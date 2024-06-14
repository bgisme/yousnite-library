import Vapor

// MARK: - AppleView + GoogleView
extension ViewController {
    struct Apple: AppleView {
        let servicesId: String
        let scopes: AppleScopeOptions
        let redirectUri: String
        let error: String?
        
        init(servicesId: String = AppleController.servicesId,
             scopes: AppleScopeOptions = .all,
             redirectUri: String = ViewController.appleRedirectPath,
             error: String? = nil) {
            self.servicesId = servicesId
            self.scopes = scopes
            self.redirectUri = redirectUri
            self.error = error
        }
    }
    
    struct Google: GoogleView {
        let clientId: String
        let redirectUri: String
        let error: String?
        
        init(clientId: String = GoogleController.clientId,
             redirectUri: String = ViewController.googleRedirectPath,
             error: String? = nil) {
            self.clientId = clientId
            self.redirectUri = redirectUri
            self.error = error
        }
    }
    
    static func appleGoogleView(req: Request) -> (AppleView, GoogleView) {
        let e = try? Self.exception(req: req)
        var apple = Apple(redirectUri: path(isRelative: false, appending: appleRedirectRoute))
        var google = Google(redirectUri: ViewController.path(isRelative: false, appending: googleRedirectRoute))
        if let e = e {
            switch e.method {
            case .apple:
                apple = Apple(error: e.message)
            case .google:
                google = Google(error: e.message)
            default:
                break
            }
        }
        return (apple, google)
    }
}

// MARK: - EmailJoinView
extension ViewController {
    struct EmailJoin: EmailJoinView {
        let email: String?
        let postTo: String
        let signInPath: String
        let error: String?
        
        init(email: String? = nil,
             postTo: String = ViewController.emailRequestPath(isNewUser: true),
             signInPath: String = ViewController.signInPath(),
             error: String? = nil) {
            self.email = email
            self.postTo = postTo
            self.signInPath = signInPath
            self.error = error
        }
    }
    
    static func emailJoinView(isDeleted: Bool = false, req: Request) -> EmailJoinView {
        if let e = try? Self.exception(isDeleted: isDeleted, req: req) {
            switch e.method {
            case .email(let address):
                return EmailJoin(email: address, error: e.message)
            default:
                break
            }
        }
        return EmailJoin()
    }
}

// MARK: - EmailSignInView
extension ViewController {
    struct EmailSignIn: EmailSignInView {
        let postTo: String
        let joinPath: String
        let passwordResetPath: String
        let email: String?
        let error: String?
        
        init(postTo: String = ViewController.signInPath(),
             joinPath: String = ViewController.joinPath(),
             passwordResetPath: String = ViewController.passwordResetPath(),
             email: String? = nil,
             error: String? = nil) {
            self.postTo = postTo
            self.joinPath = joinPath
            self.passwordResetPath = passwordResetPath
            self.email = email
            self.error = error
        }
    }
    
    static func emailSignInView(isDeleted: Bool = false, req: Request) -> EmailSignInView {
        if let e = try? Self.exception(isDeleted: isDeleted, req: req) {
            switch e.method {
            case .email(let address):
                return EmailSignIn(email: address, error: e.message)
            default:
                break
            }
        }
        return EmailSignIn()
    }
}

// MARK: - PasswordResetView
extension ViewController {
    struct PasswordReset: PasswordResetView {
        let postTo: String
        let joinPath: String
        let signInPath: String
        let email: String?
        let error: String?
        
        init(postTo: String = ViewController.emailRequestPath(),
             joinPath: String = ViewController.joinPath(),
             signInPath: String = ViewController.signInPath(),
             email: String? = nil,
             error: String? = nil) {
            self.postTo = postTo
            self.joinPath = joinPath
            self.signInPath = signInPath
            self.email = email
            self.error = error
        }
    }
    
    static func passwordResetView(isDeleted: Bool = false, req: Request) -> PasswordResetView {
        if let e = try? Self.exception(isDeleted: isDeleted, req: req) {
            switch e.method {
            case .email(let address):
                return PasswordReset(email: address, error: e.message)
            default:
                break
            }
        }
        return PasswordReset()
    }
}

// MARK: - PasswordUpdateView
extension ViewController {
    struct PasswordUpdate: PasswordUpdateView {
        let email: String
        let isNewUser: Bool
        let postTo: String
        let signInPath: String?
        let error: String?
        
        init(email: String,
             isNewUser: Bool,
             postTo: String = ViewController.passwordUpdatePath(),
             state: String? = nil,
             signInPath: String = ViewController.signInPath(),
             error: String? = nil) {
            self.email = email
            self.isNewUser = isNewUser
            if let state = state {
                self.postTo = postTo + "/" + state
            } else {
                self.postTo = postTo
            }
            self.signInPath = signInPath
            self.error = error
        }
    }
    
    static func passwordUpdateView(email: String,
                                           isNewUser: Bool,
                                           state: String? = nil,
                                           isDeleted: Bool = false,
                                           req: Request) -> PasswordUpdateView {
        if let e = try? Self.exception(isDeleted: isDeleted, req: req) {
            return PasswordUpdate(email: email,
                                  isNewUser: isNewUser,
                                  state: state,
                                  error: e.message)
        }
        return PasswordUpdate(email: email,
                              isNewUser: isNewUser,
                              state: state)
    }
}

