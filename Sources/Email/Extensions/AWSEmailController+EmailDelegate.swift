import Vapor
import Users

extension AWSEmailController: Users.EmailDelegate {
    private(set) static var fromAddress = "noreply@yousnite.com"
    private(set) static var name = "Yousnite"
    
    public static func configure(fromAddress: String,
                                 as name: String) throws {
        self.fromAddress = fromAddress
        self.name = name
    }
    
    public func email(_ purpose: EmailPurpose, req: Request) async throws {
        let subject: String
        let body: String
        let toAddress: String
        switch purpose {
        case .invite(let link, let address):
            subject = "Invitation to Join"
            body = try text(fileName: "email_with_link.html",
                                replacing: [
                                    ("##CLUB_NAME##", Self.name),
                                    ("##BUTTON_INSTRUCTION##", "Click to finish the process."),
                                    ("##BUTTON_TITLE##", "Register"),
                                    ("##BUTTON_HREF##", link.absoluteString),
                                    ("##DISCLAIMER##", "Ignore if not requested."),
                                ])
            toAddress = address
        case .joined(let address, let type):
            subject = "Welcome!"
            let message: String
            switch type {
            case .apple:
                message = "Your Apple ID was used to join."
            case .email:
                message = "The email address \(address) was used to join."
            case .google:
                message = "Your Google Account with email \(address) was used to join."
            }
            body = try text(fileName: "email_with_message.html",
                                replacing: [
                                    ("##CLUB_NAME##", Self.name),
                                    ("##MESSAGE##", message),
                                    ("##DISCLAIMER##", "Contact us immediately if not requested."),
                                ])
            toAddress = address
        case .passwordReset(let link, let address):
            subject = "Password Reset"
            body = try text(fileName: "email_with_link.html",
                                replacing: [
                                    ("##CLUB_NAME##", Self.name),
                                    ("##BUTTON_INSTRUCTION##", "Click to reset password for \(address)."),
                                    ("##BUTTON_TITLE##", "Reset"),
                                    ("##BUTTON_HREF##", link.absoluteString),
                                    ("##DISCLAIMER##", "Ignore if not requested. Nothing has changed with your account."),
                                ])
            toAddress = address
        case .passwordUpdated(let address):
            subject = "Password Updated"
            body = try text(fileName: "email_with_message.html",
                                replacing: [
                                    ("##CLUB_NAME##", Self.name),
                                    ("##MESSAGE##", "Your password for \(address) has been updated."),
                                    ("##DISCLAIMER##", "Contact us immediately if not requested."),
                                ])
            toAddress = address
        case .quit(let address, let type):
            let message: String
            switch type {
            case .apple:
                message = "Membership for your Apple ID has been canceled."
            case .email:
                message = "Membership for your email address \(address) has been canceled."
            case .google:
                message = "Membership for your Google Account with email \(address) has been canceled."
            }
            subject = "Sorry to see you go... ☹️"
            body = try text(fileName: "email_with_message.html",
                                replacing: [
                                    ("##CLUB_NAME##", "Pack 1 New Rochelle"),
                                    ("##MESSAGE##", message),
                                    ("##DISCLAIMER##", "Contact us immediately if not requested."),
                                ])
            toAddress = address
        }
        _ = try await send(subject: subject, body: body, to: toAddress)
    }
    
    private func text(fileName: String,
                      replacing replacements: [(String, String)] = []) throws -> String {
        let fileURL = URL(fileURLWithPath: "./Resources/Email Templates/" + fileName)
        var body = try String(contentsOf: fileURL, encoding: .utf8)
        for r in replacements {
            body = body.replacingOccurrences(of: r.0, with: r.1)
        }
        return body
    }
    
    private func send(subject: String,
                      body: String,
                      to toAddress: String) async throws -> String {
        try await AWSEmailController.send(subject: subject,
                                          body: body,
                                          isBodyHTML: true,
                                          to: [toAddress],
                                          from: Self.fromAddress,
                                          as: Self.name) ?? "email sent"
    }
}
