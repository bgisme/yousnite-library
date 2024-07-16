import Vapor

public enum EmailPurpose {
    case invite(link: URL, toAddress: String)
    case joined(toAddress: String, type: AuthenticationType)
    case passwordReset(link: URL, toAddress: String)
    case passwordUpdated(toAddress: String)
    case quit(toAddress: String, type: AuthenticationType)
}

public protocol EmailDelegate {
    func email(_ purpose: EmailPurpose, req: Request) async throws
}
