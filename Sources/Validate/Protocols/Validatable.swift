import Foundation

public protocol Validatable {
    associatedtype Value
    
    typealias Validation = (Test, ErrorMessage)
    typealias Test = (Value) -> Bool
    typealias ErrorMessage = String
    
    var stringValue: String? { get }
    
    func validate<Key: Codable & Hashable>(_ error: inout ValidateError<Key>,
                                           _ key: Key,
                                           _ validations: [Validation]) -> Value
}

extension Validatable where Self == Value {
    public func validate<Key: Codable & Hashable>(_ error: inout ValidateError<Key>,
                                                  _ key: Key,
                                                  _ validations: [Validation]) -> Value {
        for (test, message) in validations {
            if !test(self),
               let value = self.stringValue {
                error[key] = .init(value, message)
            }
        }
        return self
    }
}

extension Bool: Validatable {
    public typealias Value = Self
    
    public var stringValue: String? { self ? "true" : "false" }
}

extension String: Validatable {
    public typealias Value = Self
    
    public var stringValue: String? { self }
}

extension Double: Validatable {
    public typealias Value = Self
    
    public var stringValue: String? { self.formatted() }
}

extension Float: Validatable {
    public typealias Value = Self
    
    public var stringValue: String? { self.formatted() }
}

extension Int: Validatable {
    public typealias Value = Self
    
    public var stringValue: String? { self.formatted() }
}

extension Int8: Validatable {
    public typealias Value = Self
    
    public var stringValue: String? { self.formatted() }
}

extension Int16: Validatable {
    public typealias Value = Self
    
    public var stringValue: String? { self.formatted() }
}

extension Int32: Validatable {
    public typealias Value = Self
    
    public var stringValue: String? { self.formatted() }
}

extension Int64: Validatable {
    public typealias Value = Self
    
    public var stringValue: String? { self.formatted() }
}

extension UInt: Validatable {
    public typealias Value = Self
    
    public var stringValue: String? { self.formatted() }
}

extension UInt8: Validatable {
    public typealias Value = Self
    
    public var stringValue: String? { self.formatted() }
}

extension UInt16: Validatable {
    public typealias Value = Self
    
    public var stringValue: String? { self.formatted() }
}

extension UInt32: Validatable {
    public typealias Value = Self
    
    public var stringValue: String? { self.formatted() }
}

extension UInt64: Validatable {
    public typealias Value = Self
    
    public var stringValue: String? { self.formatted() }
}
