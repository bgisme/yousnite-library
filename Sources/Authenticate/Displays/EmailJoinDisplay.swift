public struct EmailJoinDisplay: ViewControllerSourceEmailJoinDisplay {
    public let email: String?
    public let postTo: String
    public let signInPath: String
    public let error: String?
    
    public init(email: String? = nil,
                postTo: String = ViewController.emailRequestPath(isNewUser: true),
                signInPath: String = ViewController.signInPath(),
                error: String? = nil) {
        self.email = email
        self.postTo = postTo
        self.signInPath = signInPath
        self.error = error
    }
}
