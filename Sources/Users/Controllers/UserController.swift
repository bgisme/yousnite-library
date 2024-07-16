import Vapor
import Fluent
import Utilities
//import ImperialGoogle

public struct UserController { 
    public init() {}
}

// MARK: - Configure
extension UserController {
    public static func configure(app: Application,
                                 routes: [PathComponent] = routes,
                                 parentRouteCollection: NestedRouteCollection.Type? = nil,
                                 emailDelegate: some EmailDelegate,
                                 viewDelegate: some ViewDelegate) throws {
        self.routes = routes
        self.parentRouteCollection = parentRouteCollection
        
        // Migrations
        app.migrations.add(User.Migration())
        app.migrations.add(UserToken.Migration())
        
        // configure children
        try APIController.configure(app: app, parentRouteCollection: self)
        try AppleController.configure(app: app, parentRouteCollection: self)
        try GoogleController.configure(app: app, parentRouteCollection: self)
        try EmailController.configure(app: app, delegate: emailDelegate)
        try ViewController.configure(app: app,
                                     parentRouteCollection: self,
                                     delegate: viewDelegate)
    }
}

// MARK: - NestedRouteCollection
extension UserController: NestedRouteCollection {
    public private(set) static var parentRouteCollection: NestedRouteCollection.Type?
    public private(set) static var routes: [PathComponent] = ["users"]
}

// MARK: - RouteCollection
extension UserController: RouteCollection {
    typealias AppRoutes = [PathComponent]
    typealias WebRoutes = [PathComponent]
    private static func path(either: (AppRoutes, WebRoutes),
                             isAbsolute: Bool,
                             isToApp: Bool,
                             urlEncodedToken token: String? = nil) -> String {
        path(to: isToApp ? either.0 : either.1,
             isAbsolute: isAbsolute,
             isToApp: isToApp,
             appending: token != nil ? [token!] : [])
    }
    
    public static func joinPath(isAbsolute: Bool = false,
                                isToApp: Bool = false,
                                urlEncodedToken: String? = nil) -> String {
        path(either: (APIController.joinRoute, ViewController.joinRoute),
             isAbsolute: isAbsolute,
             isToApp: isToApp,
             urlEncodedToken: urlEncodedToken)
    }
    
    public static func passwordResetPath(isAbsolute: Bool = false,
                                         isToApp: Bool = false,
                                         urlEncodedToken: String? = nil) -> String {
        path(either: (APIController.passwordResetRoute, ViewController.passwordResetRoute),
             isAbsolute: isAbsolute,
             isToApp: isToApp,
             urlEncodedToken: urlEncodedToken)
    }
    
    public static func passwordSetPath(isAbsolute: Bool = false,
                                       isToApp: Bool = false,
                                       urlEncodedToken: String? = nil) -> String {
        path(either: (APIController.passwordSetRoute, ViewController.passwordSetRoute),
             isAbsolute: isAbsolute,
             isToApp: isToApp,
             urlEncodedToken: urlEncodedToken)
    }
    
    public static func signInPath(isAbsolute: Bool = false,
                                  isToApp: Bool = false) -> String {
        path(either: (APIController.signInRoute, ViewController.signInRoute),
             isAbsolute: isAbsolute,
             isToApp: isToApp)
    }
    
    public static func signOutPath(isAbsolute: Bool = false,
                                   isToApp: Bool = false) -> String {
        path(either: (APIController.signOutRoute, ViewController.signOutRoute),
             isAbsolute: isAbsolute,
             isToApp: isToApp)
    }
    
    public static func unjoinPath(isAbsolute: Bool = false,
                                  isToApp: Bool = false) -> String {
        path(either: (APIController.unjoinRoute, ViewController.unjoinRoute),
             isAbsolute: isAbsolute,
             isToApp: isToApp)
    }

    public static func userOptional(_ routes: RoutesBuilder) -> RoutesBuilder {
        routes.grouped([
            User.credentialsAuthenticator(),    // authenticate user via username + password... continues after fail
            User.sessionAuthenticator(),        // authenticate user via session... continues after fail
        ])
    }
    
    public static func userRequired(_ routes: RoutesBuilder,
                                    noUser: @escaping (Request) -> Void) -> RoutesBuilder {
        routes.grouped([
            User.redirectMiddleware { req -> String in
                if !req.auth.has(User.self) {
                    noUser(req)
                }
                return req.url.string
            },
        ])
    }

    public func boot(routes: RoutesBuilder) throws {
        let userOptional = routes.grouped([
            User.credentialsAuthenticator(),    // authenticate user via username + password... continues after fail
            User.sessionAuthenticator(),        // authenticate user via session... continues after fail
        ])
        let users = userOptional.grouped(Self.routes)
        
        try users.register(collection: APIController())
        try users.register(collection: ViewController())
        try users.register(collection: AppleController())
        try users.register(collection: GoogleController())
    }
    
    public func index(req: Request) async throws -> [User] {
        try await User.query(on: req.db).all()
    }
    public func delete(req: Request) async throws -> HTTPStatus {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await user.delete(on: req.db)
        return .noContent
    }
}
