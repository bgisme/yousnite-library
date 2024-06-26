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
//            let fromEmailAddress = "\"\(sender ?? "Yousnite.com")\" <noreply@yousnite.com>"
        }
        let email = SESv2.SendEmailRequest(content: content,
                                           destination: destination,
                                           fromEmailAddress: fromEmailAddress)
        do {
            let response: SESv2.SendEmailResponse = try await ses.sendEmail(email)
            result = response.messageId
        } catch let e as SESv2ErrorType {
            print(e.description)
        }
        try client.syncShutdown()
        return result
        
//        let region = "us-east-1"
//        let client = try SESv2Client(region: region)
//        let body = SESv2ClientTypes.Body(html: .init(charset: "UTF-8",
//                                                     data: self.content))
//        let message = SESv2ClientTypes.Message(body: body,
//                                               subject: .init(charset: "UTF-8", data: subject))
//        // email addresses must be already validated by AWS
//        let destination = SESv2ClientTypes.Destination(ccAddresses: ccAddresses,
//                                                       toAddresses: toAddresses)
//        let emailTag = SESv2ClientTypes.MessageTag(name: "tag-name", value: "tag-value")
//        let fromEmailAddress = "\"\(sender ?? "Yousnite.com")\" <noreply@yousnite.com>"
//        let input = SendEmailInput(configurationSetName: "yousnite-noreply-configuration-set",
//                                   content: .init(simple: message),
//                                   destination: destination,
//                                   emailTags: [emailTag],
//                                   feedbackForwardingEmailAddress: "feedback@yousnite.com",
//                                   feedbackForwardingEmailAddressIdentityArn: "arn:aws:ses:us-east-1:173199359945:identity/feedback@yousnite.com",
//                                   fromEmailAddress: fromEmailAddress,
//                                   fromEmailAddressIdentityArn: "arn:aws:ses:us-east-1:173199359945:identity/noreply@yousnite.com",
//                                   listManagementOptions: nil,
//                                   replyToAddresses: [fromEmailAddress])
//        do {
//            let output = try await client.sendEmail(input: input)
//            return output.messageId
//        } catch let error as AccountSuspendedException {
//            /// The message can't be sent because the account's ability to send email has been permanently restricted.
//            throw Exception.init("Account Suspended", error.message)
//        } catch let error as BadRequestException {
//            /// The input you provided is invalid.
//            throw Exception.init("Bad Request", error.message)
//        } catch let error as LimitExceededException {
//            /// There are too many instances of the specified resource type.
//            throw Exception.init("Limit Exceeded", error.message)
//        } catch let error as MailFromDomainNotVerifiedException {
//            /// The message can't be sent because the sending domain isn't verified.
//            throw Exception.init("Mail From Domain Not Verified", error.message)
//        } catch let error as MessageRejected {
//            /// The message can't be sent because it contains invalid content.
//            throw Exception.init("Message Rejected", error.message)
//        } catch let error as NotFoundException {
//            /// The resource you attempted to access doesn't exist.
//            throw Exception.init("Not Found", error.message)
//        } catch let error as SendingPausedException {
//            /// The message can't be sent because the account's ability to send email is currently paused.
//            throw Exception.init("Sending Paused", error.message)
//        } catch let error as TooManyRequestsException {
//            throw Exception.init("Too Many Requests", error.message)
//        }
//        return nil
    }
    
    public struct Exception: Error, LocalizedError {
        public let exception: String
        public let message: String?
        
        public init(_ exception: String, _ message: String?) {
            self.exception = exception
            self.message = message
        }
        
        public var errorDescription: String? {
            "\(exception)\(message != nil ? ": \(message!)" : "")"
        }
    }
}
