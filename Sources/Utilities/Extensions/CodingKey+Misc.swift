import Fluent

extension CodingKey {
    
    public var fieldKey: FieldKey { .init(stringLiteral: self.stringValue) }
}
