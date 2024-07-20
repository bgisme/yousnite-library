import Vapor
import Fluent

final class UserToken: Model, Content, @unchecked Sendable {
    static let schema = "user_tokens"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @Field(key: "value") var value: String
    @Field(key: "expires_at") var expiresAt: Date
    @Field(key: "is_revoked") var isRevoked: Bool

    init() { }

    init(id: UUID? = nil, 
         user: User,
         value: String,
         expiresAt: Date = Date().addingTimeInterval(60 * 60 * 24)) throws {
        self.id = id
        self.$user.id = try user.requireID()
        self.value = value
        self.expiresAt = expiresAt
        self.isRevoked = false
    }
}

extension UserToken {
    enum CodingKeys {
        case id
        case user
        case value
        case expiresAt
    }
}
