import Vapor

public enum AddressKind: String, Codable {
    case apple
    case email
    case google
}

public protocol EmailDelegate {
    func emailInvite(link: String,
                     toAddress: String,
                     req: Request) async throws -> String?
    
    func emailJoined(toAddress: String,
                     kind: AddressKind,
                     req: Request) async throws -> String?
    
    func emailPasswordReset(link: String,
                            toAddress: String,
                            req: Request) async throws -> String?
    
    func emailPasswordUpdated(toAddress: String,
                              req: Request) async throws -> String?
}
