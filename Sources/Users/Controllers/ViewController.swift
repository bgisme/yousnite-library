import Vapor
import Fluent
import Utilities

public struct ViewController: Sendable {
    public init() { }
}

// MARK: - Configure
extension ViewController {
    static private(set) var delegate: ViewDelegate!
    
    public static func configure(app: Application,
                                 routes: [PathComponent] = routes,
                                 parentRouteCollection: NestedRouteCollection.Type?,
                                 delegate: some ViewDelegate) throws {
        self.routes = routes
        self.parentRouteCollection = parentRouteCollection
        self.delegate = delegate
    }
}

// MARK: - NestedRouteCollection
extension ViewController: NestedRouteCollection {
    public private(set) static var parentRouteCollection: NestedRouteCollection.Type?
    public private(set) static var routes: [PathComponent] = []
}

// MARK: - RouteCollection
extension ViewController: RouteCollection {
    public static let joinRoute: [PathComponent] = APIController.joinRoute
    public static let passwordResetRoute: [PathComponent] = APIController.passwordResetRoute
    public static let passwordSetRoute: [PathComponent] = APIController.passwordSetRoute
    public static let signInRoute: [PathComponent] = APIController.signInRoute
    public static let signOutRoute: [PathComponent] = APIController.signOutRoute
    public static let unjoinRoute: [PathComponent] = APIController.unjoinRoute
    
    public func boot(routes: RoutesBuilder) throws {
        routes.get(Self.joinRoute, use: displayJoin) // <form> for email address
        routes.post(Self.joinRoute, use: postJoin)   // emails link with password-token
        
        routes.get(Self.passwordResetRoute, use: displayPasswordReset) // <form> for email address
        routes.post(Self.passwordResetRoute, use: postPasswordReset) // emails link with password-token
                
        // called by join and reset email links with password-token
        routes.get(Self.passwordSetRoute + [":\(APIController.passwordTokenKey)"], use: displayPasswordSet)
        // authenticated user changing password
        routes.get(Self.passwordSetRoute, use: displayPasswordSet)
        
        // called for join, reset
        routes.post(Self.passwordSetRoute + [":\(APIController.passwordTokenKey)"], use: postPasswordSet)
        // called for update
        routes.post(Self.passwordSetRoute, use: postPasswordSet)

        routes.get(Self.signInRoute, use: displaySignIn)
        routes.post(Self.signInRoute, use: postEmailSignIn)
        
        routes.get(Self.signOutRoute, use: signOut)
        
        routes.get(Self.unjoinRoute, use: unjoin)
    }
    
    // <form> for email address
    func displayJoin(req: Request) async throws -> Response {
        // check if authenticated
        let user = try? UserController.authenticatedUser(req: req)
        guard user == nil else {
            return await Self.delegate.did(.join(req))
        }
        // errors from previous submit
        let e = req.session.joinSignInError(isDeleted: true)
        // display info
        let (apple, google) = Self.appleGoogleView(appleError: e?.apple,
                                                   googleError: e?.google)
        let email = Self.emailJoinView(email: e?.address, error: e?.error)
        // get response from delegate
        let token = EmailController.token()
        let response = await Self.delegate.will(.join(state: token, email: email, apple: apple, google: google))
        UserController.setAuthenticationCookies(token: token, isJoin: true, response: response)
        return response
    }
    
    // emails link with password-token
    func postJoin(req: Request) async throws -> Response {
        let response: Response
        do {
            let address = try req.content.decode(Email.self).address
            try await UserController.sendPasswordCreateResetLink(to: address,
                                                                 isNewUser: true,
                                                                 req: req)
#warning("TODO: Figure out best way to display email error")
            response = await Self.delegate.did(.email(.join, to: address, error: nil, req: req))
        } catch {
            req.session.set(error)
            response = req.redirect(to: UserController.joinPath())
        }
        // clean up cookies
        UserController.deleteAuthenticationCookies(response)
        return response
    }
    
    // <form> for email address
    func displayPasswordReset(req: Request) async throws -> Response {
        let e = req.session.passwordResetError(isDeleted: true)
        let input = Self.passwordResetView(email: e?.email, error: e?.message)
        return await Self.delegate.will(.resetPassword(input: input))
    }
    
    // emails link with password-token
    func postPasswordReset(req: Request) async throws -> Response {
        do {
            let address = try req.content.decode(Email.self).address
            try await UserController.sendPasswordCreateResetLink(to: address,
                                                                 isNewUser: false,
                                                                 req: req)
#warning("TODO: Figure out best way to display email error")
            return await Self.delegate.did(.email(.passwordReset, to: address, error: nil, req: req))
        } catch {
            req.session.set(error)
            return req.redirect(to: UserController.passwordResetPath())
        }
    }
    
    // called by join and reset email links with password-token... and authenticated user changing password without password-token
    func displayPasswordSet(req: Request) async throws -> Response {
        var isNewUser = false
        var token: String?
        var postTo: String?
        var e = req.session.passwordSetError(isDeleted: true)
        if e == nil {
            do {
                token = try await UserController.passwordToken(req: req,
                                                               isURLEncoded: true,
                                                               isNewUser: &isNewUser)
                postTo = UserController.passwordSetPath(urlEncodedToken: token)
            } catch {
                req.session.set(error)
                e = req.session.passwordSetError(isDeleted: true)
            }
        }
        let input = Self.PasswordSetView(postTo: postTo,
                                         isNewUser: isNewUser,
                                         error: e?.message)
        return await Self.delegate.will(.setPassword(input: input))
    }
    
    // called after join, password reset with password-token... and update with authenticated user
    func postPasswordSet(req: Request) async throws -> Response {
        do {
            let password = try req.content.decode(Password.self).value
            var isNewUser = true
            try await UserController.setPassword(password, isNewUser: &isNewUser, req: req)
            if isNewUser {
                return await Self.delegate.did(.join(req))
            } else {
                return await Self.delegate.did(.setPassword(req))
            }
        } catch {
            req.session.set(error)
            return req.redirect(to: UserController.passwordSetPath())
        }
    }
    
    // display sign-in page with options
    func displaySignIn(req: Request) async throws -> Response {
        let user = try? UserController.authenticatedUser(req: req)
        guard user == nil else {
            return await Self.delegate.did(.signIn(req))
        }
        let e = req.session.joinSignInError(isDeleted: true)
        let (apple, google) = Self.appleGoogleView(appleError: e?.apple, googleError: e?.google)
        let email = Self.emailSignInView(email: e?.address, error: e?.error)
        let token = EmailController.token()
        let response = await Self.delegate.will(.signIn(state: token, email: email, apple: apple, google: google))
        UserController.setAuthenticationCookies(token: token, response: response)
        return response
    }
    
    // email <form> submit on sign-in page
    func postEmailSignIn(req: Request) async throws -> Response {
        do {
            let signIn = try req.content.decode(SignIn.self)
            try await UserController.signIn(signIn, req: req)
            return await Self.delegate.did(.signIn(req))
        } catch {
            req.session.set(error)
            return req.redirect(to: UserController.signInPath())
        }
    }
    
    func signOut(req: Request) async throws -> Response {
        UserController.unauthenticate(isSessionEnd: true, req: req)
        return await Self.delegate.did(.signOut(req))
    }
    
    func unjoin(req: Request) async throws -> Response {
        do {
            try await UserController.unjoinAuthenticatedUser(req: req)
        } catch {
            req.session.set(error)
        }
        return await Self.delegate.did(.unjoin(req))
    }
}
