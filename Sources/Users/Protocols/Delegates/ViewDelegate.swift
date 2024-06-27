import Vapor
import Fluent

public protocol ViewDelegate {
    func displayJoin(state: String,
                     email: EmailJoinView,
                     apple: AppleView,
                     google: GoogleView) -> Response
    
    /// user authenticated
    func joinDone(req: Request) async throws -> Response
    
    func displaySignIn(state: String,
                       email: EmailSignInView,
                       apple: AppleView,
                       google: GoogleView) -> Response
    
    /// user authenticated
    func signInDone(req: Request) async throws -> Response
    
    /// user unauthenticated
    func signOutDone(req: Request) async throws -> Response
    
    func displayPasswordReset(input: PasswordResetView) -> Response
    
    func displayPasswordUpdate(input: PasswordUpdateView) -> Response
    
    func passwordUpdateDone(req: Request) async throws -> Response
    
    func sent(_ type: EmailType, email: String, req: Request) async throws -> Response
    
    func fatalError(_ message: String, req: Request) async throws -> Response
}

public enum EmailType: String {
    case join
    case passwordReset
    case update
}
