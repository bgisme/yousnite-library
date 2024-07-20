import Vapor
import Utilities

public struct Password: Content {
    public static var minPasswordLength = 11
    public static var isLetterRequired = true
    public static var isNumberRequired = true
    public static var isPunctuationRequired = true
    
    public static func random(length: Int = minPasswordLength) -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz01234567890~`!@#$%^&*()_-+={}[]:;<>,.?"
        return String((0..<30).map{ _ in chars.randomElement()! })
    }
    
    public static var passwordValidations: [((String) -> Bool, String)] {
        var v: [((String) -> Bool, String)] = [
            ({!$0.isEmpty}, "Enter a password."),
            ({$0.count >= minPasswordLength}, "Password must be \(minPasswordLength) or more characters."),
        ]
        if isLetterRequired {
            v += [({$0.rangeOfCharacter(from: .letters) != nil}, "Password must contain letters.")]
        }
        if isNumberRequired {
            v += [({$0.rangeOfCharacter(from: .decimalDigits) != nil}, "Password must contain numbers.")]
        }
        if isPunctuationRequired {
            v += [({$0.rangeOfCharacter(from: .punctuationCharacters) != nil}, "Password must contain punctuation.")]
        }
        return v
    }
    
    public static var requirements: String {
        let result = "Minimum \(minPasswordLength) characters."
        var optionals = [String]()
        if isLetterRequired {
            optionals += ["letter"]
        }
        if isNumberRequired {
            optionals += ["number"]
        }
        if isPunctuationRequired {
            optionals += ["punctuaction mark"]
        }
        var options = " At least one "
        switch optionals.count {
        case Int.min...0:
            options = ""
        case 1:
            options += optionals.first! + "."
        case 2...Int.max:
            options += optionals.joined(by: ", ") + "."
        default:
            // should never be reached
            options = ""
        }
        return result + options
    }
    
    public let value: String
    
    public enum CodingKeys: String, CodingKey, Codable {
        case password
        case confirm = "confirm-password"
    }

    public init(password: String,
                passwordValidations: [((String) -> Bool, String)] = Self.passwordValidations,
                confirmPassword: String) throws {
        var error = ValidateResults<CodingKeys>()
        self.value = password
            .trimmingCharacters(in: .whitespaces)
            .validate(&error, .password, passwordValidations)
        guard error.isEmpty else { throw error }
        guard password == confirmPassword else {
            throw ValidateResults<CodingKeys>(.confirm, "", "Passwords did not match.")
        }
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
