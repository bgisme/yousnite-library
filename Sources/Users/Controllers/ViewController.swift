import Vapor
import Fluent
import Utilities

public struct ViewController: Sendable {
    public init() { }
}

// MARK: - Configure
extension ViewController {
    static var delegate: ViewDelegate!
    
    public static func configure(app: Application,
                                 delegate: some ViewDelegate) throws {
        self.delegate = delegate
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
        path(isRelative: isRelative, appending: joinRoute)
    }
    
    public static let passwordResetRoute: [PathComponent] = ["password-reset"]
    public static func passwordResetPath(isRelative: Bool = true) -> String {
        path(isRelative: isRelative, appending: passwordResetRoute)
    }
    
    public static let emailRequestRoute: [PathComponent] = ["email-request"]
    public static func emailRequestPath(isNewUser: Bool = false, isRelative: Bool = true) -> String {
        path(isRelative: isRelative, appending: emailRequestRoute) + isNewUserQueryParameter(isNewUser)
    }
    
    public static let passwordUpdateRoute: [PathComponent] = ["password-update"]
    public static func passwordUpdatePath(isRelative: Bool = true) -> String {
        path(isRelative: isRelative, appending: passwordUpdateRoute)
    }
    
    public static let signInRoute: [PathComponent] = ["signin"]
    public static func signInPath(isRelative: Bool = true) -> String {
        path(isRelative: isRelative, appending: signInRoute)
    }
    
    public static let signOutRoute: [PathComponent] = ["signout"]
    public static func signOutPath(isRelative: Bool = true) -> String {
        path(isRelative: isRelative, appending: signOutRoute)
    }
    
    public static let appleRedirectRoute: [PathComponent] = ["apple", "redirect"]
    public static var appleRedirectPath: String {
        path(isRelative: false, appending: appleRedirectRoute)
    }
    
    public static let googleRedirectRoute: [PathComponent] = ["google", "redirect"]
    public static var googleRedirectPath: String {
        path(isRelative: false, appending: googleRedirectRoute)
    }
    
    public static let quitRoute: [PathComponent] = ["quit"]
    public static func quitPath(isRelative: Bool = true) -> String {
        path(isRelative: isRelative, appending: quitRoute)
    }
    
    public func boot(routes: RoutesBuilder) throws {
        let route = routes.grouped(Self.route)
        
        route.get(Self.joinRoute, use: displayJoinRequest)
        route.get(Self.passwordResetRoute, use: displayPasswordResetRequest)
        route.post(Self.emailRequestRoute, use: postEmailRequest)
        
        /// password update handles...
        /// join... new password after clicking email link
        /// reset... update password after clicking email link
        /// update... update password for authenticated user
        route.get(Self.passwordUpdateRoute + [":state"], use: displayPasswordUpdate)    // called by email link
        route.get(Self.passwordUpdateRoute, use: displayPasswordUpdate)                 // called by email link
        route.post(Self.passwordUpdateRoute + [":state"], use: postPasswordUpdate)
        route.post(Self.passwordUpdateRoute, use: postPasswordUpdate)               // called by authenticated user
        
        route.get(Self.signInRoute, use: displaySignIn)
        route.post(Self.signInRoute, use: postEmailSignIn)
        
        route.get(Self.signOutRoute, use: signOut)
        
        route.post(Self.appleRedirectRoute, use: appleRedirect)
        route.post(Self.googleRedirectRoute, use: googleRedirect)
        
        route.get(Self.quitRoute, use: quit)
    }
    
    /// <form> with field for email to request join link
    func displayJoinRequest(req: Request) async throws -> Response {
        let user = try? MainController.delegate.authenticatedUser(req: req)
        guard user == nil else {
            return try await Self.delegate.joinDone(req: req)
        }
        // pull out display info
        let (apple, google) = Self.appleGoogleView(req: req)
        let email = Self.emailJoinView(isDeleted: true, req: req)
        // get response from source
        let (state, _) = EmailController.state()
        let response = Self.delegate.join(state: state, email: email, apple: apple, google: google)
        Self.setAuthenticationCookies(state: state, isJoin: true, response: response)
        return response
    }
    
    /// <form> with field for email to request password-reset link
    func displayPasswordResetRequest(req: Request) async throws -> Response {
        let input = Self.passwordResetView(isDeleted: true, req: req)
        return Self.delegate.passwordChange(.reset(input: input))
    }
    
    /// handles join and password-reset requests
    func postEmailRequest(req: Request) async throws -> Response {
        guard let email = try? req.content.decode(Email.self).address
        else { throw Abort(.internalServerError) }
        let isNewUser: Bool = req.query[Self.isNewUserQueryKey] ?? false
        let response: Response
        do {
            try await EmailController.requestPasswordUpdate(email: email,
                                                            isNewUser: isNewUser,
                                                            req: req)
            response = try await Self.delegate.sent(isNewUser ? .join : .passwordReset, email: email, req: req)
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
        do {
            if let user = try MainController.delegate.authenticatedUser(req: req) {
                // authenticated
                let input = Self.passwordUpdateView(email: user.email,
                                                    isNewUser: false,
                                                    req: req)
                return Self.delegate.passwordChange(.update(input: input, isNewUser: false))
            } else {
                // unauthenticated
                guard 
                    let (state, urlEncodedState) = try? EmailController.state(req: req),
                    let email = try? await EmailController.email(for: state, db: req.db)
                else {
                    return Self.delegate.passwordChange(.updateInvalid(error: "Option not available.", isNewUser: true))
                }
                let isNewUser: Bool = req.query[Self.isNewUserQueryKey] ?? false
                let input = Self.passwordUpdateView(email: email,
                                                    isNewUser: isNewUser,
                                                    state: urlEncodedState,
                                                    req: req)
                return Self.delegate.passwordChange(.update(input: input, isNewUser: true))
            }
        } catch {
            return try await Self.delegate.fatalError("Unauthorized password update.", req: req)
        }
    }
    
    func postPasswordUpdate(req: Request) async throws -> Response {
        var isNewUser = false
        do {
            if let _ = try? MainController.delegate.authenticatedUser(req: req) {
                // authenticated
                try await EmailController.changePassword(isUpdate: true, req: req)
            } else {
                // unauthenticated
                let (user, isNew) = try await EmailController.changePassword(req: req)
                isNewUser = isNew
                try MainController.delegate.authenticate(user, req: req)
            }
        } catch {
            Self.setException(error, method: .email(), req: req)
            return req.redirect(to: Self.passwordUpdatePath())
        }
        return try await isNewUser ? Self.delegate.joinDone(req: req) : Self.delegate.passwordUpdateDone(req: req)
    }
    
    // display sign-in page with options
    func displaySignIn(req: Request) async throws -> Response {
        guard (try? MainController.delegate.authenticatedUser(req: req)) == nil else {
            return try await Self.delegate.signInDone(req: req)
        }
        let (apple, google) = Self.appleGoogleView(req: req)
        let email = Self.emailSignInView(isDeleted: true, req: req)
        let (state, _) = EmailController.state()
        let response = Self.delegate.signIn(state: state, email: email, apple: apple, google: google)
        Self.setAuthenticationCookies(state: state, response: response)
        return response
    }
    
    // email <form> submit on sign-in page
    func postEmailSignIn(req: Request) async throws -> Response {
        let signIn = try req.content.decode(SignIn.self)
        do {
            try await EmailController.signIn(signIn, req: req)
            return try await Self.delegate.signInDone(req: req)
        } catch {
            Self.setException(error, method: .email(signIn.email.address), req: req)
            return req.redirect(to: Self.signInPath())
        }
    }
    
    // called by Apple
    func appleRedirect(req: Request) async throws -> Response {
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
            if let existing = try await MainController.delegate.user(method, on: req.db) {
                try MainController.delegate.authenticate(existing, req: req)
                response = try await Self.delegate.signInDone(req: req)
            } else if isJoin {
                let new = try await MainController.delegate.createUser(method, on: req.db)
                try MainController.delegate.authenticate(new, req: req)
                try await EmailController.sendEmail(.joined(.apple), to: email, req: req)
                response = try await Self.delegate.joinDone(req: req)
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
            if let existing = try await MainController.delegate.user(method, on: req.db) {
                try MainController.delegate.authenticate(existing, req: req)
                response = try await Self.delegate.signInDone(req: req)
            } else if isJoin {
                let new = try await MainController.delegate.createUser(method, on: req.db)
                try MainController.delegate.authenticate(new, req: req)
                try await EmailController.sendEmail(.joined(.google), to: email, req: req)
                response = try await Self.delegate.joinDone(req: req)
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
        MainController.delegate.unauthenticate(isSessionEnd: true, req: req)
        return try await Self.delegate.signOutDone(req: req)
    }

    #warning("TODO: Add date field to user for quitAt... reset random password... retain deleted users for short period of time")
    func quit(req: Request) async throws -> Response {
        guard let user = try MainController.delegate.authenticatedUser(req: req) else {
            throw Abort(.internalServerError)
        }
        MainController.delegate.unauthenticate(isSessionEnd: true, req: req)
        try await MainController.delegate.delete(user, req: req)
        return try Self.delegate.userDeleted(req: req)
    }
}
