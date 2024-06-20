import Vapor
import Utilities

/// use for email join, sign in, password reset and update
public struct Email: Content {
    public static var emailValidations: [((String) -> Bool, String)] = [
        ({!$0.isEmpty}, "Enter an email"),
        ({!Validator.email.validate($0).isFailure}, "Invalid email address."),
    ]
    
    public let address: String
    
    public enum CodingKeys: String, CodingKey, Codable {
        case email
    }
    
    public init(_ address: String,
                emailValidations: [((String) -> Bool, String)] = Self.emailValidations) throws {
        var error = ValidateError<CodingKeys>()
        self.address = address
            .trimmingCharacters(in: .whitespaces)
            .validate(&error, .email, emailValidations)
        guard error.isEmpty else { throw error }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let address = try container.decode(String.self, forKey: .email)
        try self.init(address)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(address, forKey: .email)
    }
}
