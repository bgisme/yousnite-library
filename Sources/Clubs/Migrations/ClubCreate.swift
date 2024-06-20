import Vapor
import Fluent

extension Club {
    
    public struct Migration: AsyncMigration {
        public var name: String { "ClubCreate" }
        
        public init() { }

        public func prepare(on database: Database) async throws {
            try await database.schema(Club.schema)
                .id()
                .field(Fields1.name, .string, .required)
                .field(Fields1.createdAt, .datetime, .required)
                .field(Fields1.description, .string)
                .create()
        }

        public func revert(on database: Database) async throws {
            try await database.schema(Club.schema).delete()
        }
    }
}
