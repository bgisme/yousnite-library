import Vapor
import Fluent

public protocol UserDelegate {
    func createUser(on: Database) async throws -> UUID
}
