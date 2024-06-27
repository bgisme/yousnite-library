import Vapor
//import AWSSESv2
import SotoSESv2

public struct AWSEmail {
    
    public typealias Find = String
    public typealias Replace = String
    
    public static let accessKey: String = Environment.get("AWS_ACCESS_KEY")!
    public static let secretAccessKey: String = Environment.get("AWS_SECRET_ACCESS_KEY")!
    
    public let body: SESv2.Body
    
    public static func email(from name: String,
                             instruction: String,
                             buttonTitle: String,
                             href: String,
                             disclaimer: String) throws -> AWSEmail {
        try .init("email_with_link.html",
                  replace: [
                    ("##CLUB_NAME##", name),
                    ("##BUTTON_INSTRUCTION##", instruction),
                    ("##BUTTON_TITLE##", buttonTitle),
                    ("##BUTTON_HREF##", href),
                    ("##DISCLAIMER##", disclaimer)
                  ])
    }
    
    public static func email(from name: String,
                             message: String,
                             disclaimer: String) throws -> AWSEmail {
        try .init("email_with_message.html",
                  replace: [
                    ("##CLUB_NAME##", name),
                    ("##MESSAGE##", message),
                    ("##DISCLAIMER##", disclaimer)
                  ])
    }
    
    public init(_ filename: String,
                in path: String = "./Resources/Email Templates/",
                replace replacements: [(Find, Replace)] = []) throws {
        let fileURL = URL(fileURLWithPath: path + filename)
        try self.init(fileURL, replace: replacements)
    }
    
    public init(_ fileURL: URL,
                replace replacements: [(Find, Replace)] = []) throws {
        var body = try String(contentsOf: fileURL, encoding: .utf8)
        for r in replacements {
            body = body.replacingOccurrences(of: r.0, with: r.1)
        }
        self.body = .init(html: .init(data: body))
    }
    
    public func send(to toAddress: String,
                     cc ccAddresses: [String] = [],
                     from fromAddress: String,
                     as name: String? = nil,
                     subject: String) async throws -> String? {
        try await self.send(to: [toAddress], 
                            cc: ccAddresses,
                            from: fromAddress,
                            as: name,
                            subject: subject)
    }
    
    public func send(to toAddresses: [String],
                     cc ccAddresses: [String] = [],
                     from fromAddress: String,
                     as fromName: String? = nil,
                     subject: String) async throws -> String? {
        var result: String?
        let client = AWSClient(credentialProvider: .static(accessKeyId: Self.accessKey, secretAccessKey: Self.secretAccessKey),
                               httpClientProvider: .createNew)
        let ses = SESv2(client: client, region: .useast1)
        let content = SESv2.EmailContent(simple: .init(body: body, subject: .init(data: subject)))
        let destination = SESv2.Destination(ccAddresses: ccAddresses, toAddresses: toAddresses)
        var fromEmailAddress = fromAddress
        if let fromName = fromName {
            // format: "name" <email.address>
            fromEmailAddress = "\"" + fromName + "\" <" + fromEmailAddress + ">"
        }
        let email = SESv2.SendEmailRequest(content: content,
                                           destination: destination,
                                           fromEmailAddress: fromEmailAddress)
        let response: SESv2.SendEmailResponse = try await ses.sendEmail(email)
        result = response.messageId
        try client.syncShutdown()
        return result
    }    
}
