import Vapor
import Fluent
import NestRoute
import SessionStorage

public struct ViewController {
    public init() { }
}

// MARK: - Configure
extension ViewController {
    private static var source: ViewControllerSource.Type?
    
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
        let user = try? MainController.source.authenticatedUser(req: req)
        guard user == nil else {
            return try await s.joinDone(req: req)
        }
        // pull out display info
        let (apple, google) = Self.appleGoogleView(req: req)
        let email = Self.emailJoinView(isDeleted: true, req: req)
        // get response from source
        let state = EmailController.state(isURLEncoded: true)
        let response = s.displayJoin(state: state, email: email, apple: apple, google: google)
        Self.setAuthenticationCookies(state: state, isJoin: true, response: response)
        return response
    }
    
    /// <form> with field for email to request password-reset link
    func displayPasswordResetRequest(req: Request) async throws -> Response {
        guard let s = Self.source else { throw Abort(.internalServerError) }
        let input = Self.passwordResetView(isDeleted: true, req: req)
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
        if let user = try MainController.source.authenticatedUser(req: req) {
            // authenticated
            let input = Self.passwordUpdateView(email: user.email,
                                                isNewUser: false,
                                                isDeleted: true,
                                                req: req)
            return s.displayPasswordUpdate(input: input)
        } else {
            do {
                // unauthenticated
                let state = try EmailController.state(req: req)
                let email = try await EmailController.email(for: state, db: req.db)
                let isNewUser: Bool = req.query[Self.isNewUserQueryKey] ?? false
                let input = Self.passwordUpdateView(email: email,
                                                    isNewUser: isNewUser,
                                                    state: state,
                                                    isDeleted: true,
                                                    req: req)
                return s.displayPasswordUpdate(input: input)
            } catch {
                return try await s.fatalError("Unauthorized password update.", req: req)
            }
        }
    }
    
    func postPasswordUpdate(req: Request) async throws -> Response {
        guard let s = Self.source else { throw Abort(.internalServerError) }
        var isNewUser = false
        do {
            if let _ = try? MainController.source.authenticatedUser(req: req) {
                // authenticated
                try await EmailController.changePassword(isUpdate: true, req: req)
            } else {
                // unauthenticated
                let (user, isNew) = try await EmailController.changePassword(req: req)
                isNewUser = isNew
                try MainController.source.authenticate(user, req: req)
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
        guard (try? MainController.source.authenticatedUser(req: req)) == nil else {
            return try await s.signInDone(req: req)
        }
        let (apple, google) = Self.appleGoogleView(req: req)
        let email = Self.emailSignInView(isDeleted: true, req: req)
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
            if let existing = try await MainController.source.user(method, on: req.db) {
                try MainController.source.authenticate(existing, req: req)
                response = try await s.signInDone(req: req)
            } else if isJoin {
                let new = try await MainController.source.createUser(method, on: req.db)
                try MainController.source.authenticate(new, req: req)
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
            if let existing = try await MainController.source.user(method, on: req.db) {
                try MainController.source.authenticate(existing, req: req)
                response = try await s.signInDone(req: req)
            } else if isJoin {
                let new = try await MainController.source.createUser(method, on: req.db)
                try MainController.source.authenticate(new, req: req)
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
        MainController.source.unauthenticate(isSessionEnd: true, req: req)
        return try await s.signOutDone(req: req)
    }
}

// MARK: - NestedRouteCollection
extension ViewController: NestedRouteCollection {
    public static private(set) var route: [PathComponent] = ["auth"]
    public static var nestedParent: NestedRouteCollection.Type?
    public static private(set) var nestedChildren: [NestedRouteCollection.Type] = []
}
