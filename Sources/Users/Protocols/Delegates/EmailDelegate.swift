import Vapor

public protocol EmailDelegate {
    typealias Result = String
    
    static func emailInvite(link: String, to: String, from: String) async throws -> Result?
    static func emailPasswordReset(link: String, to: String, from: String) async throws -> Result?
    static func emailPasswordUpdated(to: String, from: String) async throws -> Result?
}