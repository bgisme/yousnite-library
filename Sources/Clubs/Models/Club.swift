import Vapor
import Fluent
import Utilities

final public class Club: Model, Content, @unchecked Sendable {
    public static let schema = Fields1.schema
    
    @ID(key: .id) public var id: UUID?
    @Field(key: Fields1.name) public var name: String
    @Field(key: Fields1.createdAt) public var createdAt: Date
    @OptionalField(key: Fields1.description) public var description: String?
    
    public init() { }
    
    public init(id: UUID? = nil,
                name: String,
                description: String? = nil) {
        self.id = id
        self.name = name
        self.createdAt = Date()
        self.description = description
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(description, forKey: .description)
    }
}

extension Club {
    enum CodingKeys: String, CodingKey {
        case name
        case createdAt = "created_at"
        case description
    }

    enum Fields1 {
        static let schema = "clubs"
        static let name = CodingKeys.name.fieldKey
        static let createdAt = CodingKeys.createdAt.fieldKey
        static let description = CodingKeys.description.fieldKey
    }
}
