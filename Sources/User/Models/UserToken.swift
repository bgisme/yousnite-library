import Vapor
import Fluent

final public class UserToken: Model {
    
    public static let schema = "user_tokens"
    
    public static var expires = TimeInterval(60 * 60 * 24)
    
    @ID(key: .id) public var id: UUID?
    @Parent(key: "user_id") public var user: User
    @Field(key: "value") public var value: String
    @OptionalField(key: "expires_at") public var expiresAt: Date?
    @Timestamp(key: "created_at", on: .create) public var createdAt: Date?
    
    public init() {}
    
    public init(id: UUID? = nil,
                user: User,
                value: String = [UInt8].random(count: 16).base64,
                expires: TimeInterval? = UserToken.expires) throws {
        self.id = id
        self.$user.id = try user.requireID()
        self.value = value
        self.expiresAt = expires != nil ? Date().addingTimeInterval(expires!) : nil
    }
}

// MARK: - ModelTokenAuthenticatable
extension UserToken: ModelTokenAuthenticatable {
    public static let valueKey = \UserToken.$value
    public static let userKey = \UserToken.$user
    
    public var isValid: Bool {
        guard let expiresAt = expiresAt else {
            return true
        }
        return expiresAt > Date()
    }
}
