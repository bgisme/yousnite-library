import Vapor
import Fluent

public struct EmailController: Sendable {
    public init() { }
}

// MARK: - Configure
extension EmailController {
    static var delegate: EmailDelegate!
    
    public static func configure(app: Application,
                                 delegate: some EmailDelegate) throws {
        self.delegate = delegate

        // Migrations
        app.migrations.add(PasswordToken.Migration())
    }
}

// MARK: - Tokens
extension EmailController {
    static var expires: TimeInterval = 900
    
    @discardableResult
    static func createPasswordToken(state: String,
                                    email: String,
                                    expiresAfter: TimeInterval = Self.expires,
                                    isFailed: Bool = false,
                                    db: Database) async throws -> PasswordToken {
        let pt = PasswordToken(state: state,
                               email: email,
                               expiresAfter: expiresAfter,
                               isFailed: isFailed)
        try await pt.save(on: db)
        return pt
    }
    
    static func token(count: Int = 32) -> String {
        [UInt8].random(count: count).base64
    }
    
    static func urlEncoded(_ token: String) -> String {
        token.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? token
    }
}

// MARK: - Send Email
extension EmailController {
    public enum EmailKind: Codable {
        case invite(token: String, link: URL)
        case joined(_ AuthenticationKind: AuthenticationType)
        case passwordReset(token: String, link: URL)
        case passwordSet
        case unjoined(_ AuthenticationKind: AuthenticationType)
        
        var description: String {
            switch self {
            case .invite: "invite"
            case .joined: "joined"
            case .passwordReset: "passwordReset"
            case .passwordSet: "passwordSet"
            case .unjoined: "unjoined"
            }
        }
    }
        
    static func sendEmail(_ kind: EmailKind,
                          to toAddress: String,
                          req: Request) async throws {
        do {
            switch kind {
            case .invite(let state, let link):
                let invite = EmailPurpose.invite(link: link, toAddress: toAddress)
                try await Self.delegate.email(invite, req: req)
                try await createPasswordToken(state: state,
                                              email: toAddress,
                                              db: req.db)
            case .joined(let type):
                let join = EmailPurpose.joined(toAddress: toAddress, type: type)
                try await Self.delegate.email(join, req: req)
            case .passwordReset(let state, let link):
                let passwordReset = EmailPurpose.passwordReset(link: link, toAddress: toAddress)
                try await Self.delegate.email(passwordReset, req: req)
                try await createPasswordToken(state: state,
                                              email: toAddress,
                                              db: req.db)
            case .passwordSet:
                let update = EmailPurpose.passwordUpdated(toAddress: toAddress)
                try await Self.delegate.email(update, req: req)
            case .unjoined(let type):
                let quit = EmailPurpose.quit(toAddress: toAddress, type: type)
                try await Self.delegate.email(quit, req: req)
            }
        } catch {
            req.logger.critical("Email Failed", [
                "to": toAddress,
                "kind": kind.description,
                "error": error.localizedDescription,
            ])
            switch kind {
            case .invite, .passwordReset:
                throw error
            default:
                // other kinds are just notification... user will not miss them
                break
            }
        }
    }
    
    static func sendPasswordCreateResetLink(to toAddress: String,
                                            isNewUser: Bool,
                                            isToApp: Bool,
                                            req: Request) async throws {
        let token = token()
        let path = UserController.passwordSetPath(isAbsolute: true,
                                                 isToApp: isToApp,
                                                 urlEncodedToken: urlEncoded(token))
        guard let link = URL(string: path) else { throw Abort(.internalServerError) }
        let kind: EmailKind
        if isNewUser {
            kind = .invite(token: token, link: link)
        } else {
            kind = .passwordReset(token: token, link: link)
        }
        try await Self.sendEmail(kind, to: toAddress, req: req)
    }
}

// MARK: - Retrieve Email Address
extension EmailController {
    static func email(for state: String,
                      deleteOthersWithEmail isOthersDeleted: Bool = false,
                      db: Database) async throws -> String? {
        // fetch password token for state value
        guard let pt = try await PasswordToken
            .query(on: db)
            .filter(\.$state == state)
            .first()
        else {
            return nil
        }
        if isOthersDeleted {
            // delete all records with email... in case user made multiple requests
            let all = try await PasswordToken
                .query(on: db)
                .filter(\.$email == pt.email)
                .all()
            for each in all {
                try await each.delete(on: db)
            }
        }
        return !pt.isExpired ? pt.email : nil
    }
}
