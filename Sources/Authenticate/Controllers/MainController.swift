import Vapor
import Fluent
import Utilities

public struct MainController { 
    public init() {}
}

// MARK: - Configure
extension MainController {
    static var userDelegate: UserDelegate!
    static var notificationDelegate: NotificationDelegate!
    
    public static func configure(app: Application,
                                 routes: [PathComponent] = Self.routes,
                                 parentRouteCollection: NestedRouteCollection.Type? = nil,
                                 userDelegate: some UserDelegate,
                                 notificationDelegate: some NotificationDelegate,
                                 viewDelegate: some ViewDelegate) throws {
        // Delegates
        self.userDelegate = userDelegate
        self.notificationDelegate = notificationDelegate
        // NestedRouteCollection
        self.routes = routes
        self.parentRouteCollection = parentRouteCollection
        // Migrations
        app.migrations.add(Credential.Migration())
        // Subordinates
        try APIController.configure(app: app, parentRouteCollection: self)
        try AppleController.configure(app: app, parentRouteCollection: self)
        try GoogleController.configure(app: app, parentRouteCollection: self)
        try EmailController.configure(app: app, parentRouteCollection: self)
        try ViewController.configure(app: app,
                                     parentRouteCollection: self,
                                     delegate: viewDelegate)
    }
}

// MARK: -
extension MainController {
//    static func joinInfo(isApp: Bool, req: Request) async throws -> (Email, IsNewUser, PostToURL) {
//        let (token, urlEncodedToken) = try EmailController.getState(req: req)
//        let email = try await EmailController.email(for: state, db: req.db)
//        let isNewUser: Bool = req.query[isNewUserParameterKey] ?? false
//        var postToURL = isApp ? path(isRelative: false, appending: passwordCreateResetRoute) : ViewController.passwordResetPath()
//        postToURL += "/" + urlEncodedToken
//        return (email, isNewUser, postToURL)
//    }
        
    static func signInOrCreateUser(_ method: CredentialMethod, req: Request) async throws -> Response {
        let isJoin = req.cookies.isJoin
        let isAPI = req.cookies.isAPI
        let response: Response
        var other: CredentialType?
        if let existing = try? await MainController.credential(method, other: &other, on: req.db) {
            // user exists... authenticate
            try MainController.authenticate(existing, req: req)
            if isAPI {
                #warning("TODO: Need appropriate API response")
                response = .init(status: .ok)
            } else {
                response = await ViewController.delegate.did(.signIn(req))
            }
        } else if isJoin {
            if let other = other {
                // user exists with email and another authentication type... possible when Google or Facebook adopt email account
                let error = CredentialError.otherRegistration(.init(other, method.email))
                if isAPI {
                    #warning("TODO: Need appropriate API error")
                    response = .init(status: .conflict)
                } else {
                    req.session.setCredentialError(error)
                    response = req.redirect(to: ViewController.signInPath())
                }
            } else {
                // no user with email exists... create user
                let new = try await MainController.createCredential(method, on: req.db)
                try MainController.authenticate(new, req: req)
                try await EmailController.sendEmail(.joined(method.type), to: method.email, req: req)
                if isAPI {
                    #warning("TODO: Need appropriate API response")
                    response = .init(status: .ok)
                } else {
                    response = await ViewController.delegate.did(.join(req))
                }
            }
        } else {
            req.session.setCredentialError(.notRegistered(.init(method)))
            if isAPI {
                #warning("TODO: Need appropriate API error")
                response = .init(status: .conflict)
            } else {
                response = req.redirect(to: ViewController.signInPath())
            }
        }
        return response
    }
    
    static func unjoinauthentication(req: Request) async throws {
        do {
            guard let credential = try req.credential else { return }
            // set date for unjoin
            credential.unjoinedAt = Date()
            try await credential.save(on: req.db)
            unauthenticate(isSessionEnd: true, req: req)
            let kind = EmailController.EmailKind.unjoined(credential.type)
            try await EmailController.sendEmail(kind, to: credential.email, req: req)
        } catch {
            // will not be called... only invite and password reset email errors thrown here
            req.session.set(error)
        }
    }
        
    static func signIn(_ signIn: EmailPassword? = nil, req: Request) async throws {
        let si = try signIn ?? req.content.decode(EmailPassword.self)
        let address = si.email
        let password = si.password
        // find user
        var other: CredentialType?
        guard let user = try? await credential(.email(address), other: &other, on: req.db) else {
            throw CredentialError.notRegistered(.email(address))
        }
        // check password
        guard try user.verify(password: password) else {
            throw CredentialError.passwordWrong(email: address)
        }
        try authenticate(user, req: req)
    }
    
    static func createCredential(_ method: CredentialMethod, on db: Database) async throws -> Credential {
        let userId = try await userDelegate.createUser(on: db)
        let credential = try Credential(method, userId: userId)
        try await credential.save(on: db)
        return credential
    }
    
    static func credential(_ method: CredentialMethod,
                     other: inout CredentialType?,
                     on db: Database) async throws -> Credential {
        let address: String
        switch method {
        case .apple(let email, _):
            address = email
        case .email(let email, _):
            address = email
        case .google(let email, _):
            address = email
        }
        if let type = try? await Credential.type(address, in: db),
           type != method.type {
            other = type
        }
        return try await Credential.find(method, in: db)
    }
        
    static func authenticate(_ credential: Credential, req: Request) throws {
        req.auth.login(credential)
    }
    
    static func unauthenticate(isSessionEnd: Bool, req: Request) {
        req.auth.logout(Credential.self)
        if isSessionEnd { req.session.destroy() }
    }
    
    static func delete(_ credential: Credential, req: Request) async throws {
        try await credential.delete(on: req.db)
    }
}

// MARK: - Sessions
extension MainController {
    static let joinCookieKey = "AUTHENTICATE_JOIN"
}
