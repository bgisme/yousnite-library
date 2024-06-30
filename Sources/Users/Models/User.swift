import Vapor
import Fluent

final public class User: Model, Content, @unchecked Sendable {
    public static let schema = "users"
    
    @ID(key: .id) public var id: UUID?
    @Field(key: "email") public var email: String
    @Enum(key: "type") public var type: AuthenticationType
    @Field(key: "value") public var value: String   // id for apple + google, password_hash for email
    
    private static func passwordHash(_ password: String) throws -> String {
        try Bcrypt.hash(password)
    }
    
    public func setPassword(_ password: String) throws {
        self.value = try Self.passwordHash(password)
    }
    
    public init() { }
    
    public init(id: UUID? = nil,
                email: String,
                type: AuthenticationType,
                value: String) throws {
        self.id = id
        self.email = email
        self.type = type
        self.value = type == .email ? try Self.passwordHash(value) : value
    }
    
    public enum CodingKeys: CodingKey {
        case email
        case type
        case value
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.email = try container.decode(String.self, forKey: .email)
        self.type = try container.decode(AuthenticationType.self, forKey: .type)
        self.value = try container.decode(String.self, forKey: .value)
    }
}

// MARK: - Public Representation
extension User {
    public struct Public: Content {
        let id: UUID
        let email: String
        
        init(user: User) throws {
            self.id = try user.requireID()
            self.email = user.email
        }
    }
    
    public func asPublic() throws -> Public {
        try .init(user: self)
    }
}

// MARK: - Utilities
extension User {
    public static func find(_ method: AuthenticationMethod, in db: Database) async throws -> User? {
        switch method {
        case .apple(_, let id), .google(_, let id):
            return try await User
                .query(on: db)
                .filter(\.$type == method.type)
                .filter(\.$value == id)
                .first()
        case .email(let address, _):
            return try await User
                .query(on: db)
                .filter(\.$type == method.type)
                .filter(\.$email == address)
                .first()
        }
    }
}
