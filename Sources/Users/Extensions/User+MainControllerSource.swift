import Vapor
import Fluent

// MARK: - MainDelegate
extension UserController: MainDelegate {
    public func createUser(_ method: AuthenticationMethod, on db: Database) async throws -> any UserIdentifiable {
        let user = try User(method)
        try await user.save(on: db)
        return user
    }
    
    public func user(_ method: AuthenticationMethod, on db: Database) async throws -> (any UserIdentifiable)? {
        try await User.find(method, in: db)
    }
    
    public func authenticatedUser(req: Request) throws -> (any UserIdentifiable)? {
        req.auth.get(User.self)
    }
    
    public func authenticate(_ user: any UserIdentifiable, req: Request) throws {
        req.auth.login(user)
    }
    
    public func unauthenticate(isSessionEnd: Bool, req: Request) {
        req.auth.logout(User.self)
        if isSessionEnd { req.session.destroy() }
    }
    
    public func delete(_ user: any UserIdentifiable, req: Request) async throws {
        try await user.delete(on: req.db)
    }
}
