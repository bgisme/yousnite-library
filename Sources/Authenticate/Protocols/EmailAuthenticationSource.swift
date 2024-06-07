import Vapor
import Fluent

public protocol EmailAuthenticationSource {
    static func passwordHash(_ password: String) throws -> String
    static func update(passwordHash: String, user: any Authenticatable, db: Database) async throws
    static func updateAuthenticatedUser(password: String, req: Request) async throws -> String
}
