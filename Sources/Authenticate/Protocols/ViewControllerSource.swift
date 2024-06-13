import Vapor
import Fluent

public enum EmailType: String {
    case join
    case passwordReset
    case update
}

public protocol ViewControllerSource {
    static func displayJoin(state: String,
                            email: ViewControllerSourceEmailJoinDisplay,
                            apple: ViewControllerSourceAppleDisplay,
                            google: ViewControllerSourceGoogleDisplay) -> Response
    
    /// user authenticated
    static func joinDone(req: Request) async throws -> Response
    
    static func displaySignIn(state: String,
                              email: ViewControllerSourceEmailSignInDisplay,
                              apple: ViewControllerSourceAppleDisplay,
                              google: ViewControllerSourceGoogleDisplay) -> Response
    
    /// user authenticated
    static func signInDone(req: Request) async throws -> Response
    
    /// user unauthenticated
    static func signOutDone(req: Request) async throws -> Response
    
    static func displayPasswordReset(input: ViewControllerSourcePasswordResetDisplay) -> Response
    
    static func displayPasswordUpdate(input: ViewControllerSourcePasswordUpdateDisplay) -> Response
    
    static func passwordUpdateDone(req: Request) async throws -> Response
    
    static func sent(_ type: EmailType, email: String, req: Request) async throws -> Response
    
    static func fatalError(_ message: String, req: Request) async throws -> Response
}

public protocol ViewControllerSourceEmailJoinDisplay {
    var email: String? { get }
    var postTo: String { get }
    var signInPath: String { get }
    var error: String? { get }
}

public protocol ViewControllerSourceEmailSignInDisplay {
    var email: String? { get }
    var postTo: String { get }
    var joinPath: String { get }
    var passwordResetPath: String { get }
    var error: String? { get }
}

public protocol ViewControllerSourcePasswordResetDisplay {
    var postTo: String { get }
    var joinPath: String { get }
    var signInPath: String { get }
    var email: String? { get }
    var error: String? { get }
}

public protocol ViewControllerSourcePasswordUpdateDisplay {
    var email: String { get }
    var isNewUser: Bool { get }
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

public protocol ViewControllerSourceAppleDisplay {
    var servicesId: String { get }
    var scopes: AppleScopeOptions { get }
    var redirectUri: String { get }
    var error: String? { get }
}

public protocol ViewControllerSourceGoogleDisplay {
    var clientId: String { get }
    var redirectUri: String { get }
    var error: String? { get }
}
