import Vapor
import Fluent
import Authenticate

extension User: EmailAuthenticationSource {    
    public static func update(passwordHash: String, user: any Authenticatable, db: Database) async throws {
        guard let user = user as? User else {
            throw Abort(.internalServerError)   // programming error
        }
        user.setPasswordHash(passwordHash)
        try await user.save(on: db)
    }
    
    public static func updateAuthenticatedUser(password: String, req: Request) async throws -> String {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.internalServerError)   // programming error
        }
        try user.setPassword(password)
        try await user.save(on: req.db)
        return user.email
    }
}
