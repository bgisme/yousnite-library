import Vapor

public protocol NotificationDelegate {
    func email(_ purpose: EmailPurpose, req: Request) async throws
}

public enum EmailPurpose {
    case invite(link: String, toAddress: String)
    case joined(toAddress: String, type: CredentialType)
    case passwordReset(link: String, toAddress: String)
    case passwordUpdated(toAddress: String)
    case quit(toAddress: String, type: CredentialType)
}
