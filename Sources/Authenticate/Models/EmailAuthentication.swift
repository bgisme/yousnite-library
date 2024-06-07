import Vapor
import Fluent

/// Sole purpose of this class is to preserve a state value for email invitations and password resets
final class EmailAuthentication: Model, Content {
    static let schema = "email_authentications"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "state") var state: String
    @Boolean(key: "is_join") var isJoin: Bool
    @Field(key: "email") var email: String
    @Field(key: "password_hash") var passwordHash: String
    @Timestamp(key: "expires_at", on: .none) var expiresAt: Date?
    @Timestamp(key: "sent_at", on: .none) var sentAt: Date?
    @OptionalField(key: "result") var result: String?
    
    init() {}
    
    init(id: UUID? = nil,
         state: String,
         isJoin: Bool,
         email: String,
         passwordHash: String,
         expiresAfter: TimeInterval = 600,
         isFailed: Bool = false,
         result: String?) {
        self.id = id
        self.state = state
        self.isJoin = isJoin
        self.email = email
        self.passwordHash = passwordHash
        self.expiresAt = Date().addingTimeInterval(expiresAfter)
        self.sentAt = !isFailed ? Date() : nil
        self.result = result
    }
    
    var isExpired: Bool { expiresAt != nil ? expiresAt!.timeIntervalSinceNow < 0 : false }
    
    func renewExpiresAt(_ value: TimeInterval = 600) {
        self.expiresAt = Date().addingTimeInterval(value)
    }
}

// MARK: - Utilities
extension EmailAuthentication {
    static func find(email: String, db: Database) async throws -> EmailAuthentication {
        guard let ae = try await EmailAuthentication
            .query(on: db)
            .filter(\.$email == email)
            .first()
        else {
            throw Exception.notFound
        }
        guard !ae.isExpired else { throw Exception.expired }
        return ae
    }
    
    static func find(state: String, db: Database) async throws -> EmailAuthentication {
        guard let ae = try await EmailAuthentication
            .query(on: db)
            .filter(\.$state == state)
            .first()
        else {
            throw Exception.notFound
        }
        guard !ae.isExpired else {
            throw Exception.expired
        }
        return ae
    }
    
    enum Exception: Error {
        case notFound
        case expired
    }
}
