import Vapor
import Validate

public struct Password: Content {
    public static let minPasswordLength = 11
    
    public static func random(length: Int = minPasswordLength) -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz01234567890~`!@#$%^&*()_-+={}[]:;<>,.?"
        return String((0..<30).map{ _ in chars.randomElement()! })
    }
    
    public static let passwordValidations: [((String) -> Bool, String)] = [
        ({!$0.isEmpty}, "Enter a password."),
        ({$0.count >= minPasswordLength}, "Enter \(Self.minPasswordLength) or more characters."),
        ({$0.rangeOfCharacter(from: .letters) != nil}, "Must contain letters."),
        ({$0.rangeOfCharacter(from: .decimalDigits) != nil}, "Must contain numbers."),
        ({$0.rangeOfCharacter(from: .punctuationCharacters) != nil}, "Must contain punctuation."),
    ]
    
    public let value: String
    
    public enum CodingKeys: String, CodingKey, Codable {
        case password
        case confirm = "confirm-password"
    }

    public init(password: String,
                passwordValidations: [((String) -> Bool, String)] = Self.passwordValidations,
                confirmPassword: String) throws {
        var error = ValidateError<CodingKeys>()
        self.value = password
            .trimmingCharacters(in: .whitespaces)
            .validate(&error, .password, passwordValidations)
        guard password == confirmPassword else {
            throw ValidateError<CodingKeys>(.confirm, "", "Does not match password.")
        }
        guard error.isEmpty else { throw error }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let password = try container.decode(String.self, forKey: .password)
        let confirm = try container.decodeIfPresent(String.self, forKey: .confirm) ?? password
        try self.init(password: password, confirmPassword: confirm)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .password)
        try container.encode(value, forKey: .confirm)
    }
}
