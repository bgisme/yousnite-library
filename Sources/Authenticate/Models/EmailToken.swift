import Vapor
import Fluent

final class EmailToken: Model, Content, @unchecked Sendable {
    static let schema = "email_tokens"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "state") var state: String
    @Field(key: "email") var email: String
    @Timestamp(key: "expires_at", on: .none) var expiresAt: Date?
    @Timestamp(key: "sent_at", on: .none) var sentAt: Date?
    
    init() {}
    
    init(id: UUID? = nil,
         state: String,
         email: String,
         expiresAfter: TimeInterval = 600,
         isFailed: Bool = false) {
        self.id = id
        self.state = state
        self.email = email
        self.expiresAt = Date().addingTimeInterval(expiresAfter)
        self.sentAt = !isFailed ? Date() : nil
    }
    
    var isExpired: Bool { expiresAt != nil ? expiresAt!.timeIntervalSinceNow < 0 : false }
    
    func renewExpiresAt(_ value: TimeInterval = 600) {
        self.expiresAt = Date().addingTimeInterval(value)
    }
}

// MARK: - Utilities
extension EmailToken {
    static func find(email: String, db: Database) async throws -> EmailToken {
        guard let ae = try await EmailToken
            .query(on: db)
            .filter(\.$email == email)
            .first()
        else {
            throw Exception.notFound
        }
        guard !ae.isExpired else { throw Exception.expired }
        return ae
    }
    
    static func find(state: String, db: Database) async throws -> EmailToken {
        guard let ae = try await EmailToken
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
