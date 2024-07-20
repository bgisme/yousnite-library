import Fluent

extension EmailToken {
    struct Migration: AsyncMigration {
        var name: String { "EmailTokenCreate" }
        
        func prepare(on database: Database) async throws {
            try await database
                .schema(EmailToken.schema)
                .id()
                .field("state", .string, .required)
                .unique(on: "state")
                .field("email", .string, .required)
                .field("expires_at", .datetime, .required)
                .field("sent_at", .datetime)
                .create()
        }
        
        func revert(on database: any Database) async throws {
            try await database
                .schema(EmailToken.schema)
                .delete()
        }
    }
}
