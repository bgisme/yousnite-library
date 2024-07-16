import Fluent

extension PasswordToken {
    struct Migration: AsyncMigration {
        var name: String { "PasswordTokenCreate" }
        
        func prepare(on database: Database) async throws {
            try await database
                .schema(PasswordToken.schema)
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
                .schema(PasswordToken.schema)
                .delete()
        }
    }
}
