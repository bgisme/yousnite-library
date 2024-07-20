import Vapor
import Fluent
import JWT
import Utilities
import ImperialGoogle

public struct GoogleController: Sendable {
    public init() { }
    
    struct GoogleAuthResponse: Content {
        let credential: String
        let gState: String
        
        init(_ req: Request) throws {
            let cookies = req.cookies.all
            guard let bodyCSRFToken: String = req.content["g_csrf_token"],
                  let gCSRFToken = cookies["g_csrf_token"]?.string,
                  gCSRFToken == bodyCSRFToken,
                  let credential: String = req.content["credential"],
                  let gState = cookies["g_state"]?.string
            else {
                throw Abort(.unauthorized)
            }
            self.credential = credential
            self.gState = gState
        }
    }
}

// MARK: - Configure
extension GoogleController {
    static public private(set) var clientId = ""
    
    static func configure(app: Application,
                          routes: [PathComponent] = routes,
                          parentRouteCollection: NestedRouteCollection.Type?) throws {
        guard
            let clientId = Environment.get("GOOGLE_CLIENT_ID")/*,
            let clientSecret = Environment.get("GOOGLE_CLIENT_SECRET")*/
        else {
            throw Abort(.internalServerError)
        }
        self.clientId = clientId

        self.routes = routes
        self.parentRouteCollection = parentRouteCollection
    }
}

// MARK: - NestedRouteCollection
extension GoogleController: NestedRouteCollection {
    public private(set) static var parentRouteCollection: NestedRouteCollection.Type?
    public private(set) static var routes: [PathComponent] = ["google"]
}

// MARK: - RouteCollection
extension GoogleController: RouteCollection {
    private static let oAuthValue = "authenticate"
    public static let oAuthRoute: [PathComponent] = [.init(stringLiteral: oAuthValue)]
    public static let oAuthPath = path(to: oAuthRoute, isAbsolute: true, isAPI: false)
    public static let oAuthDoneRoute: [PathComponent] = ["oauth-done"]
    
    public static let javascriptRoute: [PathComponent] = ["javascript"]
    public static var javascriptPath = path(to: javascriptRoute, isAbsolute: true, isAPI: false)
    
    public func boot(routes: any RoutesBuilder) throws {
        let authOptional = MainController.authenticationOptional(routes)
        
        let google = authOptional.grouped(Self.routes)
        
        try google.oAuth(grouped: Self.path().components(separatedBy: "/").compactMap{ !$0.isEmpty ? .init(stringLiteral: $0) : nil },
                         from: Google.self,
                         authenticate: Self.oAuthValue,  // trigger oAuth process at path... users/google/authenticate
                         callback: "https://" + Environment.get("BASE_WEB_URI")! + Self.path() + "/oauth/google",
                         scope: ["profile", "email"],
                         redirect: Self.path(to: Self.oAuthDoneRoute))   // called with Google token
        
        google.post(Self.javascriptRoute, use: javascript)
        google.get(Self.oAuthDoneRoute, use: oAuthDone)
    }
    
    // called by Google when using javascript button
    func javascript(req: Request) async throws -> Response {
        // decode google response
        let auth = try GoogleController.GoogleAuthResponse(req)
        // compare state values and verify according to https://developers.google.com/identity/gsi/web/guides/verify-google-id-token
        guard let info = try? await req.jwt.google.verify(auth.credential),
              info.audience.value.first == GoogleController.clientId,
              info.issuer == "accounts.google.com" || info.issuer == "https://accounts.google.com",
              info.expires.value.timeIntervalSinceNow >= 0,
              let state = req.cookies[Self.cookieKey]?.string,
              state == info.nonce
        else {
            req.logger.warning("\(Self.cookieKey) does not exist or match")
            throw Abort(.unauthorized)
        }
        let response: Response
        if let email = info.email {
            response = try await MainController.signInOrCreateUser(.google(email: email, id: info.subject.value), req: req)
        } else {
            req.session.setCredentialError(.service(.google))
            response = req.redirect(to: ViewController.signInPath())
        }
        // clean up cookies
        response.deleteAuthenticationCookies()
        return response
    }
    
    func oAuthDone(req: Request) async throws -> Response {
        // query Google with access token for user info
        var headers = HTTPHeaders()
        headers.bearerAuthorization = try BearerAuthorization(token: req.accessToken())
        let googleAPIURL = "https://www.googleapis.com/oauth2/v1/userinfo?alt=json"
        /// https://www.googleapis.com/oauth2/v4/token
        let response = try await req
            .client
            .get(.init(stringLiteral: googleAPIURL), headers: headers)
        guard response.status == .ok else {
            throw Abort(.internalServerError)
        }
        let info = try response
            .content
            .decode(GoogleUserInfo.self)
        return try await MainController.signInOrCreateUser(.google(email: info.email, id: info.id), req: req)
    }
}

// MARK: - Sessions
extension GoogleController {
    static let cookieKey = "AUTHENTICATE_GOOGLE"
}

public struct GoogleUserInfo: Content {
    let id: String
    let email: String
}
