import Fluent

extension EmailAuthentication {
    struct Migration: AsyncMigration {
        var name: String { "EmailAuthenticationCreate" }
        
        func prepare(on database: Database) async throws {
            try await database
                .schema(EmailAuthentication.schema)
                .id()
                .field("state", .string, .required)
                .unique(on: "state")
                .field("is_join", .bool, .required)
                .field("email", .string, .required)
                .field("password_hash", .string, .required)
                .field("expires_at", .datetime, .required)
                .field("sent_at", .datetime)
                .field("result", .string)
                .create()
        }
        
        func revert(on database: any Database) async throws {
            try await database
                .schema(EmailAuthentication.schema)
                .delete()
        }
    }
}
