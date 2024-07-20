import Vapor

extension ViewController: RouteCollection {
    public func boot(routes: RoutesBuilder) throws {
        routes.get(Self.joinRoute, use: join) // <form> for email address
        routes.get(Self.passwordResetRoute, use: passwordReset) // <form> for email address
        routes.get(Self.passwordSetRoute + [":\(EmailController.stateKey)"], use: passwordSet)  // join + reset links with password-token
        routes.get(Self.passwordSetRoute, use: passwordSet) // authenticated user changing password
        routes.get(Self.signInRoute, use: signIn)
        routes.get(Self.signOutRoute, use: signOut)
        routes.get(Self.unjoinRoute, use: unjoin)
    }
    
    // <form> for email address
    func join(req: Request) async throws -> Response {
        guard req.credential == nil else {
            // not authenticated
            return await Self.delegate.did(.join(req))
        }
        // errors from previous submit
        let e = req.session.joinSignInError(isDeleted: true)
        // display info
        let (apple, google) = Self.appleGoogleView(appleError: e?.apple,
                                                   googleError: e?.google)
        let email = Self.emailJoinView(email: e?.address, error: e?.error)
        // get response from delegate
        let state = EmailController.state()
        let response = await Self.delegate.will(.join(state: state, email: email, apple: apple, google: google))
        response.setAuthenticationCookies(state: state, isJoin: true)
        return response
    }
    
    // <form> for email address
    func passwordReset(req: Request) async throws -> Response {
        let e = req.session.passwordResetError(isDeleted: true)
        let input = Self.passwordResetView(email: e?.email, error: e?.message)
        return await Self.delegate.will(.resetPassword(input: input))
    }
    
    // called by join and reset email links with password-token... and authenticated user changing password without password-token
    func passwordSet(req: Request) async throws -> Response {
        var isNewUser = false
        var postTo: String?
        var e = req.session.passwordSetError(isDeleted: true)
        if e == nil {
            do {
                let state = try await EmailController.getState(req: req, isNewUser: &isNewUser)
                postTo = EmailController.passwordSetPath(state: state)
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
    
    // display sign-in page with options
    func signIn(req: Request) async throws -> Response {
        guard try req.credential == nil else {
            // already authenticated
            return await Self.delegate.did(.signIn(req))
        }
        let e = req.session.joinSignInError(isDeleted: true)
        let (apple, google) = Self.appleGoogleView(appleError: e?.apple, googleError: e?.google)
        let email = Self.emailSignInView(email: e?.address, error: e?.error)
        let state = EmailController.state()
        let response = await Self.delegate.will(.signIn(state: state, email: email, apple: apple, google: google))
        response.setAuthenticationCookies(state: state)
        return response
    }
    
    func signOut(req: Request) async throws -> Response {
        MainController.unauthenticate(isSessionEnd: true, req: req)
        return await Self.delegate.did(.signOut(req))
    }
    
    func unjoin(req: Request) async throws -> Response {
        do {
            try await MainController.unjoinauthentication(req: req)
        } catch {
            req.session.set(error)
        }
        return await Self.delegate.did(.unjoin(req))
    }
}
