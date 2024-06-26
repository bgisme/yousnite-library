import Vapor
import Fluent

public protocol ViewDelegate {
    static func displayJoin(state: String,
                            email: EmailJoinView,
                            apple: AppleView,
                            google: GoogleView) -> Response
    
    /// user authenticated
    static func joinDone(req: Request) async throws -> Response
    
    static func displaySignIn(state: String,
                              email: EmailSignInView,
                              apple: AppleView,
                              google: GoogleView) -> Response
    
    /// user authenticated
    static func signInDone(req: Request) async throws -> Response
    
    /// user unauthenticated
    static func signOutDone(req: Request) async throws -> Response
    
    static func displayPasswordReset(input: PasswordResetView) -> Response
    
    static func displayPasswordUpdate(input: PasswordUpdateView) -> Response
    
    static func passwordUpdateDone(req: Request) async throws -> Response
        
    static func sent(_ type: EmailType, email: String, req: Request) async throws -> Response
    
    static func fatalError(_ message: String, req: Request) async throws -> Response
}

public enum EmailType: String {
    case join
    case passwordReset
    case update
}
