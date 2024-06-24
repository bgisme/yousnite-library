import Vapor
import Fluent
import JWT

public struct AppleController: Sendable { 
    public init() { }
}

// MARK: - Configure
extension AppleController {
    public static private(set) var applicationId = ""
    public static private(set) var servicesId = ""
    public static private(set) var teamId = ""
    public static private(set) var jwkId = ""
    public static private(set) var jwkKey = ""
    
    public static func authResponse(req: Request) throws -> AuthResponse {
        try req.content.decode(AppleController.AuthResponse.self)
    }
    
    public static func idToken(authResponse: AuthResponse, req: Request) async throws -> AppleIdentityToken {
        let token = try await req.jwt.apple
            .verify(authResponse.idToken, applicationIdentifier: AppleController.servicesId)
            .get()
        guard token.issuer == "https://appleid.apple.com" else { throw Exception.notIssuedByApple }
        return token
    }
    
    public static func configure() throws {
        guard
            let applicationId = Environment.get("APPLE_APP_ID"),
            let servicesId = Environment.get("SIWA_SERVICES_ID"),
            let teamId = Environment.get("APPLE_TEAM_ID"),
            let jwkId = Environment.get("APPLE_JWK_ID"),
            let jwkKey = Environment.get("APPLE_JWK_KEY")
        else {
            throw Abort(.internalServerError)
        }
        self.applicationId = applicationId
        self.servicesId = servicesId
        self.teamId = teamId
        self.jwkId = jwkId
        self.jwkKey = jwkKey.addingCharacterReturnsAndLineFeeds()
    }
}

// MARK: - RouteCollection
extension AppleController: RouteCollection {
    public func boot(routes: any RoutesBuilder) throws {
        #warning("TODO: make API routes")
    }
}

// MARK: - Decoding
extension AppleController {
    public struct AuthResponse: Decodable {
        public struct User: Decodable {
            public struct Name: Decodable {
                public let firstName: String
                public let lastName: String
            }
            public let email: String?
            public let name: Name?
        }
        
        public let code: String
        public let idToken: String
        public let state: String
        public let user: User

        public enum CodingKeys: String, CodingKey {
            case code
            case idToken = "id_token"
            case state
            case user
        }
    }
}

// MARK: - Errors
extension AppleController {
    public enum Exception: Error {
        case notIssuedByApple
    }
}

extension AppleController.Exception: AbortError {
    public var status: HTTPResponseStatus {
        switch self {
        case .notIssuedByApple: return .unauthorized
        }
    }
    
    public var reason: String {
        switch self {
        case .notIssuedByApple: return "Apple did not send this request."
        }
    }
}
