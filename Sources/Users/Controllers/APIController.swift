import Vapor
import Fluent
import JWTKit
import Utilities

public struct APIController: Sendable {
    public init() { }
}

// MARK: - Configure
extension APIController {    
    public static func configure(app: Application,
                                 routes: [PathComponent] = routes,
                                 parentRouteCollection: NestedRouteCollection.Type? = nil) throws {
        self.routes = routes
        self.parentRouteCollection = parentRouteCollection
    }
}

// MARK: - NestedRouteCollection
extension APIController: NestedRouteCollection {
    public private(set) static var parentRouteCollection: NestedRouteCollection.Type?
    public private(set) static var routes: [PathComponent] = ["api"]
}

// MARK: - RouteCollection
extension APIController: RouteCollection {
    public static let joinRoute: [PathComponent] = ["join"]
    public static let passwordResetRoute: [PathComponent] = ["password-reset"]
    public static let passwordUpdateRoute: [PathComponent] = ["password-update"]
    public static let passwordSetRoute: [PathComponent] = ["password-set"]
    public static let signInRoute: [PathComponent] = ["signin"]
    public static let signOutRoute: [PathComponent] = ["signout"]
    public static let unjoinRoute: [PathComponent] = ["unjoin"]
    
    public static let passwordTokenKey = "token"
        
    public func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped(Self.routes)
        api.get(Self.signOutRoute, use: signOut)
    }
    
    func signOut(req: Request) async throws -> HTTPStatus {
        UserController.unauthenticate(isSessionEnd: true, req: req)
        return .ok
    }
}
