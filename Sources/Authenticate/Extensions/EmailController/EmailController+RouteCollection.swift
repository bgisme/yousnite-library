import Vapor

extension EmailController: RouteCollection {
    public static let stateKey = "state"
    
    public func boot(routes: any RoutesBuilder) throws {
        let emails = routes.grouped(Self.routes)
        
        emails.post(Self.joinRoute, use: join)  // content is email address
        emails.post(Self.passwordResetRoute, use: passwordReset)  // content is email address
        emails.post(Self.passwordSetRoute, use: passwordSet)  // authenticated user
        emails.post(Self.passwordSetRoute + [":\(Self.stateKey)"], use: passwordSet)  // email link with token
        emails.post(Self.signInRoute, use: signIn)  // content is email and password
    }
    
    // emails link with password-token
    func join(req: Request) async throws -> Response {
        let isAPI = req.cookies.isAPI
        let response: Response
        do {
            let address = try req.content.decode(Email.self).address
            try await Self.sendPasswordCreateResetLink(to: address, isNewUser: true, req: req)
            if isAPI {
                #warning("TODO: Need API response")
                response = .init(status: .ok)
            } else {
                #warning("TODO: Figure out best way to display email error")
                response = await ViewController.delegate.did(.email(.join, to: address, error: nil, req: req))
            }
        } catch {
            req.session.set(error)
            response = req.redirect(to: Self.joinPath())
        }
        // clean up cookies
        response.deleteAuthenticationCookies()
        return response
    }
    
    // emails link with password-token
    func passwordReset(req: Request) async throws -> Response {
        let isAPI = req.cookies.isAPI
        let response: Response
        do {
            let address = try req.content.decode(Email.self).address
            try await Self.sendPasswordCreateResetLink(to: address, isNewUser: false, isAPI: isAPI, req: req)
            if isAPI {
                #warning("TODO: Need API response")
                response = .init(status: .ok)
            } else {
                #warning("TODO: Figure out best way to display email error")
                response = await ViewController.delegate.did(.email(.passwordReset, to: address, error: nil, req: req))
            }
        } catch {
            if isAPI {
                #warning("TODO: Need API response")
                response = .init(status: .conflict)
            } else {
                req.session.set(error)
                response = req.redirect(to: ViewController.passwordResetPath())
            }
        }
        return response
    }

    // called by join and password-reset links with token... and by authenticated user
    func passwordSet(req: Request) async throws -> Response {
        let isAPI = req.cookies.isAPI
        let response: Response
        do {
            let password = try req.content.decode(Password.self).value
            var isNewUser = true
            try await Self.setPassword(password, isNewUser: &isNewUser, req: req)
            if isNewUser {
                if isAPI {
                    #warning("TODO: Need API response")
                    response = .init(status: .ok)
                } else {
                    response = await ViewController.delegate.did(.join(req))
                }
            } else {
                if isAPI {
                    #warning("TODO: Need API response")
                    response = .init(status: .ok)
                } else {
                    response = await ViewController.delegate.did(.setPassword(req))
                }
            }
        } catch {
            if isAPI {
                #warning("TODO: Need API response")
                response = .init(status: .conflict)
            } else {
                req.session.set(error)
                response = req.redirect(to: ViewController.passwordSetPath())
            }
        }
        return response
    }
    
    func signIn(req: Request) async throws -> Response {
        let isAPI = req.cookies.isAPI
        let response: Response
        do {
            let signIn = try req.content.decode(EmailPassword.self)
            try await MainController.signIn(signIn, req: req)
            if isAPI {
                #warning("TODO: Need API response")
                response = .init(status: .ok)
            } else {
                response = await ViewController.delegate.did(.signIn(req))
            }
        } catch {
            if isAPI {
                #warning("TODO: Need API response")
                response = .init(status: .conflict)
            } else {
                req.session.set(error)
                response = req.redirect(to: ViewController.signInPath())
            }
        }
        // clean up cookies
        response.deleteAuthenticationCookies()
        return response
    }
}
