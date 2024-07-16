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
                .unique(on: "email")
                .field("type", .string, .required)
                .unique(on: "email", "type")
                .field("value", .string, .required)
                .field("joined_at", .datetime, .required)
                .field("unjoined_at", .datetime)
                .create()
        }

        public func revert(on database: Database) async throws {
            try await database.schema(User.schema).delete()
        }
    }
}
