import Vapor

public protocol EmailDelegate {
    func emailInvite(link: String,
                     toAddress: String,
//                     from: String,
//                     as: String,
                     req: Request) async throws -> String?
    
    func emailPasswordReset(link: String,
                            toAddress: String,
//                            from: String,
//                            as: String,
                            req: Request) async throws -> String?
    
    func emailPasswordUpdated(toAddress: String,
//                              from: String,
//                              as: String,
                              req: Request) async throws -> String?
}
