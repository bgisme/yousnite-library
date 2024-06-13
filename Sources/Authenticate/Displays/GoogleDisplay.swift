public struct GoogleDisplay: ViewControllerSourceGoogleDisplay {
    public let clientId: String
    public let redirectUri: String
    public let error: String?
    
    public init(clientId: String = GoogleController.clientId,
                redirectUri: String = ViewController.googleRedirectPath,
                error: String? = nil) {
        self.clientId = clientId
        self.redirectUri = redirectUri
        self.error = error
    }
}
