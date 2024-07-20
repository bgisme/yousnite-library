import Vapor
import Fluent

final public class User: Model, Content, @unchecked Sendable {
    public static let schema = "users"
    
    @ID(key: .id) public var id: UUID?
    
    public init() { }
    
    public init(id: UUID? = nil) throws {
        self.id = id
    }
}
