import Vapor
import Fluent
import Authenticate

// MARK: - AuthenticationControllerSource
extension User: AuthenticationControllerSource {
    public static func createUser(_ method: AuthenticationMethod, db: Database) async throws -> any Authenticatable {
        let user: User
        switch method {
        case .apple(let email, let appleID):
            user = try .init(email: email, appleID: appleID)
        case .email(let email, let passwordHash):
            user = try .init(email: email, passwordHash: passwordHash)
        case .google(let email, let googleID):
            user = try .init(email: email, googleID: googleID)
        }
        try await user.save(on: db)
        return user
    }
    
    public static func user(_ method: AuthenticationMethod, db: Database) async throws -> (any Authenticatable)? {
        try await User.find(method, in: db)
    }
    
    public static func verify(_ password: String, 
                              for user: any Authenticatable,
                              db: Database) throws -> Bool {
        guard let user = user as? User else {
            throw Abort(.internalServerError)
        }
        return try user.verify(password: password)
    }
    
    public static func isSignedIn(req: Request) -> Bool {
        req.auth.has(User.self)
    }
    
    public static func authenticate(_ user: any Authenticatable, req: Request) {
        req.auth.login(user)
    }
    
    public static func unauthenticate(isSessionEnd: Bool, req: Request) {
        req.auth.logout(User.self)
        if isSessionEnd { req.session.destroy() }
    }
}
