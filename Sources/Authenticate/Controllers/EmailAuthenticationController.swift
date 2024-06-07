import Vapor
import Fluent

public struct EmailAuthenticationController { 
    public init() { }
}

// MARK: - Configure
extension EmailAuthenticationController {
    static var authenticationSource: EmailAuthenticationSource.Type?
    static var providerSource: EmailProviderSource.Type?
    static var sender: String?
    
    public static func configure(app: Application,
                                 authenticationSource: EmailAuthenticationSource.Type,
                                 providerSource: EmailProviderSource.Type,
                                 sender: String,
                                 joinRoute: [PathComponent] = Self.joinRoute,
                                 passwordResetRoute: [PathComponent] = Self.passwordResetRoute,
                                 passwordUpdateRoute: [PathComponent] = Self.passwordUpdateRoute) throws {
        // Class properties
        self.authenticationSource = authenticationSource
        self.providerSource = providerSource
        self.sender = sender
        self.joinRoute = joinRoute
        self.passwordResetRoute = passwordResetRoute
        self.passwordUpdateRoute = passwordUpdateRoute
        // Migrations
        app.migrations.add(EmailAuthentication.Migration())
    }
}

// MARK: - RouteController
extension EmailAuthenticationController: RouteCollection {
    public static var joinRoute: [PathComponent] = ["join"]
    public static var signInRoute: [PathComponent] = ["sign-in"]
    public static var passwordResetRoute: [PathComponent] = ["password-reset"]
    public static var passwordUpdateRoute: [PathComponent] = ["password-update"]
    public static let stateKey = "state"

    public func boot(routes: any RoutesBuilder) throws {
        routes.post(Self.joinRoute, use: sendJoin)
        routes.get(Self.joinRoute + [":\(Self.stateKey)"], use: redeemJoin)
        routes.post(Self.passwordResetRoute, use: sendPasswordReset)
        routes.get(Self.passwordResetRoute + [":\(Self.stateKey)"], use: redeemPasswordReset)
        routes.post(Self.signInRoute, use: signIn)
        #warning("TODO: password update needs to be on user authenticated route")
        routes.get(Self.passwordUpdateRoute, use: updatePassword)
    }
    
    func sendJoin(req: Request) async throws -> HTTPStatus {
        try await Self.sendJoin(req: req)
        return .ok
    }
    
    func redeemJoin(req: Request) async throws -> HTTPStatus {
        try await Self.redeemJoin(req: req)
        return .ok
    }
    
    func signIn(req: Request) async throws -> HTTPStatus {
        try await Self.signIn(req: req)
        return .ok
    }
    
    func sendPasswordReset(req: Request) async throws -> HTTPStatus {
        try await Self.sendPasswordReset(req: req)
        return .ok
    }
    
    func redeemPasswordReset(req: Request) async throws -> HTTPStatus {
        try await Self.redeemPasswordReset(req: req)
        return .ok
    }
    
    func updatePassword(req: Request) async throws -> HTTPStatus {
        try await Self.updatePassword(req: req)
        return .ok
    }
}

// MARK: - Join
extension EmailAuthenticationController {
    static func sendJoin(_ join: EmailCredentials? = nil, req: Request) async throws {
        guard let s = Self.authenticationSource else { throw Abort(.internalServerError) }
        let j = try join ?? req.content.decode(EmailCredentials.self)
        // user with email must not exist
        let passwordHash = try s.passwordHash(j.password)
        let method = AuthenticationMethod.email(j.email, passwordHash: passwordHash)
        guard try await !AuthenticationController.isExistingUser(method, db: req.db) else {
            throw Exception.userExists(email: j.email)
        }
        let path = j.isApp ? "yousnite://join/" : AuthenticationViewController.joinPath(isRelative: false)
        let kind = EmailKind.invite(path: path, password: j.password)
        try await Self.sendEmail(kind, to: j.email, req: req)
    }
    
    static func redeemJoin(req: Request) async throws {
        let state = try Self.state(req: req)
        // get email and password for the state... throws if expired
        let (email, passwordHash) = try await Self.emailPasswordHash(for: state, isJoin: true, db: req.db)
        // delete any extra records with same email
        try await deleteRecords(for: email, db: req.db)
        // create user
        let method = AuthenticationMethod.email(email, passwordHash: passwordHash)
        try await AuthenticationController.createUser(method, db: req.db)
    }
}

// MARK: - Sign In
extension EmailAuthenticationController {
    static func signIn(_ signIn: EmailCredentials? = nil, req: Request) async throws {
        guard let s = Self.authenticationSource else { throw Abort(.internalServerError) }
        let si = try signIn ?? req.content.decode(EmailCredentials.self)
        // find user
        let passwordHash = try s.passwordHash(si.password)
        let method = AuthenticationMethod.email(si.email, passwordHash: passwordHash)
        guard let user = try await AuthenticationController.user(method, db: req.db) else {
            throw Exception.noUser(email: si.email)
        }
        // check password
        guard try AuthenticationController.verify(si.password, for: user, db: req.db) else {
            throw Exception.wrongPassword(email: si.email)
        }
        try AuthenticationController.authenticate(user, req: req)
    }
}

// MARK: - Password Reset
extension EmailAuthenticationController {
    static func sendPasswordReset(_ reset: EmailCredentials? = nil, req: Request) async throws {
        guard let s = Self.authenticationSource else { throw Abort(.internalServerError) }
        let r = try reset ?? req.content.decode(EmailCredentials.self)
        // user with email must already exist
        let passwordHash = try s.passwordHash(r.password)
        let method = AuthenticationMethod.email(r.email, passwordHash: passwordHash)
        guard try await AuthenticationController.isExistingUser(method, db: req.db) else {
            throw Exception.noUser(email: r.email)
        }
        let path = r.isApp ? "yousnite://password-reset/" : AuthenticationViewController.passwordResetPath(isRelative: false)
        let kind = EmailKind.passwordReset(path: path, password: r.password)
        try await Self.sendEmail(kind, to: r.email, req: req)
    }
    
    static func redeemPasswordReset(req: Request) async throws {
        guard let s = authenticationSource else { throw Abort(.internalServerError) }
        let state = try Self.state(req: req)
        // get email and password for the state... throws if expired
        let (address, passwordHash) = try await Self.emailPasswordHash(for: state, isJoin: false, db: req.db)
        // delete any extra records with same email
        try await deleteRecords(for: address, db: req.db)
        // update user
        let method = AuthenticationMethod.email(address, passwordHash: passwordHash)
        guard let user = try await AuthenticationController.user(method, db: req.db) else {
            throw Exception.noUser(email: address)
        }
        try await s.update(passwordHash: passwordHash, user: user, db: req.db)
    }
}

// MARK: - Password Update
extension EmailAuthenticationController {
    static func updatePassword(_ update: EmailCredentials? = nil, req: Request) async throws {
        guard let s = authenticationSource else { throw Abort(.internalServerError) }
        let u = try update ?? req.content.decode(EmailCredentials.self)
        // user must be authenticated
        guard try AuthenticationController.isSignedIn(req: req) else {
            throw Exception.noAuthenicatedUser
        }
        let email = try await s.updateAuthenticatedUser(password: u.password, req: req)
        try await Self.sendEmail(.passwordUpdated, to: email, req: req)
    }
}

// MARK: - Miscellaneous Utilities
extension EmailAuthenticationController {
    public enum EmailKind: Codable {
        case invite(path: String, password: String)
        case passwordReset(path: String, password: String)
        case passwordUpdated
    }
    
    static var expires: TimeInterval = 900
        
    static func sendEmail(_ kind: EmailKind,
                          to address: String,
                          req: Request) async throws {
        guard let s = Self.authenticationSource,
              let ps = Self.providerSource,
              let sender = Self.sender
        else {
            throw Abort(.internalServerError)
        }
        let state = Self.state()
        let statePathComponent = "/" + (state.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? state)
        var result: String?
        var isSent: Bool = false
        var isSave: Bool = true  // create record
        var isJoin = false
        var password: String?
        do {
            switch kind {
            case .invite(let path, let pw):
                result = try await ps.emailInvite(link: path + statePathComponent, to: address, from: sender)
                password = pw
                isJoin = true
            case .passwordReset(let path, let pw):
                result = try await ps.emailPasswordReset(link: path + statePathComponent, to: address, from: sender)
                password = pw
            case .passwordUpdated:
                result = try await ps.emailPasswordUpdated(to: address, from: sender)
                isSave = false
            }
            isSent = true
        } catch {
            result = error.localizedDescription
        }
        if isSave,
           let password = password {
            let passwordHash = try s.passwordHash(password)
            let ae = EmailAuthentication(state: state,
                                         isJoin: isJoin,
                                         email: address,
                                         passwordHash: passwordHash,
                                         expiresAfter: Self.expires,
                                         isFailed: !isSent,
                                         result: result)
            try await ae.save(on: req.db)
        }
        guard isSent else {
            throw Exception.unableToEmail(kind, to: address, error: result ?? "Unknown Error")
        }
    }
    
    static func emailPasswordHash(for state: String, isJoin: Bool, db: Database) async throws -> (String, String) {
        guard let ea = try await EmailAuthentication
            .query(on: db)
            .filter(\.$state == state)
            .filter(\.$isJoin == isJoin)
            .first()
        else { throw Exception.inviteInvalid }
        // remove record
        guard !ea.isExpired else { throw Exception.inviteExpired(ea.email) }
        return (ea.email, ea.passwordHash)
    }
    
    static func deleteRecords(for email: String, db: Database) async throws {
        let all = try await EmailAuthentication
            .query(on: db)
            .filter(\.$email == email)
            .all()
        for each in all {
            try await each.delete(on: db)
        }
    }
    
    static func state(count: Int = 32, isURLEncoded: Bool = false) -> String {
        [UInt8].random(count: count).base64
    }
    
    static func state(req: Request) throws -> String {
        guard let state = req.parameters.get("state") else {
            throw Abort(.notFound)
        }
        return state
    }
}

// MARK: - Errors
extension EmailAuthenticationController {
    enum Exception: Error, Codable {
        case noEmail
        case invalidEmail(_ address: String)
        case noPassword
        case passwordTooLong(extra: Int)
        case userExists(email: String)
        case noUser(email: String)
        case wrongPassword(email: String)
        case noAuthenicatedUser
        case unableToEmail(_ kind: EmailKind, to: String, error: String)
        case inviteInvalid
        case inviteExpired(_ address: String)
        case passwordResetInvalid
        case passwordResetExpired
    }
}

extension EmailAuthenticationController.Exception: AbortError {
    
    var status: HTTPResponseStatus {
        switch self {
        case .noEmail: return .unauthorized
        case .invalidEmail: return .unauthorized
        case .noPassword: return .unauthorized
        case .passwordTooLong: return .unauthorized
        case .userExists: return .unauthorized
        case .noUser: return .unauthorized
        case .wrongPassword: return .unauthorized
        case .noAuthenicatedUser: return .unauthorized
        case .unableToEmail: return .unauthorized
        case .inviteInvalid: return .unauthorized
        case .inviteExpired: return .unauthorized
        case .passwordResetInvalid: return .unauthorized
        case .passwordResetExpired: return .unauthorized
        }
    }
    
    var reason: String {
        switch self {
        case .noEmail: return "Enter an email address."
        case .invalidEmail: return "Enter a valid email address."
        case .noPassword: return "Enter a password."
        case .passwordTooLong (let extra): return "Password is \(extra) character(s) too long."
        case .userExists: return "Email already registered."
        case .noUser: return "No registered account."
        case .wrongPassword: return "Password incorrect."
        case .noAuthenicatedUser: return "Not signed in."
        case .unableToEmail(let kind, _, _):
            let type: String
            switch kind {
            case .invite:
                type = "invite"
            case .passwordReset:
                type = "passowrd reset"
            case .passwordUpdated:
                type = "password updated"
            }
            return "Unable to email \(type) due to internal error."
        case .inviteInvalid: return "Invalid invitation."
        case .inviteExpired: return "Invitation has expired."
        case .passwordResetInvalid: return "Password reset is invalid."
        case .passwordResetExpired: return "Password reset has expired."
        }
    }
}

extension EmailAuthenticationController.Exception: LocalizedError {
    public var errorDescription: String? { reason }
}
