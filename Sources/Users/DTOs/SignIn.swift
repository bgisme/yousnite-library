import Vapor
import Utilities

public struct SignIn: Content {
    public let email: String
    public let password: String
    
    public static var emailValidations: [((String) -> Bool, String)] = [
        ({!$0.isEmpty}, "Enter an email.")
    ]
    
    public static var passwordValidations: [((String) -> Bool, String)] = [
        ({!$0.isEmpty}, "Enter a password.")
    ]
    
    public enum CodingKeys: String, CodingKey, Codable {
        case email
        case password
    }
    
    public init(email: String, password: String) throws {
        var error = ValidateResults<CodingKeys>()
        self.email = email
            .trimmingCharacters(in: .whitespaces)
            .validate(&error, .email, Self.emailValidations)
        self.password = password
            .trimmingCharacters(in: .whitespaces)
            .validate(&error, .password, Self.passwordValidations)
        guard error.isEmpty else { throw error }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let email = try container.decode(String.self, forKey: .email)
        let password = try container.decode(String.self, forKey: .password)
        try self.init(email: email, password: password)
    }
    
//    public enum CodingKeys: String, CodingKey, Codable {
//        case email
//        case password
//    }
//    
//    public init(email: Email, password: Password) {
//        self.email = email
//        self.password = password
//    }
//    
//    public init(from decoder: any Decoder) throws {
//        // gather validation results
//        var errors = ValidateResults<CodingKeys>()
//        do {
//            let email = try Email(from: decoder).address
//            // save email even if no validation error
//            // available to re-fill form input
//            errors[.email] = .init(email)
//        } catch let error as ValidateResults<Email.CodingKeys> {
//            if let vm = error[.email] {
//                errors[.email] = vm
//            }
//        }
//        do {
//            let password = try Password(from: decoder)
//        } catch let error as ValidateResults<Password.CodingKeys> {
//            if let vm = error[.password] {
//                // save password message... not value
//                errors[.password] = .init(nil, vm.message)
//            }
//        }
//        guard errors.isEmpty else { throw errors }
//        // no errors... decode for init
//        self.email = try Email(from: decoder)
//        self.password = try Password(from: decoder)
//    }
}
