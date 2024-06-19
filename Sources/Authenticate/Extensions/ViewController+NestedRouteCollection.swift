import Vapor
import NestRoute

extension ViewController: NestedRouteCollection {
    public static private(set) var route: [PathComponent] = ["auth"]    // affects path of Apple + Google redirect uri
    public static var nestedParent: NestedRouteCollection.Type?
    public static private(set) var nestedChildren: [NestedRouteCollection.Type] = []
}
