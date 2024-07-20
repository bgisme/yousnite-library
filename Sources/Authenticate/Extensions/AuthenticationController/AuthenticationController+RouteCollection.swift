import Vapor

// MARK: - RouteCollection
extension MainController: RouteCollection {
//    typealias AppRoutes = [PathComponent]
//    typealias WebRoutes = [PathComponent]
    
//    private static func path(to components: [PathComponent],
//                             isAbsolute: Bool,
//                             isAPI: Bool,
//                             urlEncodedToken token: String? = nil) -> String {
//        if isAPI {
//            return APIController.path(to: components, isAbsolute: isAbsolute, appending: token != nil ? [token!] : [])
//        } else {
//            return ViewController.path(to: components, isAbsolute: isAbsolute, appending: token != nil ? [token!] : [])
//        }
//    }
    
//    public static func joinPath(isAbsolute: Bool = false,
//                                isAPI: Bool = false,
//                                urlEncodedToken: String? = nil) -> String {
//        path(to: MainController.joinRoute,
//             isAbsolute: isAbsolute,
//             isAPI: isAPI,
//             urlEncodedToken: urlEncodedToken)
//    }
    
//    public static func passwordResetPath(isAbsolute: Bool = false,
//                                         isAPI: Bool = false,
//                                         urlEncodedToken: String? = nil) -> String {
//        path(to: MainController.passwordResetRoute,
//             isAbsolute: isAbsolute,
//             isAPI: isAPI,
//             urlEncodedToken: urlEncodedToken)
//    }
    
//    public static func passwordSetPath(isAbsolute: Bool = false,
//                                       isAPI: Bool = false,
//                                       urlEncodedToken: String? = nil) -> String {
//        path(to: MainController.passwordSetRoute,
//             isAbsolute: isAbsolute,
//             isAPI: isAPI,
//             urlEncodedToken: urlEncodedToken)
//    }
    
//    public static func signInPath(isAbsolute: Bool = false,
//                                  isAPI: Bool = false) -> String {
//        path(to: MainController.signInRoute,
//             isAbsolute: isAbsolute,
//             isAPI: isAPI)
//    }
    
//    public static func signOutPath(isAbsolute: Bool = false,
//                                   isAPI: Bool = false) -> String {
//        path(to: MainController.signOutRoute,
//             isAbsolute: isAbsolute,
//             isAPI: isAPI)
//    }
    
//    public static func unjoinPath(isAbsolute: Bool = false,
//                                  isAPI: Bool = false) -> String {
//        path(to: MainController.unjoinRoute,
//             isAbsolute: isAbsolute,
//             isAPI: isAPI)
//    }

    public static func authenticationOptional(_ routes: RoutesBuilder) -> RoutesBuilder {
        routes.grouped([
            Credential.credentialsAuthenticator(),    // authenticate user via username + password... continues after fail
            Credential.sessionAuthenticator(),        // authenticate user via session... continues after fail
        ])
    }
    
    public static func authenticationRedirected(_ routes: RoutesBuilder,
                                                noUser: @escaping (Request) -> Void) -> RoutesBuilder {
        routes.grouped([
            Credential.redirectMiddleware { req -> String in
                if !req.isAuthenticated {
                    noUser(req)
                }
                return req.url.string
            },
        ])
    }
    
    public static func authenticationRequired(_ routes: RoutesBuilder) -> RoutesBuilder {
        routes.grouped([
            Credential.authenticator(),           // via username + password... continues after fail
    //        UserToken.authenticator(),      // via token... continues after fail
            Credential.guardMiddleware()          // fails if no user
        ])
    }

    public func boot(routes: RoutesBuilder) throws {
        let userOptional = routes.grouped([
            Credential.credentialsAuthenticator(),    // authenticate user via username + password... continues after fail
            Credential.sessionAuthenticator(),        // authenticate user via session... continues after fail
        ])
        let users = userOptional.grouped(Self.routes)
        
        try users.register(collection: APIController())
        try users.register(collection: ViewController())
        try users.register(collection: AppleController())
        try users.register(collection: EmailController())
        try users.register(collection: GoogleController())
    }
    
    func index(req: Request) async throws -> [Credential] {
        try await Credential.query(on: req.db).all()
    }
    public func delete(req: Request) async throws -> HTTPStatus {
        guard let credential = try await Credential.find(req.parameters.get("authID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await credential.delete(on: req.db)
        return .noContent
    }
}
