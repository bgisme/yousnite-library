import Vapor
import Fluent
import NestRoute
import SessionStorage

public struct AuthenticationViewController {
    public init() { }
}

// MARK: - Configure
extension AuthenticationViewController {
    public static let joinRoute: [PathComponent] = ["join"]
    public static func joinPath(isRelative: Bool = true) -> String {
        Self.path(isRelative: isRelative, appending: joinRoute)
    }
    
    public static let signInRoute: [PathComponent] = ["signin"]
    public static func signInPath(isRelative: Bool = true) -> String {
        Self.path(isRelative: isRelative, appending: signInRoute)
    }
    
    public static let appleRedirectRoute: [PathComponent] = ["apple", "redirect"]
    public static let googleRedirectRoute: [PathComponent] = ["google", "redirect"]
    
    public static let passwordResetRoute: [PathComponent] = ["password-reset"]
    public static func passwordResetPath(isRelative: Bool = true) -> String {
        Self.path(isRelative: isRelative, appending: passwordResetRoute)
    }
    
    public static let passwordUpdateRoute: [PathComponent] = ["password-update"]
    public static func passwordUpdatePath(isRelative: Bool = true) -> String {
        Self.path(isRelative: isRelative, appending: passwordUpdateRoute)
    }
    
    public static let signOutRoute: [PathComponent] = ["signout"]
    public static func signOutPath(isRelative: Bool = true) -> String {
        Self.path(isRelative: isRelative, appending: signOutRoute)
    }
    
    static private(set) var source: AuthenticationViewControllerSource.Type?
    
    public static func configure(source: AuthenticationViewControllerSource.Type) throws {
        self.source = source
    }
}

// MARK: - RouteCollection
extension AuthenticationViewController: RouteCollection {
    public func boot(routes: RoutesBuilder) throws {
        let route = routes.grouped(Self.route)
        
        route.get(Self.joinRoute, use: getJoin)
        route.post(Self.joinRoute, use: postJoin)
        route.get(Self.joinRoute + [":state"], use: redeemJoin)
        
        route.get(Self.signInRoute, use: getSignIn)
        route.post(Self.signInRoute, use: postEmailSignIn)
        route.post(Self.appleRedirectRoute, use: appleRedirect)
        route.post(Self.googleRedirectRoute, use: googleRedirect)
        
        route.get(Self.passwordResetRoute, use: getPasswordReset)
        route.post(Self.passwordResetRoute, use: postPasswordReset)
        route.get(Self.passwordResetRoute + [":state"], use: redeemPasswordReset)
        route.get(Self.passwordUpdateRoute, use: getPasswordUpdate)
        route.post(Self.passwordUpdateRoute, use: postPasswordUpdate)
        
        route.get(Self.signOutRoute, use: signOut)
    }
    
    // join page with options
    func getJoin(req: Request) async throws -> Response {
        guard let s = Self.source else { throw Abort(.internalServerError) }
        guard try !AuthenticationController.isSignedIn(req: req) else {
            return req.redirect(to: Self.nextPath(source: s, req: req))
        }
        // pull out display info from error
        let (apple, google) = Self.getAppleGoogleDisplays(req: req)
        let email = Self.getEmailJoinDisplay(isDeleted: true, req: req)
        // get response from source
        let state = EmailAuthenticationController.state()
        let response = s.join(state: state, email: email, apple: apple, google: google)
        Self.setAuthenticationCookies(state: state, isJoin: true, response: response)
        return response
    }
    
    // <form> submit to send join link
    func postJoin(req: Request) async throws -> Response {
        guard let s = Self.source,
              let j = try? req.content.decode(EmailCredentials.self)
        else { throw Abort(.internalServerError) }
        let response: Response
        do {
            try await EmailAuthenticationController.sendJoin(j, req: req)
            response = try await s.sent(.join, email: j.email, req: req)
        } catch {
            Self.setException(error, method: .email(j.email), req: req)
            response = req.redirect(to: Self.path(appending: Self.joinRoute))
        }
        Self.deleteAuthenticationCookies(response)
        return response
    }
    
    // email invite link clicked
    func redeemJoin(req: Request) async throws -> Response {
        do {
            try await EmailAuthenticationController.redeemJoin(req: req)
            return req.redirect(to: Self.path(appending: Self.signInRoute))
        } catch let e as EmailAuthenticationController.Exception {
            switch e {
            case .inviteExpired(let address):
                Self.setException(e, method: .email(address), req: req)
            case .inviteInvalid:
                Self.setException(e, method: .email(), req: req)
            default:
                break
            }
        } catch {
            Self.setException(error, method: .email(), req: req)
        }
        return req.redirect(to: Self.path(appending: Self.signInRoute))
    }
    
    // display sign-in page with options
    func getSignIn(req: Request) async throws -> Response {
        guard let s = Self.source else { throw Abort(.internalServerError) }
        guard try !AuthenticationController.isSignedIn(req: req) else {
            return req.redirect(to: Self.nextPath(source: s, req: req))
        }
        let (apple, google) = Self.getAppleGoogleDisplays(req: req)
        let email = Self.getEmailSignInDisplay(isDeleted: true, req: req)
        let state = EmailAuthenticationController.state()
        let response = s.signIn(state: state, email: email, apple: apple, google: google)
        Self.setAuthenticationCookies(state: state, response: response)
        return response
    }
    
    // email <form> submit on sign-in page
    func postEmailSignIn(req: Request) async throws -> Response {
        guard let s = Self.source else { throw Abort(.internalServerError) }
        let signIn = try req.content.decode(EmailCredentials.self)
        do {
            try await EmailAuthenticationController.signIn(signIn, req: req)
            return req.redirect(to: Self.nextPath(source: s, req: req))
        } catch {
            Self.setException(error, method: .email(signIn.email), req: req)
            return req.redirect(to: Self.path(appending: Self.signInRoute))
        }
    }
    
    // called by Apple
    func appleRedirect(req: Request) async throws -> Response {
        guard let s = Self.source else { throw Abort(.internalServerError) }
        let response: Response
        let authResponse = try AppleAuthenticationController.authResponse(req: req)
        let token = try await AppleAuthenticationController.idToken(authResponse: authResponse, req: req)
        guard
            let cookieState = req.cookies[Self.appleCookieKey]?.string,
            !cookieState.isEmpty,
            cookieState == authResponse.state
        else {
            throw Abort(.unauthorized)
        }
        let isJoin = Self.isJoin(req: req)
        if let email = token.email {
            let method = AuthenticationMethod.apple(email: email, id: token.subject.value)
            if let existing = try? await AuthenticationController.user(method, db: req.db) {
                try AuthenticationController.authenticate(existing, req: req)
                response = req.redirect(to: Self.nextPath(source: s, req: req))
            } else if isJoin {
                let new = try await AuthenticationController.createUser(method, db: req.db)
                try AuthenticationController.authenticate(new, req: req)
                response = try await s.joinComplete(req: req)
            } else {
                Self.setException("No registered account.", method: .apple, req: req)
                response = req.redirect(to: Self.path(appending: Self.signInRoute))
            }
        } else {
            Self.setException("Sign In with Apple is not working.", method: .apple, req: req)
            response = req.redirect(to: Self.path(appending: Self.signInRoute))
        }
        // clean up cookies
        Self.deleteAuthenticationCookies(response)
        return response
    }
    
    // called by Google
    func googleRedirect(_ req: Request) async throws -> Response {
        guard let s = Self.source else { throw Abort(.internalServerError) }
        let response: Response
        // decode google response
        let auth = try GoogleAuthenticationController.GoogleAuthResponse(req)
        // compare state values and verify according to https://developers.google.com/identity/gsi/web/guides/verify-google-id-token
        guard let info = try? await req.jwt.google.verify(auth.credential),
              info.audience.value.first == GoogleAuthenticationController.clientId,
              info.issuer == "accounts.google.com" || info.issuer == "https://accounts.google.com",
              info.expires.value.timeIntervalSinceNow >= 0,
              let state = req.cookies[Self.googleCookieKey]?.string,
              state == info.nonce
        else {
            req.logger.warning("\(Self.googleCookieKey) does not exist or match")
            throw Abort(.unauthorized)
        }
        let isJoin = Self.isJoin(req: req)
        if let email = info.email {
            // use Google subject as user identifier, not email which can change
            let method = AuthenticationMethod.google(email: email, id: info.subject.value)
            if let existing = try? await AuthenticationController.user(method, db: req.db) {
                try AuthenticationController.authenticate(existing, req: req)
                response = req.redirect(to: Self.nextPath(source: s, req: req))
            } else if isJoin {
                let new = try await AuthenticationController.createUser(method, db: req.db)
                try AuthenticationController.authenticate(new, req: req)
                response = try await s.joinComplete(req: req)
            } else {
                Self.setException("No registered account.", method: .google, req: req)
                response = req.redirect(to: Self.path(appending: Self.signInRoute))
            }
        } else {
            Self.setException("Sign In with Google is not working.", method: .google, req: req)
            response = req.redirect(to: Self.path(appending: Self.signInRoute))
        }
        // clean up cookies
        Self.deleteAuthenticationCookies(response)
        return response
    }
    
    // <form> displayed to get email address for password reset
    func getPasswordReset(req: Request) async throws -> Response {
        guard let s = Self.source else { throw Abort(.internalServerError) }
        let input = Self.getPasswordResetDisplay(isDeleted: true, req: req)
        return s.passwordReset(input: input)
    }
    
    // <form> submit to send password reset link
    func postPasswordReset(req: Request) async throws -> Response {
        guard let s = Self.source else { throw Abort(.internalServerError) }
        let pr = try req.content.decode(EmailCredentials.self)
        do {
            try await EmailAuthenticationController.sendPasswordReset(pr, req: req)
            return try await s.sent(.passwordReset, email: pr.email, req: req)
        } catch {
            Self.setException(error, method: .email(pr.email), req: req)
            return req.redirect(to: Self.passwordResetPath())
        }
    }
    
    // password reset email link clicked
    func redeemPasswordReset(req: Request) async throws -> Response {
        do {
            try await EmailAuthenticationController.redeemPasswordReset(req: req)
            return req.redirect(to: Self.signInPath())
        } catch {
            Self.setException(error, method: .email(), req: req)
            return req.redirect(to: Self.passwordResetPath())
        }
    }
    
    // display <form> for new password
    func getPasswordUpdate(req: Request) async throws -> Response {
        guard let s = Self.source else { throw Abort(.internalServerError) }
        let input = Self.getPasswordUpdateDisplay(req: req)
        return s.passwordUpdate(input: input)
    }
    
    // called by <form> with new password
    func postPasswordUpdate(req: Request) async throws -> Response {
        guard let s = Self.source else { throw Abort(.internalServerError) }
        do {
            // throws if update expired
            let u = try req.content.decode(EmailCredentials.self)
            try await EmailAuthenticationController.updatePassword(u, req: req)
            return try await s.sent(.update, email: u.email, req: req)
        } catch {
            Self.setException(error, method: .email(), req: req)
        }
        return req.redirect(to: Self.nextPath(source: s, req: req))
    }
    
    func signOut(req: Request) async throws -> Response {
        guard let s = Self.source else { throw Abort(.internalServerError) }
        try AuthenticationController.unauthenticate(req: req)
        return req.redirect(to: Self.nextPath(isSignOut: true, source: s, req: req))
    }
}

// MARK: - NestedRouteCollection
extension AuthenticationViewController: NestedRouteCollection {
    public static private(set) var route: [PathComponent] = ["auth"]
    public static var nestedParent: NestedRouteCollection.Type?
    public static private(set) var nestedChildren: [NestedRouteCollection.Type] = []
}

// MARK: - Next Path
extension AuthenticationViewController {
    public static func nextPath(isSignOut: Bool = false, source s: AuthenticationViewControllerSource.Type, req: Request) -> String {
        if let nextPath = s.nextPath(req: req) {
            return nextPath
        } else if !isSignOut {
            return s.defaultSignInPath
        } else {
            return s.defaultSignOutPath ?? signInPath()
        }
    }
}

// MARK: - Cookies Management
extension AuthenticationViewController {
    static private let appleCookieKey = "AUTH_APPLE"
    static private let googleCookieKey = "AUTH_GOOGLE"
    static private let joinCookieKey = "AUTH_JOIN"
    
    public static func setAuthenticationCookies(state: String,
                                                isJoin: Bool = false,
                                                expires seconds: Int = 300,
                                                response: Response) {
        response.cookies[appleCookieKey] = .init(string: state,
                                                 expires: Date().addingTimeInterval(.init(TimeInterval(seconds))),
                                                 maxAge: seconds,
                                                 isHTTPOnly: true,
                                                 sameSite: HTTPCookies.SameSitePolicy.none)
        response.cookies[googleCookieKey] = .init(string: state,
                                                  expires: Date().addingTimeInterval(.init(TimeInterval(seconds))),
                                                  maxAge: seconds,
                                                  isHTTPOnly: true,
                                                  sameSite: HTTPCookies.SameSitePolicy.none)
        response.cookies[joinCookieKey] = .init(string: .init(isJoin),
                                                expires: Date().addingTimeInterval(.init(TimeInterval(seconds))),
                                                maxAge: seconds,
                                                isHTTPOnly: true,
                                                sameSite: HTTPCookies.SameSitePolicy.none)
    }
    
    public static func isJoin(req: Request) -> Bool {
        let isJoin: Bool
        if let stringValue = req.cookies[Self.joinCookieKey]?.string,
           let boolValue = Bool(stringValue) {
            isJoin = boolValue
        } else {
            isJoin = false
        }
        return isJoin
    }
    
    public static func deleteAuthenticationCookies(_ response: Response) {
        response.cookies[Self.appleCookieKey] = nil
        response.cookies[Self.googleCookieKey] = nil
        response.cookies[Self.joinCookieKey] = nil
    }
}

// MARK: - Session Data
extension AuthenticationViewController {
    static private let passwordUpdateKey = "AutenticationViewController.passwordUpdate"
    static private let errorKey = "AuthenticationViewController.error"
    
    public struct Exception: Error, Codable {
        enum Method: Codable {
            case email(_ address: String? = nil)
            case apple
            case google
        }
        let method: Method
        let message: String
    }
    
    private static func setException(_ error: Error, method: Exception.Method, req: Request) {
        setException(error.localizedDescription, method: method, req: req)
    }
    
    private static func setException(_ message: String, method: Exception.Method, req: Request) {
        setException(Exception(method: method, message: message), req: req)
    }
    
    private static func setException(_ exception: Exception, req: Request) {
        req.session.set(exception, key: errorKey)
    }
    
    private static func getException(isDeleted: Bool = false, req: Request) throws -> Exception {
        try req.session.get(Exception.self, key: errorKey, isDeleted: isDeleted)
    }
    
    private static func getAppleGoogleDisplays(req: Request) -> (AppleDisplay, GoogleDisplay) {
        let e = try? Self.getException(req: req)
        var apple = AppleDisplay()
        var google = GoogleDisplay()
        if let e = e {
            switch e.method {
            case .apple:
                apple = AppleDisplay(error: e.message)
            case .google:
                google = GoogleDisplay(error: e.message)
            default:
                break
            }
        }
        return (apple, google)
    }
    
    private static func getEmailJoinDisplay(isDeleted: Bool = false, req: Request) -> EmailJoinDisplay {
        if let e = try? Self.getException(isDeleted: isDeleted, req: req) {
            switch e.method {
            case .email(let address):
                return EmailJoinDisplay(email: address, error: e.message)
            default:
                break
            }
        }
        return EmailJoinDisplay()
    }
    
    private static func getEmailSignInDisplay(isDeleted: Bool = false, req: Request) -> EmailSignInDisplay {
        if let e = try? Self.getException(isDeleted: isDeleted, req: req) {
            switch e.method {
            case .email(let address):
                return EmailSignInDisplay(email: address, error: e.message)
            default:
                break
            }
        }
        return EmailSignInDisplay()
    }
    
    private static func getPasswordResetDisplay(isDeleted: Bool = false, req: Request) -> PasswordResetDisplay {
        if let e = try? Self.getException(isDeleted: isDeleted, req: req) {
            switch e.method {
            case .email(let address):
                return PasswordResetDisplay(email: address, error: e.message)
            default:
                break
            }
        }
        return PasswordResetDisplay()
    }
    
    private static func getPasswordUpdateDisplay(isDeleted: Bool = false, req: Request) -> PasswordUpdateDisplay {
        if let e = try? Self.getException(isDeleted: isDeleted, req: req) {
            return PasswordUpdateDisplay(error: e.message)
        }
        return PasswordUpdateDisplay()
    }
}

extension AuthenticationViewController {
    public struct EmailJoinDisplay: AuthenticationViewControllerSourceEmailJoinDisplay {
        public let email: String?
        public let postTo: String
        public let signInPath: String
        public let error: String?
        
        public init(email: String? = nil,
                    postTo: String = AuthenticationViewController.joinPath(),
                    signInPath: String = AuthenticationViewController.signInPath(),
                    error: String? = nil) {
            self.email = email
            self.postTo = postTo
            self.signInPath = signInPath
            self.error = error
        }
    }
    
    public struct EmailSignInDisplay: AuthenticationViewControllerSourceEmailSignInDisplay {
        public let postTo: String
        public let joinPath: String
        public let passwordResetPath: String
        public let email: String?
        public let error: String?
        
        public init(postTo: String = AuthenticationViewController.signInPath(),
                    joinPath: String = AuthenticationViewController.joinPath(),
                    passwordResetPath: String = AuthenticationViewController.passwordResetPath(),
                    email: String? = nil,
                    error: String? = nil) {
            self.postTo = postTo
            self.joinPath = joinPath
            self.passwordResetPath = passwordResetPath
            self.email = email
            self.error = error
        }
    }
    
    public struct PasswordResetDisplay: AuthenticationViewControllerSourcePasswordResetDisplay {
        public let postTo: String
        public let joinPath: String
        public let signInPath: String
        public let email: String?
        public let error: String?
        
        public init(postTo: String = AuthenticationViewController.path(appending: passwordResetRoute),
                    joinPath: String = AuthenticationViewController.joinPath(),
                    signInPath: String = AuthenticationViewController.signInPath(),
                    email: String? = nil,
                    error: String? = nil) {
            self.postTo = postTo
            self.joinPath = joinPath
            self.signInPath = signInPath
            self.email = email
            self.error = error
        }
    }
    
    public struct PasswordUpdateDisplay: AuthenticationViewControllerSourcePasswordUpdateDisplay {
        public let postTo: String
        public let signInPath: String?
        public let error: String?
        
        public init(postTo: String = AuthenticationViewController.path(appending: passwordUpdateRoute),
                    signInPath: String = AuthenticationViewController.signInPath(),
                    error: String? = nil) {
            self.postTo = postTo
            self.signInPath = signInPath
            self.error = error
        }
    }
    
    public struct AppleDisplay: AuthenticationViewControllerSourceAppleDisplay {
        public let servicesId: String
        public let scopes: AppleScopeOptions
        public let redirectUri: String
        public let error: String?
        
        public init(servicesId: String = AppleAuthenticationController.servicesId,
                    scopes: AppleScopeOptions = .all,
                    redirectUri: String = AuthenticationViewController.path(isRelative: false, appending: appleRedirectRoute),
                    error: String? = nil) {
            self.servicesId = servicesId
            self.scopes = scopes
            self.redirectUri = redirectUri
            self.error = error
        }
    }
    
    public struct GoogleDisplay: AuthenticationViewControllerSourceGoogleDisplay {
        public let clientId: String
        public let redirectUri: String
        public let error: String?
        
        public init(clientId: String = GoogleAuthenticationController.clientId,
                    redirectUri: String = AuthenticationViewController.path(isRelative: false, appending: googleRedirectRoute),
                    error: String? = nil) {
            self.clientId = clientId
            self.redirectUri = redirectUri
            self.error = error
        }
    }
}
