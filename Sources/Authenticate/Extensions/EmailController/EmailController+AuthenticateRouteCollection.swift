import Vapor
import Utilities

extension EmailController: AuthenticateRouteCollection { }

extension EmailController: NestedRouteCollection {
    public internal(set) static var parentRouteCollection: NestedRouteCollection.Type?
    public internal(set) static var routes: [PathComponent] = ["email"]
}
