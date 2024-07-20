import Vapor
import Fluent

final class Credential: Model, Content, @unchecked Sendable {
    public static let schema = "credentials"
    
    @ID(key: .id) public var id: UUID?
    @Field(key: "email") public var email: String
    @Enum(key: "type") public var type: CredentialType
    @Field(key: "value") public private(set) var value: String   // id for apple + google, password_hash for email
    @Timestamp(key: "joined_at", on: .create) public var joinedAt: Date?
    @OptionalField(key: "unjoined_at") public var unjoinedAt: Date?
    @Field(key: "user_id") public var userId: UUID
    
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
                type: CredentialType,
                value: String,
                userId: UUID) throws {
        self.id = id
        self.email = email
        self.type = type
        self.value = type == .email ? try Self.hash(value) : value
        self.unjoinedAt = nil
        self.userId = userId
    }
    
    public enum CodingKeys: CodingKey {
        case email
        case type
        case value
        case joinedAt
        case unjoinedAt
        case userId
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.email = try container.decode(String.self, forKey: .email)
        self.type = try container.decode(CredentialType.self, forKey: .type)
        self.value = try container.decode(String.self, forKey: .value)
        self.joinedAt = try container.decode(Date.self, forKey: .joinedAt)
        self.unjoinedAt = try container.decode(Date.self, forKey: .unjoinedAt)
        self.userId = try container.decode(UUID.self, forKey: .userId)
    }
}

// MARK: - Utilities
extension Credential {
    private static func hash(_ password: String) throws -> String {
        try Bcrypt.hash(password)
    }
}

// MARK: - Public Representation
extension Credential {
    public struct Public: Content {
        let id: UUID
        let email: String
        
        init(_ credential: Credential) throws {
            self.id = try credential.requireID()
            self.email = credential.email
        }
    }
    
    public func asPublic() throws -> Public {
        try .init(self)
    }
}

// MARK: - Utilities
extension Credential {
    public static func find(_ method: CredentialMethod, in db: Database) async throws -> Credential {
        let credential: Credential?
        switch method {
        case .apple(_, let id), .google(_, let id):
            credential = try await Credential
                .query(on: db)
                .filter(\.$type == method.type)
                .filter(\.$value == id)
                .first()
        case .email(let address, _):
            credential = try await Credential
                .query(on: db)
                .filter(\.$type == method.type)
                .filter(\.$email == address)
                .first()
        }
        guard let credential = credential else { throw Abort(.notFound) }
        return credential
    }
    
    public static func type(_ email: String, in db: Database) async throws -> CredentialType {
        guard let credential = try await Credential
            .query(on: db)
            .filter(\.$email == email)
            .first() else {
            throw Abort(.notFound)
        }
        return credential.type
    }
}

public enum CredentialType: String, Codable {
    case apple
    case email
    case google
}

extension Credential {
    public convenience init(_ method: CredentialMethod, userId: UUID) throws {
        let (email, type, value) = Self.emailTypeValue(method)
        try self.init(email: email, type: type, value: value, userId: userId)
    }
    
    public func update(_ method: CredentialMethod) throws -> Credential {
        let (email, type, value) = Self.emailTypeValue(method)
        self.email = email
        self.type = type
        try setValue(value)
        self.unjoinedAt = nil   // unjoined user rejoining via password reset
        return self
    }
    
    private static func emailTypeValue(_ method: CredentialMethod) -> (String, CredentialType, String) {
        let email: String
        let type: CredentialType
        let value: String
        
        switch method {
        case .apple(let address, let appleID):
            type = .apple
            email = address
            value = appleID
        case .email(let address, let password):
            type = .email
            email = address
            value = password
        case .google(let address, let googleID):
            type = .google
            email = address
            value = googleID
        }
        return (email, type, value)
    }
}
