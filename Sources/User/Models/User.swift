import Fluent
import Vapor
import JWT
import Authenticate

final public class User: Model, Content {
    public static let schema = "users"
    
    @ID(key: .id) public var id: UUID?
    @Field(key: "email") public var email: String
    @Enum(key: "auth_type") public var authType: AuthenticationType
    @Field(key: "auth_value") public var authValue: String   // id for apple + google, password_hash for email
    
    public static func passwordHash(_ password: String) throws -> String {
        try Bcrypt.hash(password)
    }
    
    public func setPasswordHash(_ hash: String) { self.authValue = hash }
    
    public func setPassword(_ password: String) throws { self.authValue = try Self.passwordHash(password) }
    
    public init() { }
    
    public convenience init(id: UUID? = nil, email: String, password: String) throws {
        let passwordHash = try Self.passwordHash(password)
        try self.init(id: id, email: email, passwordHash: passwordHash)
    }
    
    public convenience init(id: UUID? = nil, email: String, passwordHash: String) throws {
        try self.init(id: id, email: email, authType: .email, authValue: passwordHash)
    }
    
    public convenience init(id: UUID? = nil, email: String, appleID: String) throws {
        try self.init(id: id, email: email, authType: .apple, authValue: appleID)
    }
    
    public convenience init(id: UUID? = nil, email: String, googleID: String) throws {
        try self.init(id: id, email: email, authType: .google, authValue: googleID)
    }
    
    private init(id: UUID? = nil,
                 email: String,
                 authType: AuthenticationType,
                 authValue: String) throws {
        self.id = id
        self.email = email
        self.authType = authType
        self.authValue = authValue
    }
    
    public enum CodingKeys: CodingKey {
        case email
        case authType
        case authValue
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.email = try container.decode(String.self, forKey: .email)
        self.authType = try container.decode(AuthenticationType.self, forKey: .authType)
        self.authValue = try container.decode(String.self, forKey: .authValue)
    }
}

extension User {
    public enum AuthenticationType: String, Codable {
        case email
        case apple
        case google
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

// MARK: - Authentication
extension User: ModelAuthenticatable {
    public static let usernameKey = \User.$email
    public static let passwordHashKey = \User.$authValue

    public func verify(password: String) throws -> Bool {
        // only email authentication types have passwords
        guard authType == .email else { throw Abort(.internalServerError) }
        return try Bcrypt.verify(password, created: authValue)
    }
}

// MARK: - ModelCredentialsAuthenticatable
extension User: ModelCredentialsAuthenticatable {}

// MARK: - ModelSessionAuthenticatable
extension User: ModelSessionAuthenticatable {}

// MARK: - Helpers
extension User {
    public static func find(_ method: AuthenticationMethod, in db: Database) async throws -> User? {
        let authType = AuthenticationType(method)
        switch method {
        case .apple(_, let id), .google(_, let id):
            return try await User
                .query(on: db)
                .filter(\.$authType == authType)
                .filter(\.$authValue == id)
                .first()
        case .email(let address, _):
            return try await User
                .query(on: db)
                .filter(\.$authType == authType)
                .filter(\.$email == address)
                .first()
        }
    }
}
