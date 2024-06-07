public protocol EmailService {
    associatedtype Result
    static func sendEmail(address: String, body: String) async throws -> Result?
}
