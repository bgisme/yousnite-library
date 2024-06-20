import Vapor

extension Array where Element == PathComponent {
    public func path(nextPath: String? = nil) -> String {
        var result = "/" + map{ $0.description }.joined(separator: "/")
        if let nextPath = nextPath { result += "?nextPath=" + nextPath }
        return result
    }
    
    public func path(appending routes: [PathComponent]) -> String {
        routes.isEmpty ? self.path() : self.path() + routes.path()
    }
    
    public func path(appending paths: [String]) -> String {
        paths.isEmpty ? self.path() : self.path() + "/" + paths.joined(separator: "/")
    }
}
