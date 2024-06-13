import Vapor
import Fluent


extension User: ModelAuthenticatable {
    public static let usernameKey = \User.$email
    public static let passwordHashKey = \User.$value

    public func verify(password: String) throws -> Bool {
        // only email authentication types have passwords
        guard type == .email else { throw Abort(.internalServerError) }
        return try Bcrypt.verify(password, created: value)
    }
}

extension User: ModelCredentialsAuthenticatable {}

extension User: ModelSessionAuthenticatable {}
