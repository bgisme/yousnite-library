import Vapor
import Utilities

extension ViewController: NestedRouteCollection {
    public internal(set) static var parentRouteCollection: NestedRouteCollection.Type?
    public internal(set) static var routes: [PathComponent] = []
}

extension ViewController: AuthenticateRouteCollection { }
