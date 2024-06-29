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
             redirectUri: String,
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
             redirectUri: String,
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
                let appleRedirectUri = ViewController.appleRedirectPath
                apple = Apple(redirectUri: appleRedirectUri, error: e.message)
            case .google:
                let googleRedirectUri = ViewController.googleRedirectPath
                google = Google(redirectUri: googleRedirectUri, error: e.message)
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
             postTo: String/* = ViewController.emailRequestPath(isNewUser: true)*/,
             signInPath: String/* = ViewController.signInPath()*/,
             error: String? = nil) {
            self.email = email
            self.postTo = postTo
            self.signInPath = signInPath
            self.error = error
        }
    }
    
    static func emailJoinView(isDeleted: Bool = false, req: Request) -> EmailJoinView {
        let postTo = ViewController.emailRequestPath(isNewUser: true)
        let signInPath = ViewController.signInPath()
        if let e = try? Self.exception(isDeleted: isDeleted, req: req) {
            switch e.method {
            case .email(let address):
                return EmailJoin(email: address,
                                 postTo: postTo,
                                 signInPath: signInPath,
                                 error: e.message)
            default:
                break
            }
        }
        return EmailJoin(postTo: postTo,
                         signInPath: signInPath)
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
        
        init(postTo: String,
             joinPath: String,
             passwordResetPath: String,
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
        let postTo = ViewController.signInPath()
        let joinPath = ViewController.joinPath()
        let passwordResetPath = ViewController.passwordResetPath()
        if let e = try? Self.exception(isDeleted: isDeleted, req: req) {
            switch e.method {
            case .email(let address):
                return EmailSignIn(postTo: postTo,
                                   joinPath: joinPath,
                                   passwordResetPath: passwordResetPath,
                                   email: address, error: e.message)
            default:
                break
            }
        }
        return EmailSignIn(postTo: postTo,
                           joinPath: joinPath,
                           passwordResetPath: passwordResetPath)
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
        
        init(postTo: String,
             joinPath: String,
             signInPath: String,
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
        let postTo = ViewController.emailRequestPath()
        let joinPath = ViewController.joinPath()
        let signInPath = ViewController.signInPath()
        if let e = try? Self.exception(isDeleted: isDeleted, req: req) {
            switch e.method {
            case .email(let address):
                return PasswordReset(postTo: postTo,
                                     joinPath: joinPath,
                                     signInPath: signInPath,
                                     email: address,
                                     error: e.message)
            default:
                break
            }
        }
        return PasswordReset(postTo: postTo,
                             joinPath: joinPath,
                             signInPath: signInPath)
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
             postTo: String,
             state: String? = nil,
             signInPath: String,
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
                                   req: Request) -> PasswordUpdateView {
        let postTo = ViewController.passwordUpdatePath()
        let signInPath = ViewController.signInPath()
        if let e = try? Self.exception(isDeleted: true, req: req) {
            return PasswordUpdate(email: email,
                                  isNewUser: isNewUser,
                                  postTo: postTo,
                                  state: state,
                                  signInPath: signInPath,
                                  error: e.message)
        }
        return PasswordUpdate(email: email,
                              isNewUser: isNewUser,
                              postTo: postTo,
                              state: state,
                              signInPath: signInPath)
    }
    
    struct PasswordUpdateInvalid: PasswordUpdateInvalidView {
        let error: String
    }
    
    static func passwordUpdateViewInvalid(_ message: String,
                                          req: Request) -> PasswordUpdateInvalidView {
        PasswordUpdateInvalid(error: message)
    }
}

