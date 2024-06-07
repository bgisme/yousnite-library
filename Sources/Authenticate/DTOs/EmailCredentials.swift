import Vapor
import Validate

/// use for email join, sign in, password reset and update
public struct EmailCredentials: Content {
    public static var emailValidations: [((String) -> Bool, String)] = [
        ({!$0.isEmpty}, "Enter an email"),
        ({!Validator.email.validate($0).isFailure}, "Invalid email address."),
    ]
    
    static let minPasswordLength = 11
    
    public static let passwordValidations: [((String) -> Bool, String)] = [
        ({!$0.isEmpty}, "Enter a password."),
        ({$0.count >= minPasswordLength}, "Enter \(Self.minPasswordLength) or more characters."),
        ({$0.rangeOfCharacter(from: .letters) != nil}, "Must contain letters."),
        ({$0.rangeOfCharacter(from: .decimalDigits) != nil}, "Must contain numbers."),
        ({$0.rangeOfCharacter(from: .punctuationCharacters) != nil}, "Must contain punctuation."),
    ]

    public let email: String
    public let password: String
    public let isApp: Bool
    
    public enum CodingKeys: String, CodingKey, Codable {
        case email
        case password
        case confirmPassword
        case isApp
    }
    
    public init(email: String,
                emailValidations: [((String) -> Bool, String)] = Self.emailValidations,
                password: String,
                passwordValidations: [((String) -> Bool, String)] = Self.passwordValidations,
                isApp: Bool = false) throws {
        var error = ValidateError<CodingKeys>()
        self.email = email
            .trimmingCharacters(in: .whitespaces)
            .validate(&error, .email, emailValidations)
        self.password = password
            .trimmingCharacters(in: .whitespaces)
            .validate(&error, .password, passwordValidations)
        self.isApp = isApp
        guard error.isEmpty else { throw error }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let email = try container.decode(String.self, forKey: .email)
        let password = try container.decode(String.self, forKey: .password)
        let isApp = try container.decodeIfPresent(Bool.self, forKey: .isApp) ?? false
        // when used for join and update... include confirm for extra validation
        if let confirmPassword = try container.decodeIfPresent(String.self, forKey: .confirmPassword) {
            guard password == confirmPassword else {
                throw ValidateError<CodingKeys>(.confirmPassword, "", "Does not match password.")
            }
        }
        try self.init(email: email, password: password, isApp: isApp)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(email, forKey: .email)
        try container.encode(password, forKey: .password)
        try container.encode(isApp, forKey: .isApp)
    }
}
