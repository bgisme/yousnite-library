import Vapor
import Fluent

extension Credential: ModelAuthenticatable {
    public static let usernameKey = \Credential.$email
    public static let passwordHashKey = \Credential.$value

    public func verify(password: String) throws -> Bool {
        // only email authentication types have passwords
        guard type == .email else { throw Abort(.internalServerError) }
        return try Bcrypt.verify(password, created: value)
    }
}

extension Credential: ModelCredentialsAuthenticatable {}

extension Credential: ModelSessionAuthenticatable {}
