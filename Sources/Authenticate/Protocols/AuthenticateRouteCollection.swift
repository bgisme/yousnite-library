import Utilities
import Vapor

public protocol AuthenticateRouteCollection: NestedRouteCollection {
    static func joinPath(isAbsolute: Bool, isAPI: Bool) -> String
    static func passwordResetPath(isAbsolute: Bool, isAPI: Bool, state: String?) -> String
    static func passwordSetPath(isAbsolute: Bool, isAPI: Bool, state: String?) -> String
    static func signInPath(isAbsolute: Bool, isAPI: Bool) -> String
    static func signOutPath(isAbsolute: Bool, isAPI: Bool) -> String
    static func unjoinPath(isAbsolute: Bool, isAPI: Bool) -> String
}

extension AuthenticateRouteCollection {
    public static var joinRoute: [PathComponent] { ["join"] }
    public static var passwordResetRoute: [PathComponent] { ["password-reset"] }
    public static var passwordSetRoute: [PathComponent] { ["password-set"] }
    public static var signInRoute: [PathComponent] { ["signin"] }
    public static var signOutRoute: [PathComponent] { ["signout"] }
    public static var unjoinRoute: [PathComponent] { ["unjoin"] }
    
    public static func joinPath(isAbsolute: Bool = false, isAPI: Bool = false) -> String {
        path(to: joinRoute, isAbsolute: isAbsolute, isAPI: isAPI)
    }
    
    public static func passwordResetPath(isAbsolute: Bool = false, isAPI: Bool = false, state: String? = nil) -> String {
        path(to: passwordResetRoute, isAbsolute: isAbsolute, isAPI: isAPI, appending: urlEncoded(state))
    }
    
    public static func passwordSetPath(isAbsolute: Bool = false, isAPI: Bool = false, state: String? = nil) -> String {
        path(to: passwordSetRoute, isAbsolute: isAbsolute, isAPI: isAPI, appending: urlEncoded(state))
    }
    
    public static func signInPath(isAbsolute: Bool = false, isAPI: Bool = false) -> String {
        path(to: signInRoute, isAbsolute: isAbsolute, isAPI: isAPI)
    }
    
    public static func signOutPath(isAbsolute: Bool = false, isAPI: Bool = false) -> String {
        path(to: signOutRoute, isAbsolute: isAbsolute, isAPI: isAPI)
    }
    
    public static func unjoinPath(isAbsolute: Bool = false, isAPI: Bool = false) -> String {
        path(to: unjoinRoute, isAbsolute: isAbsolute, isAPI: isAPI)
    }
    
    private static func urlEncoded(_ state: String?) -> [String] {
        guard let state = state else { return [] }
        let urlEncoded = state.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? state
        return [urlEncoded]
    }
}
