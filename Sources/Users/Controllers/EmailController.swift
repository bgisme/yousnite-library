import Vapor
import Fluent

public struct EmailController: Sendable {
    public init() { }
}

// MARK: - Configure
extension EmailController {
    static var delegate: EmailDelegate.Type!
    static var sender: String?
    
    public static func configure(app: Application,
                                 delegate: EmailDelegate.Type,
                                 sender: String,
                                 joinRoute: [PathComponent] = Self.joinRoute,
                                 passwordResetRoute: [PathComponent] = Self.passwordResetRoute,
                                 passwordUpdateRoute: [PathComponent] = Self.passwordUpdateRoute) throws {
        // Class properties
        self.delegate = delegate
        self.sender = sender
        self.joinRoute = joinRoute
        self.passwordResetRoute = passwordResetRoute
        self.passwordUpdateRoute = passwordUpdateRoute
        // Migrations
        app.migrations.add(PasswordToken.Migration())
    }
}

// MARK: - RouteController
extension EmailController: RouteCollection {
    public static var joinRoute: [PathComponent] = ["join"]
    public static var signInRoute: [PathComponent] = ["sign-in"]
    public static var passwordRoute: [PathComponent] = ["password"]
    public static var passwordResetRoute: [PathComponent] = ["password-reset"]
    public static var passwordUpdateRoute: [PathComponent] = ["password-update"]
    public static let stateKey = "state"
    
    public func boot(routes: any RoutesBuilder) throws {
        routes.get(Self.passwordRoute + [":\(Self.stateKey)"], use: passwordReset)
        routes.get(Self.passwordUpdateRoute, use: passwordUpdate)
        routes.post(Self.signInRoute, use: signIn)
    }
    
    func signIn(req: Request) async throws -> HTTPStatus {
        try await Self.signIn(req: req)
        return .ok
    }
    
    func passwordReset(req: Request) async throws -> HTTPStatus {
        try await Self.changePassword(isFromAPI: true, req: req)
        return .ok
    }
    
    func passwordUpdate(req: Request) async throws -> HTTPStatus {
        try await Self.changePassword(isUpdate: true, isFromAPI: true, req: req)
        return .ok
    }
}

// MARK: - Password Change
extension EmailController {
    static func requestPasswordUpdate(email: String,
                                      isNewUser: Bool = false,
                                      isFromAPI: Bool = false,
                                      req: Request) async throws {
        // check conflicts... new user but one exists... not new user and one does not exist
        let method = AuthenticationMethod.email(email)
        let isExisting = try await MainController.delegate.user(method, on: req.db) != nil
        let isNewAndNotExisting = isNewUser && !isExisting
        let isNotNewAndExisting = !isNewUser && isExisting
        guard isNewAndNotExisting || isNotNewAndExisting else {
            throw isNewUser ? Exception.userExists(email: email) : Exception.noUser(email: email)
        }
        // make state value for password token
        let state = Self.state()
        // assemble email link with state value
        var path = isFromAPI ? "yousnite://password" : ViewController.passwordUpdatePath(isRelative: false)
        path += "/" + (state.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? state)
        path += ViewController.isNewUserQueryParameter(isNewUser)
        let kind: EmailKind = isNewUser ? .invite(state: state, path: path) : .passwordReset(state: state, path: path)
        try await Self.sendEmail(kind, to: email, req: req)
    }
        
    typealias User = any UserAuthenticatable
    typealias IsNew = Bool
    
    @discardableResult
    static func changePassword(isUpdate: Bool = false,
                               isFromAPI: Bool = false,
                               req: Request) async throws -> (User, IsNew) {
        let user: User
        var isNew = false
        guard let p = try? req.content.decode(Password.self) else {
            throw Abort(.internalServerError)
        }
        if isUpdate {
            // user must be authenticated
            guard let u = try MainController.delegate.authenticatedUser(req: req) else {
                throw Exception.noAuthenicatedUser
            }
            user = u
            try await user
                .set(.email(u.email, password: p.value))
                .save(on: req.db)
            try await Self.sendEmail(.passwordUpdated, to: u.email, req: req)
        } else {
            // fetch password token
            let pt = try await passwordToken(isAllDeleted: true, req: req)
            // throw if expired
            guard !pt.isExpired else { throw Exception.passwordTokenExpired(pt.email) }
            // if user exists — update... if not — create
            let method = AuthenticationMethod.email(pt.email, password: p.value)
            if let u = try await MainController.delegate.user(method, on: req.db) {
                user = u
            } else {
                user = try await MainController.delegate.createUser(method, on: req.db)
                isNew = true
            }
        }
        return (user, isNew)
    }
    
    private static func passwordToken(isAllDeleted: Bool = false, req: Request) async throws -> PasswordToken {
        // get state from request
        guard let state = try? Self.state(req: req) else {
            throw Abort(.internalServerError)
        }
        // fetch password token for state value
        guard let pt = try await PasswordToken
            .query(on: req.db)
            .filter(\.$state == state)
            .first()
        else { throw Exception.passwordTokenInvalid }
        // throw if token expired
        guard !pt.isExpired else { throw Exception.passwordTokenExpired(pt.email) }
        if isAllDeleted {
            // delete all records with email... in case user made multiple requests
            let all = try await PasswordToken
                .query(on: req.db)
                .filter(\.$email == pt.email)
                .all()
            for each in all {
                try await each.delete(on: req.db)
            }
        }
        return pt
    }
}

// MARK: - Sign In
extension EmailController {
    static func signIn(_ signIn: SignIn? = nil, req: Request) async throws {
        let si = try signIn ?? req.content.decode(SignIn.self)
        let email = si.email.address
        let password = si.password.value
        // find user
        guard let user = try await MainController.delegate.user(.email(email), on: req.db) else {
            throw Exception.noUser(email: email)
        }
        // check password
        guard try user.verify(password: password) else {
            throw Exception.wrongPassword(email: email)
        }
        try MainController.delegate.authenticate(user, req: req)
    }
}

// MARK: - Miscellaneous Utilities
extension EmailController {
    public enum EmailKind: Codable {
        case invite(state: String, path: String)
        case passwordReset(state: String, path: String)
        case passwordUpdated
    }
    
    static var expires: TimeInterval = 900
    
    static func sendEmail(_ kind: EmailKind,
                          to address: String,
                          req: Request) async throws {
        guard let d = Self.delegate,
              let sender = Self.sender
        else {
            throw Abort(.internalServerError)
        }
        var result: String?
        var isSent: Bool = false
        do {
            switch kind {
            case .invite(let state, let path):
                result = try await d.emailInvite(link: path, to: address, from: sender)
                try await createPasswordToken(state: state, email: address, result: result, db: req.db)
            case .passwordReset(let state, let path):
                result = try await d.emailPasswordReset(link: path, to: address, from: sender)
                try await createPasswordToken(state: state, email: address, result: result, db: req.db)
            case .passwordUpdated:
                result = try await d.emailPasswordUpdated(to: address, from: sender)
            }
            isSent = true
        } catch {
            result = error.localizedDescription
        }
        guard isSent else {
            throw Exception.unableToEmail(kind, to: address, error: result ?? "Unknown Error")
        }
    }
    
    @discardableResult
    static func createPasswordToken(state: String,
                                    email: String,
                                    expiresAfter: TimeInterval = Self.expires,
                                    isFailed: Bool = false,
                                    result: String?,
                                    db: Database) async throws -> PasswordToken {
        let pt = PasswordToken(state: state,
                               email: email,
                               expiresAfter: expiresAfter,
                               isFailed: isFailed,
                               result: result)
        try await pt.save(on: db)
        return pt
    }
        
    static func state(count: Int = 32, isURLEncoded: Bool = false) -> String {
        let state = [UInt8].random(count: count).base64
        let urlEncodedState = state.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? state
        return isURLEncoded ? urlEncodedState : state
    }
    
    static func state(req: Request) throws -> String {
        guard let state = req.parameters.get("state") else {
            throw Abort(.notFound)
        }
        return state
    }
    
    static func email(for state: String, db: Database) async throws -> String {
        guard let pt = try await PasswordToken
            .query(on: db)
            .filter(\.$state == state)
            .first()
        else {
            throw Abort(.internalServerError)
        }
        return pt.email
    }
}

// MARK: - Errors
extension EmailController {
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
        case passwordTokenInvalid
        case passwordTokenExpired(_ email: String)
//        case inviteInvalid
//        case inviteExpired(_ address: String)
//        case passwordResetInvalid
//        case passwordResetExpired
    }
}

extension EmailController.Exception: AbortError {
    
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
        case .passwordTokenInvalid: return .unauthorized
        case .passwordTokenExpired(_): return .unauthorized
//        case .inviteInvalid: return .unauthorized
//        case .inviteExpired: return .unauthorized
//        case .passwordResetInvalid: return .unauthorized
//        case .passwordResetExpired: return .unauthorized
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
        case .passwordTokenInvalid: return "Invalid password change."
        case .passwordTokenExpired(let email): return "Password change for \(email) expired."
//        case .inviteInvalid: return "Invalid invitation."
//        case .inviteExpired: return "Invitation has expired."
//        case .passwordResetInvalid: return "Password reset is invalid."
//        case .passwordResetExpired: return "Password reset has expired."
        }
    }
}

extension EmailController.Exception: LocalizedError {
    public var errorDescription: String? { reason }
}
