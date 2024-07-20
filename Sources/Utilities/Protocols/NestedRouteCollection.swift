import Vapor

public protocol NestedRouteCollection: RouteCollection {
    static var parentRouteCollection: NestedRouteCollection.Type? { get }
    static var routes: [PathComponent] { get }
    
    // must make class or struct init public
    init()
}

extension NestedRouteCollection {
    public typealias Key = String
    public typealias Value = String
    
    public static func path(to childRoutes: [PathComponent] = [],
                            isAbsolute: Bool = false,
                            isAPI: Bool = false,
                            appending: [String] = [],
                            parameters: [(Key, Value)] = []) -> String {
        var parentRoutes = [PathComponent]()
        var p = parentRouteCollection
        while p != nil {
            parentRoutes = p!.routes + parentRoutes
            p = p!.parentRouteCollection
        }
        var path = String()
        if isAbsolute {
            if isAPI {
                path = Environment.get("BASE_APP_URI") ?? "UNKNOWN_BASE_APP_URI"
            } else if let envURI = Environment.get("BASE_WEB_URI") {
                path = "https://" + envURI + "/"
            } else {
                path = "localhost://"
            }
        } else {
            path = "/"
        }
        path += (parentRoutes + routes + childRoutes)
            .map{$0.description}
            .joined(separator: "/")
        if !appending.isEmpty {
            path += "/" + appending.joined(separator: "/")
        }
        if !parameters.isEmpty {
            path += "?" + parameters.map{$0.0 + "=" + $0.1}.joined(separator: "&")
        }
        return path
    }
}
