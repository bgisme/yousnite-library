import Vapor

// MARK: - AppleView + GoogleView
extension ViewController {
    static func appleGoogleView(appleError: String?,
                                googleError: String?) -> (AppleView, GoogleOAuthView) {
        let apple = Apple(error: appleError)
//        let google = GoogleJavascript(error: googleError)
        let google = GoogleOAuth(error: googleError)
        return (apple, google)
    }

    struct Apple: AppleView {
        let servicesId: String
        let scopes: AppleScopeOptions
        let redirectUri: String
        let error: String?
        
        init(servicesId: String = AppleController.servicesId,
             scopes: AppleScopeOptions = .all,
             redirectUri: String = AppleController.redirectPath,
             error: String?) {
            self.servicesId = servicesId
            self.scopes = scopes
            self.redirectUri = redirectUri
            self.error = error
        }
    }
    
    struct GoogleOAuth: GoogleOAuthView {
        let href: String
        let error: String?
        
        init(href: String = GoogleController.oAuthPath,
             error: String?) {
            self.href = href
            self.error = error
        }
    }
    
    struct GoogleJavascript: GoogleJavascriptView {
        let clientId: String
        let redirectUri: String
        let error: String?
        
        init(clientId: String = GoogleController.clientId,
             redirectUri: String = GoogleController.javascriptPath,
             error: String? = nil) {
            self.clientId = clientId
            self.redirectUri = redirectUri
            self.error = error
        }
    }
}

// MARK: - EmailJoinView
extension ViewController {
    static func emailJoinView(email: String?,
                              error: String?) -> EmailJoinView {
        return EmailJoin(email: email,
                         postTo: EmailController.joinPath(),
                         signInPath: signInPath(),
                         error: error)
    }

    struct EmailJoin: EmailJoinView {
        let email: String?
        let postTo: String
        let signInPath: String
        let error: String?
    }
}

// MARK: - EmailSignInView
extension ViewController {
    static func emailSignInView(email: String?,
                                error: String?) -> EmailSignInView {
        return EmailSignIn(postTo: EmailController.signInPath(),
                           joinPath: joinPath(),
                           passwordResetPath: passwordResetPath(),
                           email: email,
                           error: error)
    }

    struct EmailSignIn: EmailSignInView {
        let postTo: String
        let joinPath: String
        let passwordResetPath: String
        let email: String?
        let error: String?
    }
}

// MARK: - PasswordResetView
extension ViewController {
    static func passwordResetView(email: String?,
                                  error: String?) -> PasswordResetView {
        return PasswordReset(postTo: EmailController.passwordResetPath(),
                             joinPath: joinPath(),
                             signInPath: signInPath(),
                             email: email,
                             error: error)
    }

    struct PasswordReset: PasswordResetView {
        let postTo: String
        let joinPath: String
        let signInPath: String
        let email: String?
        let error: String?
    }
}

// MARK: - PasswordSetView
extension ViewController {
    static func PasswordSetView(postTo: String?,
                                isNewUser: Bool,
                                error: String?) -> PasswordSetView {
        return PasswordSet(postTo: postTo,
                           joinPath: joinPath(),
                           signInPath: signInPath(),
                           isNewUser: isNewUser,
                           requirements: Password.requirements,
                           error: error)
    }
    
    struct PasswordSet: PasswordSetView {
        let postTo: String?
        let joinPath: String
        let signInPath: String
        let isNewUser: Bool
        let requirements: String?
        let error: String?
    }
}

