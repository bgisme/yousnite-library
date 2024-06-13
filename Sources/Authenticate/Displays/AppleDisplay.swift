extension ViewController {
    public struct AppleDisplay: ViewControllerSourceAppleDisplay {
        public let servicesId: String
        public let scopes: AppleScopeOptions
        public let redirectUri: String
        public let error: String?
        
        public init(servicesId: String = AppleController.servicesId,
                    scopes: AppleScopeOptions = .all,
                    redirectUri: String = ViewController.appleRedirectPath,
                    error: String? = nil) {
            self.servicesId = servicesId
            self.scopes = scopes
            self.redirectUri = redirectUri
            self.error = error
        }
    }
}
