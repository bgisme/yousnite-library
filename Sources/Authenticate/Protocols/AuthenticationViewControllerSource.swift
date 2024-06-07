import Vapor
import Fluent

public enum EmailType: String {
    case join
    case passwordReset
    case update
}

public protocol AuthenticationViewControllerSource {
    /// path to redirect after join or sign-in
    static func nextPath(req: Request) -> String?
    
    /// path to redirect after sign in... if next path == nil
    static var defaultSignInPath: String { get }
    
    /// path to redirect after sign out... if next path == nil
    static var defaultSignOutPath: String? { get }
        
    static func join(state: String,
                     email: AuthenticationViewControllerSourceEmailJoinDisplay,
                     apple: AuthenticationViewControllerSourceAppleDisplay,
                     google: AuthenticationViewControllerSourceGoogleDisplay) -> Response
        
    /// user is authenticated when called
    static func joinComplete(req: Request) async throws -> Response
    
    static func signIn(state: String,
                       email: AuthenticationViewControllerSourceEmailSignInDisplay,
                       apple: AuthenticationViewControllerSourceAppleDisplay,
                       google: AuthenticationViewControllerSourceGoogleDisplay) -> Response
    
    static func passwordReset(input: AuthenticationViewControllerSourcePasswordResetDisplay) -> Response
    
    static func passwordUpdate(input: AuthenticationViewControllerSourcePasswordUpdateDisplay) -> Response
    
    static func sent(_ type: EmailType, email: String, req: Request) async throws -> Response
}

public protocol AuthenticationViewControllerSourceEmailJoinDisplay {
    var email: String? { get }
    var postTo: String { get }
    var signInPath: String { get }
    var error: String? { get }
}

public protocol AuthenticationViewControllerSourceEmailSignInDisplay {
    var email: String? { get }
    var postTo: String { get }
    var joinPath: String { get }
    var passwordResetPath: String { get }
    var error: String? { get }
}

public protocol AuthenticationViewControllerSourcePasswordResetDisplay {
    var postTo: String { get }
    var joinPath: String { get }
    var signInPath: String { get }
    var email: String? { get }
    var error: String? { get }
}

public protocol AuthenticationViewControllerSourcePasswordUpdateDisplay {
    var postTo: String { get }
    var error: String? { get }
}

public struct AppleScopeOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let email = AppleScopeOptions(rawValue: 1 << 0)
    public static let name  = AppleScopeOptions(rawValue: 1 << 1)
    public static let all: AppleScopeOptions = [.email, .name]
}

public protocol AuthenticationViewControllerSourceAppleDisplay {
    var servicesId: String { get }
    var scopes: AppleScopeOptions { get }
    var redirectUri: String { get }
    var error: String? { get }
}

public protocol AuthenticationViewControllerSourceGoogleDisplay {
    var clientId: String { get }
    var redirectUri: String { get }
    var error: String? { get }
}
