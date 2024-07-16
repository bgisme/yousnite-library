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
    public static let oAuthPath = path(to: oAuthRoute, isAbsolute: true, isToApp: false)
    public static let oAuthDoneRoute: [PathComponent] = ["oauth-done"]
    
    public static let javascriptRoute: [PathComponent] = ["javascript"]
    public static var javascriptPath = path(to: javascriptRoute, isAbsolute: true, isToApp: false)
    
    public func boot(routes: any RoutesBuilder) throws {
        let userOptional = UserController.userOptional(routes)
        
        let google = userOptional.grouped(Self.routes)
        
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
        // triggered by join? ...don't create account if triggered by sign-in
        let isJoin = UserController.isJoin(req: req)
        let response: Response
        if let email = info.email {
            response = try await processUserInfo(isJoin: isJoin, 
                                                 email: email,
                                                 id: info.subject.value,
                                                 req: req)
        } else {
            req.session.setAuthenticationError(.service(.google))
            response = req.redirect(to: UserController.signInPath())
        }
        // clean up cookies
        UserController.deleteAuthenticationCookies(response)
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
        let isJoin = UserController.isJoin(req: req)
        return try await processUserInfo(isJoin: isJoin,
                                         email: info.email,
                                         id: info.id,
                                         req: req)
    }
    
    private func processUserInfo(isJoin: Bool,
                                 email: String,
                                 id: String,
                                 req: Request) async throws -> Response {
        let response: Response
        // use Google subject as user identifier, not email which can change
        let method = AuthenticationMethod.google(email: email, id: id)
        var other: AuthenticationType?
        if let existing = try? await UserController.user(method, other: &other, on: req.db) {
            try UserController.authenticate(existing, req: req)
            response = await ViewController.delegate.did(.signIn(req))
        } else if isJoin {
            if other == nil {
                let new = try await UserController.createUser(method, on: req.db)
                try UserController.authenticate(new, req: req)
                try await EmailController.sendEmail(.joined(.google), to: email, req: req)
                response = await ViewController.delegate.did(.join(req))
            } else {
                // user exists with email and other authentication type... possible with Google accounts
                req.session.setAuthenticationError(.otherRegistration(other!.method(email: email)))
                response = req.redirect(to: UserController.signInPath())
            }
        } else {
            req.session.setAuthenticationError(.notRegistered(.google))
            response = req.redirect(to: UserController.signInPath())
        }
        return response
    }
}

// MARK: - Sessions
extension GoogleController {
    static let cookieKey = "AUTH_GOOGLE"
}

public struct GoogleUserInfo: Content {
    let id: String
    let email: String
}
