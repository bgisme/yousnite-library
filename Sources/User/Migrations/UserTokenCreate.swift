import Fluent

extension UserToken {
    
    public struct Migration: AsyncMigration {
        public var name: String { "UserTokenCreate" }
        
        public init() { }
        
        public func prepare(on database: Database) async throws {
            try await database
                .schema(UserToken.schema)
                .id()
                .field("user_id", .uuid, .required, .references("users", "id"))
                .field("value", .string, .required)
                .unique(on: "value")
                .field("created_at", .datetime, .required)
                .field("expires_at", .datetime)
                .create()
        }
        
        public func revert(on database: Database) async throws {
            try await database
                .schema(UserToken.schema).delete()
        }
    }
}
