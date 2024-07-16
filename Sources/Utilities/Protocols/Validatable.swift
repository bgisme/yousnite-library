import Foundation

public protocol Validatable {
    associatedtype Value
    
    typealias Validation = (Test, ErrorMessage)
    typealias Test = (Value) -> Bool
    typealias ErrorMessage = String
    
    var description: String { get }
    
    func validate<Key: Codable & Hashable>(_ errors: inout ValidateResults<Key>,
                                           _ key: Key,
                                           _ validations: [Validation]) -> Value
}

extension Validatable where Self == Value {
    public func validate<Key: Codable & Hashable>(_ errors: inout ValidateResults<Key>,
                                                  _ key: Key,
                                                  _ validations: [Validation]) -> Value {
        // always save the value
        errors[key] = .init(self.description)
        for (test, message) in validations {
            if !test(self) {
                // overwrite with error message
                errors[key] = .init(self.description, message)
                break
            }
        }
        return self
    }
}

extension Bool: Validatable {
    public typealias Value = Self
}

extension String: Validatable {
    public typealias Value = Self
}

extension Double: Validatable {
    public typealias Value = Self
}

extension Float: Validatable {
    public typealias Value = Self
}

extension Int: Validatable {
    public typealias Value = Self
}

extension Int8: Validatable {
    public typealias Value = Self
}

extension Int16: Validatable {
    public typealias Value = Self
}

extension Int32: Validatable {
    public typealias Value = Self
}

extension Int64: Validatable {
    public typealias Value = Self
}

extension UInt: Validatable {
    public typealias Value = Self
}

extension UInt8: Validatable {
    public typealias Value = Self
}

extension UInt16: Validatable {
    public typealias Value = Self
}

extension UInt32: Validatable {
    public typealias Value = Self
}

extension UInt64: Validatable {
    public typealias Value = Self
}
