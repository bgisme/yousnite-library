import Vapor
import Fluent
import Authenticate

extension UsersController: UserDelegate {
    public func createUser(on db: Database) async throws -> UUID {
        let user = User()
        try await user.save(on: db)
        return try user.requireID()
    }
    
    public func deleteUser(id: UUID, on db: Database) async throws {
        guard let user = try await User.find(id, on: db) else {
            throw Abort(.notFound)
        }
        try await user.delete(on: db)
    }
}
