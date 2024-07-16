import Foundation
import Utilities

public struct ZipCode: Codable {
    public let value: String
    
    public static let valueValidations: [((String) -> Bool, String)] = [
        ({!$0.isEmpty}, "Enter 5-digit number."),
        ({$0.count == 5 || $0.count == 9}, "Enter 5 or 9 digit number."),
    ]
    
    public enum CodingKeys: String, CodingKey, Codable {
        case value = "zipcode"
    }
    
    public init(_ value: String) throws {
        var error = ValidateResults<CodingKeys>()
        self.value = value
            .unicodeScalars
            .filter{CharacterSet.decimalDigits.contains($0)}
            .stringValue
            .validate(&error, .value, Self.valueValidations)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let value = try container.decode(String.self, forKey: .value)
        try self.init(value)
    }
}
