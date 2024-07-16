import Vapor
import SotoSESv2

public struct AWSEmailController: Sendable {
    public init() { }
    
    public typealias Find = String
    public typealias Replace = String
    
    public static let accessKey: String = Environment.get("AWS_ACCESS_KEY")!
    public static let secretAccessKey: String = Environment.get("AWS_SECRET_ACCESS_KEY")!
    
    public static func send(subject: String,
                            body: String,
                            isBodyHTML: Bool,
                            to toAddresses: [String],
                            cc ccAddresses: [String] = [],
                            from fromAddress: String,
                            as fromName: String? = nil) async throws -> String? {
        let bodyContent = SESv2.Content(data: body)
        let body: SESv2.Body = isBodyHTML ? .init(html: bodyContent) : .init(text: bodyContent)
        let subject = SESv2.Content(data: subject)
        let message = SESv2.Message(body: body, subject: subject)
        let content = SESv2.EmailContent(simple: message)
        var result: String?
        let client = AWSClient(credentialProvider: .static(accessKeyId: Self.accessKey, secretAccessKey: Self.secretAccessKey),
                               httpClientProvider: .createNew)
        let ses = SESv2(client: client, region: .useast1)
        let destination = SESv2.Destination(ccAddresses: ccAddresses,
                                            toAddresses: toAddresses)
        var fromEmailAddress = fromAddress
        if let fromName = fromName {
            // format: "name" <email.address>
            fromEmailAddress = "\"" + fromName + "\" <" + fromEmailAddress + ">"
        }
        let request = SESv2.SendEmailRequest(content: content,
                                           destination: destination,
                                           fromEmailAddress: fromEmailAddress)
        do {
            let response = try await ses.sendEmail(request)
            result = response.messageId
        } catch {
            result = error.localizedDescription
        }
        try client.syncShutdown()
        return result
    }
}
