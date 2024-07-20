import Vapor
import Fluent
import Utilities

public struct ViewController: Sendable {
    public init() { }
}

// MARK: - Configure
extension ViewController {
    static private(set) var delegate: ViewDelegate!
    
    public static func configure(app: Application,
                                 routes: [PathComponent] = routes,
                                 parentRouteCollection: NestedRouteCollection.Type?,
                                 delegate: some ViewDelegate) throws {
        self.routes = routes
        self.parentRouteCollection = parentRouteCollection
        self.delegate = delegate
    }
}
