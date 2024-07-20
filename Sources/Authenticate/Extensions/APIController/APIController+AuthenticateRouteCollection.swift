import Vapor
import Utilities

extension APIController: NestedRouteCollection {
    public internal(set) static var parentRouteCollection: NestedRouteCollection.Type?
    public internal(set) static var routes: [PathComponent] = ["api"]
}

extension APIController: AuthenticateRouteCollection { }

