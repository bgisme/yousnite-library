import Vapor
import Fluent

public protocol ViewDelegate {
    func join(state: String,
              email: EmailJoinView,
              apple: AppleView,
              google: GoogleView) -> Response
    
    /// user authenticated
    func joinDone(req: Request) async throws -> Response
    
    func signIn(state: String,
                email: EmailSignInView,
                apple: AppleView,
                google: GoogleView) -> Response
    
    /// user authenticated
    func signInDone(req: Request) async throws -> Response
    
    /// user unauthenticated
    func signOutDone(req: Request) async throws -> Response
    
    func passwordChange(_ kind: PasswordChangeKind) -> Response
    
    func passwordUpdateDone(req: Request) async throws -> Response
    
    func sent(_ type: EmailType, email: String, req: Request) async throws -> Response
    
    func fatalError(_ message: String, req: Request) async throws -> Response
}

public enum PasswordChangeKind {
    case reset(input: PasswordResetView)
    case resetInvalid(error: String)
    case update(input: PasswordUpdateView, isNewUser: Bool)
    case updateInvalid(error: String, isNewUser: Bool)
}

public enum EmailType: String {
    case join
    case passwordReset
    case update
}
