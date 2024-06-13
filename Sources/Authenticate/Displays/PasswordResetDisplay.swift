public struct PasswordResetDisplay: ViewControllerSourcePasswordResetDisplay {
    public let postTo: String
    public let joinPath: String
    public let signInPath: String
    public let email: String?
    public let error: String?
    
    public init(postTo: String = ViewController.emailRequestPath(),
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
