import Vapor
import Fluent

final public class User: Model, Content, @unchecked Sendable {
    public static let schema = "users"
    
    @ID(key: .id) public var id: UUID?
    @Field(key: "email") public var email: String
    @Enum(key: "type") public var type: AuthenticationType
    @Field(key: "value") public private(set) var value: String   // id for apple + google, password_hash for email
    @Timestamp(key: "joined_at", on: .create) public var joinedAt: Date?
    @OptionalField(key: "unjoined_at") public var unjoinedAt: Date?
    
    public func setValue(_ value: String) throws {
        switch type {
        case .apple, .google:
            self.value = value
        case .email:
            self.value = try Self.hash(value)
        }
    }
    
    public init() { }
    
    public init(id: UUID? = nil,
                email: String,
                type: AuthenticationType,
                value: String) throws {
        self.id = id
        self.email = email
        self.type = type
        self.value = type == .email ? try Self.hash(value) : value
        self.unjoinedAt = nil
    }
    
    public enum CodingKeys: CodingKey {
        case email
        case type
        case value
        case joinedAt
        case unjoinedAt
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.email = try container.decode(String.self, forKey: .email)
        self.type = try container.decode(AuthenticationType.self, forKey: .type)
        self.value = try container.decode(String.self, forKey: .value)
        self.joinedAt = try container.decode(Date.self, forKey: .joinedAt)
        self.unjoinedAt = try container.decode(Date.self, forKey: .unjoinedAt)
    }
}

// MARK: - Utilities
extension User {
    private static func hash(_ password: String) throws -> String {
        try Bcrypt.hash(password)
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
    public static func find(_ method: AuthenticationMethod, in db: Database) async throws -> User {
        let user: User?
        switch method {
        case .apple(_, let id), .google(_, let id):
            user = try await User
                .query(on: db)
                .filter(\.$type == method.type)
                .filter(\.$value == id)
                .first()
        case .email(let address, _):
            user = try await User
                .query(on: db)
                .filter(\.$type == method.type)
                .filter(\.$email == address)
                .first()
        }
        guard let user = user else { throw Abort(.notFound) }
        return user
    }
    
    public static func type(_ email: String, in db: Database) async throws -> AuthenticationType {
        guard let user = try await User
            .query(on: db)
            .filter(\.$email == email)
            .first() else {
            throw Abort(.notFound)
        }
        return user.type
    }
}
