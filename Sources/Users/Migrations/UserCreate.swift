import Vapor
import Fluent

extension User {
    public struct Migration: AsyncMigration {
        public var name: String { "UserCreate" }
        
        public init() { }
        
        public func prepare(on database: Database) async throws {
            try await database.schema(User.schema)
                .id()
                .create()
        }
        
        public func revert(on database: Database) async throws {
            try await database.schema(User.schema).delete()
        }
    }
}
