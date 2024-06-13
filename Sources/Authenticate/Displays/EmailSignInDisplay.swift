public struct EmailSignInDisplay: ViewControllerSourceEmailSignInDisplay {
    public let postTo: String
    public let joinPath: String
    public let passwordResetPath: String
    public let email: String?
    public let error: String?
    
    public init(postTo: String = ViewController.signInPath(),
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
