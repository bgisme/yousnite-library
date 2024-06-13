import Vapor
import Fluent
import NestRoute
import SessionStorage


public struct ViewController {
    public init() { }
}

// MARK: - Configure
extension ViewController {
    static private(set) var source: ViewControllerSource.Type?
    
    public static func configure(source: ViewControllerSource.Type) throws {
        self.source = source
    }
}

// MARK: - RouteCollection
extension ViewController: RouteCollection {
    public static let isNewUserQueryKey = "new"
    public static func isNewUserQueryParameter(_ isNewUser: Bool) -> String {
        isNewUser ? "?\(isNewUserQueryKey)=true" : ""
    }
    
    public static let joinRoute: [PathComponent] = ["join"]
    public static func joinPath(isRelative: Bool = true) -> String {
        Self.path(isRelative: isRelative, appending: joinRoute)
    }
    
    public static let passwordResetRoute: [PathComponent] = ["password-reset"]
    public static func passwordResetPath(isRelative: Bool = true) -> String {
        Self.path(isRelative: isRelative, appending: passwordResetRoute)
    }
    
    public static let emailRequestRoute: [PathComponent] = ["email-request"]
    public static func emailRequestPath(isNewUser: Bool = false, isRelative: Bool = true) -> String {
        Self.path(isRelative: isRelative, appending: emailRequestRoute) + isNewUserQueryParameter(isNewUser)
    }
    
    public static let passwordUpdateRoute: [PathComponent] = ["password-update"]
    public static func passwordUpdatePath(isRelative: Bool = true) -> String {
        Self.path(isRelative: isRelative, appending: passwordUpdateRoute)
    }

    public static let signInRoute: [PathComponent] = ["signin"]
    public static func signInPath(isRelative: Bool = true) -> String {
        Self.path(isRelative: isRelative, appending: signInRoute)
    }
    
    public static let signOutRoute: [PathComponent] = ["signout"]
    public static func signOutPath(isRelative: Bool = true) -> String {
        Self.path(isRelative: isRelative, appending: signOutRoute)
    }

    public static let appleRedirectRoute: [PathComponent] = ["apple", "redirect"]
    public static var appleRedirectPath: String {
        path(isRelative: false, appending: appleRedirectRoute)
    }
    public static let googleRedirectRoute: [PathComponent] = ["google", "redirect"]
    public static var googleRedirectPath: String {
        path(isRelative: false, appending: googleRedirectRoute)
    }

    public func boot(routes: RoutesBuilder) throws {
        let route = routes.grouped(Self.route)
        
        route.get(Self.joinRoute, use: displayJoinRequest)
        route.get(Self.passwordResetRoute, use: displayPasswordResetRequest)
        route.post(Self.emailRequestRoute, use: postEmailRequest)
        
        /// password update handles...
        /// join... replace auto-generated password for new user via email link
        /// reset... replace forgotten password for unauthenticated user via email link
        /// update... replace current password for authenticated user
        route.get(Self.passwordUpdateRoute + [":state"], use: displayPasswordUpdate)
        route.get(Self.passwordUpdateRoute, use: displayPasswordUpdate)
        route.post(Self.passwordUpdateRoute + [":state"], use: postPasswordUpdate)  // called by email link
        route.post(Self.passwordUpdateRoute, use: postPasswordUpdate)               // called by authenticated user
        
        route.get(Self.signInRoute, use: displaySignIn)
        route.post(Self.signInRoute, use: postEmailSignIn)
        
        route.get(Self.signOutRoute, use: signOut)
        
        route.post(Self.appleRedirectRoute, use: appleRedirect)
        route.post(Self.googleRedirectRoute, use: googleRedirect)
    }
    
    /// <form> with field for email to request join link
    func displayJoinRequest(req: Request) async throws -> Response {
        guard let s = Self.source else { throw Abort(.internalServerError) }
        let user = try? MainController.authenticatedUser(req: req)
        guard user == nil else {
            return try await s.joinDone(req: req)
        }
        // pull out display info
        let (apple, google) = Self.getAppleGoogleDisplays(req: req)
        let email = Self.getEmailJoinDisplay(isDeleted: true, req: req)
        // get response from source
        let state = EmailController.state(isURLEncoded: true)
        let response = s.displayJoin(state: state, email: email, apple: apple, google: google)
        Self.setAuthenticationCookies(state: state, isJoin: true, response: response)
        return response
    }
    
    /// <form> with field for email to request password-reset link
    func displayPasswordResetRequest(req: Request) async throws -> Response {
        guard let s = Self.source else { throw Abort(.internalServerError) }
        let input = Self.getPasswordResetDisplay(isDeleted: true, req: req)
        return s.displayPasswordReset(input: input)
    }
    
    /// handles join and password-reset requests
    func postEmailRequest(req: Request) async throws -> Response {
        guard let s = Self.source,
              let email = try? req.content.decode(Email.self).address
        else { throw Abort(.internalServerError) }
        let isNewUser: Bool = req.query[Self.isNewUserQueryKey] ?? false
        let response: Response
        do {
            try await EmailController.requestPasswordUpdate(email: email, isNewUser: isNewUser, req: req)
            response = try await s.sent(isNewUser ? .join : .passwordReset, email: email, req: req)
        } catch {
            Self.setException(error, method: .email(email), req: req)
            response = req.redirect(to: isNewUser ? Self.joinPath() : Self.passwordResetPath())
        }
        if isNewUser {
            // clean up cookies
            Self.deleteAuthenticationCookies(response)
        }
        return response
    }

    /// <form> with fields for password and confirm-password
    func displayPasswordUpdate(req: Request) async throws -> Response {
        guard let s = Self.source else { throw Abort(.internalServerError) }
        if let user = try MainController.authenticatedUser(req: req) {
            // authenticated
            let input = Self.getPasswordUpdateDisplay(email: user.email,
                                                      isNewUser: false,
                                                      isDeleted: true,
                                                      req: req)
            return s.displayPasswordUpdate(input: input)
        } else {
            // unauthenticated
            let state = try EmailController.state(req: req)
            let email = try await EmailController.email(for: state, db: req.db)
            let isNewUser: Bool = req.query[Self.isNewUserQueryKey] ?? false
            let input = Self.getPasswordUpdateDisplay(email: email,
                                                      isNewUser: isNewUser,
                                                      state: state,
                                                      isDeleted: true,
                                                      req: req)
            return s.displayPasswordUpdate(input: input)
        }
    }
    
    func postPasswordUpdate(req: Request) async throws -> Response {
        guard let s = Self.source else { throw Abort(.internalServerError) }
        var isNewUser = false
        do {
            if let _ = try? MainController.authenticatedUser(req: req) {
                // authenticated
                try await EmailController.changePassword(isUpdate: true, req: req)
            } else {
                // unauthenticated
                let (user, isNew) = try await EmailController.changePassword(req: req)
                isNewUser = isNew
                try MainController.authenticate(user, req: req)
            }
        } catch {
            Self.setException(error, method: .email(), req: req)
            return req.redirect(to: Self.passwordUpdatePath())
        }
        return try await isNewUser ? s.joinDone(req: req) : s.passwordUpdateDone(req: req)
    }
        
    // display sign-in page with options
    func displaySignIn(req: Request) async throws -> Response {
        guard let s = Self.source else { throw Abort(.internalServerError) }
        guard (try? MainController.authenticatedUser(req: req)) == nil else {
            return try await s.signInDone(req: req)
        }
        let (apple, google) = Self.getAppleGoogleDisplays(req: req)
        let email = Self.getEmailSignInDisplay(isDeleted: true, req: req)
        let state = EmailController.state(isURLEncoded: true)
        let response = s.displaySignIn(state: state, email: email, apple: apple, google: google)
        Self.setAuthenticationCookies(state: state, response: response)
        return response
    }
        
    // email <form> submit on sign-in page
    func postEmailSignIn(req: Request) async throws -> Response {
        guard let s = Self.source else { throw Abort(.internalServerError) }
        let signIn = try req.content.decode(SignIn.self)
        do {
            try await EmailController.signIn(signIn, req: req)
            return try await s.signInDone(req: req)
        } catch {
            Self.setException(error, method: .email(signIn.email.address), req: req)
            return req.redirect(to: Self.signInPath())
        }
    }
    
    // called by Apple
    func appleRedirect(req: Request) async throws -> Response {
        guard let s = Self.source else { throw Abort(.internalServerError) }
        let response: Response
        let authResponse = try AppleController.authResponse(req: req)
        let token = try await AppleController.idToken(authResponse: authResponse, req: req)
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
            if let existing = try await MainController.user(method, on: req.db) {
                try MainController.authenticate(existing, req: req)
                response = try await s.signInDone(req: req)
            } else if isJoin {
                let new = try await MainController.createUser(method, on: req.db)
                try MainController.authenticate(new, req: req)
                response = try await s.joinDone(req: req)
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
        let auth = try GoogleController.GoogleAuthResponse(req)
        // compare state values and verify according to https://developers.google.com/identity/gsi/web/guides/verify-google-id-token
        guard let info = try? await req.jwt.google.verify(auth.credential),
              info.audience.value.first == GoogleController.clientId,
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
            if let existing = try await MainController.user(method, on: req.db) {
                try MainController.authenticate(existing, req: req)
                response = try await s.signInDone(req: req)
            } else if isJoin {
                let new = try await MainController.createUser(method, on: req.db)
                try MainController.authenticate(new, req: req)
                response = try await s.joinDone(req: req)
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
        
    func signOut(req: Request) async throws -> Response {
        guard let s = Self.source else { throw Abort(.internalServerError) }
        try MainController.unauthenticate(req: req)
        return try await s.signOutDone(req: req)
    }
}

// MARK: - NestedRouteCollection
extension ViewController: NestedRouteCollection {
    public static private(set) var route: [PathComponent] = ["auth"]
    public static var nestedParent: NestedRouteCollection.Type?
    public static private(set) var nestedChildren: [NestedRouteCollection.Type] = []
}

// MARK: - Cookies Management
extension ViewController {
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
extension ViewController {
    static private let errorKey = "ViewController.error"
    static private let stateKey = "ViewController.state"
    
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
    
    private static func setState(_ state: String, req: Request) {
        req.session.set(state, key: stateKey)
    }
    
    private static func getState(isDeleted: Bool = false, req: Request) throws -> String {
        try req.session.get(String.self, key: stateKey, isDeleted: isDeleted)
    }
}
 
// MARK: - Retieve exceptions and update display structs
extension ViewController {
    private static func getAppleGoogleDisplays(req: Request) -> (AppleDisplay, GoogleDisplay) {
        let e = try? Self.getException(req: req)
        var apple = AppleDisplay(redirectUri: path(isRelative: false, appending: appleRedirectRoute))
        var google = GoogleDisplay(redirectUri: ViewController.path(isRelative: false, appending: googleRedirectRoute))
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
    
    private static func getPasswordUpdateDisplay(email: String,
                                                 isNewUser: Bool,
                                                 state: String? = nil,
                                                 isDeleted: Bool = false,
                                                 req: Request) -> PasswordUpdateDisplay {
        if let e = try? Self.getException(isDeleted: isDeleted, req: req) {
            return PasswordUpdateDisplay(email: email, 
                                         isNewUser: isNewUser,
                                         state: state,
                                         error: e.message)
        }
        return PasswordUpdateDisplay(email: email, 
                                     isNewUser: isNewUser,
                                     state: state)
    }
}
