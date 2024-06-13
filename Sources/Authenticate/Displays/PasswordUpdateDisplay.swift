public struct PasswordUpdateDisplay: ViewControllerSourcePasswordUpdateDisplay {
    public let email: String
    public let isNewUser: Bool
    public let postTo: String
    public let signInPath: String?
    public let error: String?
    
    public init(email: String,
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
