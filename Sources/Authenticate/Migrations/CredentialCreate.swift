import Vapor
import Fluent

extension Credential {
    public struct Migration: AsyncMigration {
        public var name: String { "CredentialCreate" }
        
        public init() { }

        public func prepare(on database: Database) async throws {
            try await database.schema(Credential.schema)
                .id()
                .field("email", .string, .required)
                .unique(on: "email")
                .field("type", .string, .required)
                .unique(on: "email", "type")
                .field("value", .string, .required)
                .field("joined_at", .datetime, .required)
                .field("unjoined_at", .datetime)
                .field("user_id", .uuid)
                .create()
        }

        public func revert(on database: Database) async throws {
            try await database.schema(Credential.schema).delete()
        }
    }
}
