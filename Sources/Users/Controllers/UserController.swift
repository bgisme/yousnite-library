import Vapor
import Fluent

public struct UserController { 
    public init() {}
}

// MARK: - Configure
extension UserController {
    public static func configure(app: Application) throws {
        // Migrations
        app.migrations.add(User.Migration())
        app.migrations.add(UserToken.Migration())
    }
}

// MARK: - RouteCollection
extension UserController: RouteCollection {
    public func boot(routes: RoutesBuilder) throws {
        routes.get(use: index)
//        routes.post(use: create)
        routes.group(":userID") { user in
            user.delete(use: delete)
        }
    }
}

// MARK: - Handlers
extension UserController {
    public func index(req: Request) async throws -> [User] {
        try await User.query(on: req.db).all()
    }
    
//    public func create(req: Request) async throws -> User {
//        let u = try req.content.decode(User.self)
//        let user: User
//        switch u.authType {
//        case .apple:
//            user = try User(email: u.email, appleID: u.authValue)
//        case .email:
//            // User encodes password as hashed
//            user = try User(email: u.email, passwordHash: u.authValue)
//        case .google:
//            user = try User(email: u.email, googleID: u.authValue)
//        }
//        try await user.save(on: req.db)
//        return user
//    }

    public func delete(req: Request) async throws -> HTTPStatus {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await user.delete(on: req.db)
        return .noContent
    }
}
