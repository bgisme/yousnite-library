import Vapor
import Fluent
import Authenticate

// MARK: - MainDelegate
extension User: MainDelegate {
    public static func createUser(_ method: AuthenticationMethod, on db: Database) async throws -> any UserAuthenticatable {
        let user = try User(method)
        try await user.save(on: db)
        return user
    }
    
    public static func user(_ method: AuthenticationMethod, on db: Database) async throws -> (any UserAuthenticatable)? {
        try await User.find(method, in: db)
    }
    
    public static func authenticatedUser(req: Request) throws -> (any UserAuthenticatable)? {
        req.auth.get(User.self)
    }
    
    public static func authenticate(_ user: any UserAuthenticatable, req: Request) throws {
        req.auth.login(user)
    }
    
    public static func unauthenticate(isSessionEnd: Bool, req: Request) {
        req.auth.logout(User.self)
        if isSessionEnd { req.session.destroy() }
    }
}
