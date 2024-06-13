import Vapor
import Fluent

extension User {
    
    public struct Migration: AsyncMigration {
        public var name: String { "UserCreate" }
        
        public init() { }

        public func prepare(on database: Database) async throws {
            try await database.schema(User.schema)
                .id()
                .field("email", .string, .required)
                .field("type", .string, .required)
                .field("value", .string, .required)
                .create()
        }

        public func revert(on database: Database) async throws {
            try await database.schema(User.schema).delete()
        }
    }
}
