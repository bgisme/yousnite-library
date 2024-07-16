import Vapor
import Fluent
import Utilities

extension UserController {
    static func passwordToken(req: Request, isURLEncoded: Bool, isNewUser: inout Bool) async throws -> String? {
        if let _ = try? authenticatedUser(req: req) {
            // authenticated... submit <form> without state identifier
            isNewUser = false
            return nil
        } else if let pt = req.parameters.get(APIController.passwordTokenKey),
                  let toAddress = try? await EmailController.email(for: pt, db: req.db) {
            // unauthenticated... submit <form> with state identifier
            var other: AuthenticationType?
            isNewUser = (try? await user(.email(toAddress), other: &other, on: req.db)) == nil
            return isURLEncoded ? EmailController.urlEncoded(pt) : pt
        } else {
            isNewUser = true
            throw AuthenticationError.passwordTokenMissingOrExpired
        }
    }
    
#warning("TODO: Move to EmailController")
    static func sendPasswordCreateResetLink(to toAddress: String,
                                            isNewUser: Bool,
                                            isToApp: Bool = false,
                                            req: Request) async throws {
        // check conflicts... new user but one exists... not new user and one does not exist
        let method = AuthenticationMethod.email(toAddress)
        var other: AuthenticationType?
        let isExisting = (try? await user(method, other: &other, on: req.db)) != nil
        let isNewAndNotExisting = isNewUser && !isExisting
        let isNotNewAndExisting = !isNewUser && isExisting
        // user must be new and not exist or not new and existing
        guard isNewAndNotExisting || isNotNewAndExisting else {
            throw isNewUser ? AuthenticationError.registered(.email(toAddress)) : AuthenticationError.notRegistered(.email(toAddress))
        }
        // make sure user does not exist with email and other authentication type
        guard other == nil else {
            throw UserController.AuthenticationError.otherRegistration(other!.method(email: toAddress))
        }
        do {
            try await EmailController.sendPasswordCreateResetLink(to: toAddress,
                                                                  isNewUser: isNewUser,
                                                                  isToApp: isToApp,
                                                                  req: req)
        } catch {
            // invite and password reset email errors only
            req.session.set(error)
        }
    }
    
    static func setPassword(_ password: String, isNewUser: inout Bool, req: Request) async throws {
        // update or create password
        let toAddress: String
        let user: any UserIdentifiable
        if let u = try? UserController.authenticatedUser(req: req) {
            isNewUser = false
            toAddress = u.email
            user = u
            try await user
                .update(.email(toAddress, password: password))
                .save(on: req.db)
        } else if let token = req.parameters.get(APIController.passwordTokenKey),
                  let address = try await EmailController.email(for: token,
                                                                deleteOthersWithEmail: true,
                                                                db: req.db) {
            toAddress = address
            var other: AuthenticationType?
            if let u = try? await self.user(.email(toAddress, password: ""), other: &other, on: req.db) {
                user = u
                isNewUser = false
                try await user
                    .update(.email(user.email, password: password))
                    .save(on: req.db)
            } else {
                isNewUser = true
                user = try await createUser(.email(toAddress, password: password), on: req.db)
            }
            try authenticate(user, req: req)
        } else {
            isNewUser = true
            throw AuthenticationError.passwordTokenMissingOrExpired
        }
        // send email
        let kind: EmailController.EmailKind
        if isNewUser {
            kind = .joined(.email)
        } else {
            kind = .passwordSet
        }
        do {
            try await EmailController.sendEmail(kind, to: toAddress, req: req)
            req.logger.trace("Email Sent\ttoaddress: \(toAddress)\tkind: \(kind)")
        } catch {
            // email just notification... do not need to display for user... just log error
            req.logger.critical("Email Fail\ttoaddress: \(toAddress)\tkind: \(kind)\terror: \(error.localizedDescription)")
        }
    }
    
//    static func joinInfo(isApp: Bool, req: Request) async throws -> (Email, IsNewUser, PostToURL) {
//        let (token, urlEncodedToken) = try EmailController.state(req: req)
//        let email = try await EmailController.email(for: state, db: req.db)
//        let isNewUser: Bool = req.query[isNewUserParameterKey] ?? false
//        var postToURL = isApp ? path(isRelative: false, appending: passwordCreateResetRoute) : ViewController.passwordResetPath()
//        postToURL += "/" + urlEncodedToken
//        return (email, isNewUser, postToURL)
//    }
    
    static func unjoinAuthenticatedUser(req: Request) async throws {
        do {
            let user = try authenticatedUser(req: req)
            // set date for unjoin
            user.unjoinedAt = Date()
            try await user.save(on: req.db)
            unauthenticate(isSessionEnd: true, req: req)
            let kind = EmailController.EmailKind.unjoined(user.authenticationType)
            try await EmailController.sendEmail(kind, to: user.email, req: req)
        } catch {
            // will not be called... only invite and password reset email errors thrown here
            req.session.set(error)
        }
    }
        
    static func setAuthenticationCookies(token: String,
                                         isJoin: Bool = false,
                                         expires seconds: Int = 300,
                                         response: Response) {
        response.cookies[AppleController.cookieKey] = .init(string: token,
                                                            expires: Date().addingTimeInterval(.init(TimeInterval(seconds))),
                                                            maxAge: seconds,
                                                            isHTTPOnly: true,
                                                            sameSite: HTTPCookies.SameSitePolicy.none)
        response.cookies[GoogleController.cookieKey] = .init(string: token,
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
    
    static func deleteAuthenticationCookies(_ response: Response) {
        response.cookies[AppleController.cookieKey] = nil
        response.cookies[GoogleController.cookieKey] = nil
        response.cookies[Self.joinCookieKey] = nil
    }
    
    static let joinCookieKey = "AUTH_JOIN"
    
    static func isJoin(req: Request) -> Bool {
        let isJoin: Bool
        if let stringValue = req.cookies[Self.joinCookieKey]?.string,
           let boolValue = Bool(stringValue) {
            isJoin = boolValue
        } else {
            isJoin = false
        }
        return isJoin
    }
    
    static func signIn(_ signIn: SignIn? = nil, req: Request) async throws {
        let si = try signIn ?? req.content.decode(SignIn.self)
        let address = si.email
        let password = si.password
        // find user
        var other: AuthenticationType?
        guard let user = try? await user(.email(address), other: &other, on: req.db) else {
            throw AuthenticationError.notRegistered(.email(address))
        }
        // check password
        guard try user.verify(password: password) else {
            throw AuthenticationError.passwordWrong(email: address)
        }
        try authenticate(user, req: req)
    }
    
    static func createUser(_ method: AuthenticationMethod, on db: Database) async throws -> any UserIdentifiable {
        let user = try User(method)
        try await user.save(on: db)
        return user
    }
    
    static func user(_ method: AuthenticationMethod,
                     other: inout AuthenticationType?,
                     on db: Database) async throws -> any UserIdentifiable {
        let address: String
        switch method {
        case .apple(let email, _):
            address = email
        case .email(let email, _):
            address = email
        case .google(let email, _):
            address = email
        }
        if let type = try? await User.type(address, in: db),
           type != method.type {
            other = type
        }
        return try await User.find(method, in: db)
    }
    
    static func authenticatedUser(req: Request) throws -> any UserIdentifiable {
        guard let user = req.auth.get(User.self) else { throw Abort(.notFound) }
        return user
    }
    
    static func authenticate(_ user: any UserIdentifiable, req: Request) throws {
        req.auth.login(user)
    }
    
    static func unauthenticate(isSessionEnd: Bool, req: Request) {
        req.auth.logout(User.self)
        if isSessionEnd { req.session.destroy() }
    }
    
    static func delete(_ user: any UserIdentifiable, req: Request) async throws {
        try await user.delete(on: req.db)
    }
}
