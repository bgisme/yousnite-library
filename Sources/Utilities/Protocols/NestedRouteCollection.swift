import Vapor

public protocol NestedRouteCollection: RouteCollection {
    static var route: [PathComponent] { get }
    static var nestedParent: NestedRouteCollection.Type? { get set }
    static var nestedChildren: [NestedRouteCollection.Type] { get }
    
    // must make class or struct init public
    init()
}

extension NestedRouteCollection {
    public func boot(routes: any RoutesBuilder,
                     in parent: NestedRouteCollection) throws {
        Self.nestedParent = type(of: parent)
        try boot(routes: routes)
        let childRoutes = routes.grouped(Self.route)
        for child in Self.nestedChildren {
            try child.init().boot(routes: childRoutes, in: self)
        }
    }
    
    public static func path(isRelative: Bool = true, appending components: [PathComponent]? = nil) -> String {
        (isRelative ? "/" : "") + (parentComponents(isRelative: isRelative) + (components ?? [])).map{$0.description}.joined(separator: "/")
    }
    
    public static func parentComponents(isRelative: Bool) -> [PathComponent] {
        var components = route
        var parent = nestedParent
        while parent != nil {
            components = parent!.route + components
            parent = parent?.nestedParent
        }
        if !isRelative && parent == nil {
            let baseUri = Environment.get("BASE_URI") ?? "localhost://"
            components = [.init(stringLiteral: baseUri)] + components
        }
        return components
    }
}

extension RoutesBuilder {
    public func register(nestedCollection: NestedRouteCollection,
                         in parent: NestedRouteCollection) throws {
        try nestedCollection.boot(routes: self, in: parent)
    }
}
