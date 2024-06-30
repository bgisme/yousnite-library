import Vapor

public enum EmailPurpose {
    case invite(link: String, toAddress: String)
    case joined(toAddress: String, type: AuthenticationType)
    case passwordReset(link: String, toAddress: String)
    case passwordUpdated(toAddress: String)
    case quit(toAddress: String, type: AuthenticationType)
}

public protocol EmailDelegate {
    func email(_ purpose: EmailPurpose, req: Request) async throws -> String?
    
//    func emailInvite(link: String,
//                     toAddress: String,
//                     req: Request) async throws -> String?
//    
//    func emailJoined(toAddress: String,
//                     kind: AuthenticationKind,
//                     req: Request) async throws -> String?
//    
//    func emailPasswordReset(link: String,
//                            toAddress: String,
//                            req: Request) async throws -> String?
//    
//    func emailPasswordUpdated(toAddress: String,
//                              req: Request) async throws -> String?
//    
//    func emailQuit(toAddress: String,
//                   kind: AuthenticationKind,
//                   req: Request) async throws -> String?
}
