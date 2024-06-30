extension User: UserIdentifiable {
    public var authenticationType: AuthenticationType {
        self.type
    }
}
