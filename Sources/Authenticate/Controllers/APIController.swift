import Vapor
import Fluent
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

// MARK: - Sessions
extension APIController {
    static let cookieKey = "AUTHENTICATE_API"
}
