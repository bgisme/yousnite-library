import Vapor
import Utilities

// MARK: - NestedRouteCollection
extension MainController: NestedRouteCollection {
    public internal(set) static var parentRouteCollection: NestedRouteCollection.Type?
    public internal(set) static var routes: [PathComponent] = ["users"]
}
