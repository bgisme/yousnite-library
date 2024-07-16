import Vapor
import Fluent

public enum EventType {
    case will(_ type: PreEventType)
    case did(_ type: PostEventType)
}

public enum PreEventType {
    case join(state: String, email: EmailJoinView, apple: AppleView, google: GoogleView)
    case resetPassword(input: PasswordResetView)
    case setPassword(input: PasswordSetView)
    case signIn(state: String, email: EmailSignInView, apple: AppleView, google: GoogleView)
}

public enum PostEventType {
    case email(_ type: EmailType, to: String, error: String?, req: Request)
    case join(_ req: Request)
    case setPassword(_ req: Request)
    case signIn(_ req: Request)
    case signOut(_ req: Request)
    case unjoin(_ req: Request)
}

public enum EmailType: String {
    case join
    case passwordReset
    case passwordSet
}

public protocol ViewDelegate {
    func will(_ type: PreEventType) async -> Response
    
    func did(_ type: PostEventType) async -> Response
    
//    #warning("TODO: combine two joins")
//    func join(state: String,
//              email: EmailJoinView,
//              apple: AppleView,
//              google: GoogleView) -> Response
//    
//    /// user authenticated
//    func joinDone(req: Request) async -> Response
//    
//    #warning("TODO: combine sign ins")
//    func signIn(state: String,
//                email: EmailSignInView,
//                apple: AppleView,
//                google: GoogleView) -> Response
//    
//    /// user authenticated
//    func signInDone(req: Request) async -> Response
//    
//    /// user unauthenticated
//    func signOutDone(error: String?, req: Request) async -> Response
//    
//    #warning("TODO: combine joinDone() + passwordChange() + passwordChangeDone() with isNewUser")
//    func passwordChange(_ kind: PasswordChangeKind) -> Response
//    
//    func passwordChangeDone(req: Request) async -> Response
//    
//    func sent(_ type: EmailType, email: String, req: Request) async -> Response
//    
//    #warning("TODO: willDeleteUser(req: Request)")
//    func userDeleted(req: Request) async -> Response
//    
//    #warning("TODO: Eliminate this...")
//    func fatalError(_ message: String, req: Request) async -> Response
}

//public enum PasswordChangeKind {
//    case reset(input: PasswordResetView)
//    case set(input: PasswordSetView)
//}
