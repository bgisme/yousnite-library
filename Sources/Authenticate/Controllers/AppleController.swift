import Vapor
import Fluent
import JWT
import Utilities

public struct AppleController: Sendable {
    public init() { }
}

// MARK: - Configure
extension AppleController {
//    private static private(set) var applicationId = ""
    public static private(set) var servicesId = ""
//    private static private(set) var teamId = ""
//    private static private(set) var jwkId = ""
//    private static private(set) var jwkKey = ""
    
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
    
    public static func configure(app: Application,
                                 routes: [PathComponent] = routes,
                                 parentRouteCollection: NestedRouteCollection.Type?) throws {
        guard
            //            let applicationId = Environment.get("APPLE_APP_ID"),
            let servicesId = Environment.get("SIWA_SERVICES_ID"),
            //            let teamId = Environment.get("APPLE_TEAM_ID"),
            let jwkId = Environment.get("APPLE_JWK_ID"),
            let jwkKey = Environment.get("APPLE_JWK_KEY")
        else {
            fatalError("AppleController missing environment values")
        }
        self.servicesId = servicesId
        /// JWT
        do {
            app.jwt.apple.applicationIdentifier = servicesId
            let signer = try JWTSigner.es256(key: .private(pem: jwkKey.addingCharacterReturnsAndLineFeeds()))
            app.jwt.signers.use(signer, kid: .init(string: jwkId), isDefault: false)
        } catch {
            print(jwkKey.utf8)
            fatalError(error.localizedDescription)
        }
        
        self.routes = routes
        self.parentRouteCollection = parentRouteCollection
    }
}

// MARK: - NestedRouteCollection
extension AppleController: NestedRouteCollection {
    public private(set) static var parentRouteCollection: NestedRouteCollection.Type?
    public private(set) static var routes: [PathComponent] = ["apple"]
}

// MARK: - RouteCollection
extension AppleController: RouteCollection {
    public static let redirectRoute: [PathComponent] = ["redirect"]
    public static var redirectPath = path(to: redirectRoute, isAbsolute: true)

    public func boot(routes: any RoutesBuilder) throws {
        let apple = routes.grouped(Self.routes)
        
        let authOptional = MainController.authenticationOptional(apple)
        
        authOptional.post(Self.redirectRoute, use: appleRedirect)
    }
    
    // called by Apple
    func appleRedirect(req: Request) async throws -> Response {
        let response: Response
        let authResponse = try AppleController.authResponse(req: req)
        let token = try await AppleController.idToken(authResponse: authResponse, req: req)
        guard
            let cookieState = req.cookies[Self.cookieKey]?.string,
            !cookieState.isEmpty,
            cookieState == authResponse.state
        else {
            throw Abort(.unauthorized)
        }
        if let email = token.email {
            let method = CredentialMethod.apple(email: email, id: token.subject.value)
            response = try await MainController.signInOrCreateUser(method, req: req)
        } else {
            req.session.setCredentialError(.service(.apple))
            response = req.redirect(to: ViewController.signInPath())
        }
        // clean up cookies
        response.deleteAuthenticationCookies()
        return response
    }
}

// MARK: - Sessions
extension AppleController {
    static let cookieKey = "AUTHENTICATE_APPLE"
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
