public extension String.UnicodeScalarView {
    /// Convert back into a string to continue chain of commands
    /// For example...
    /// 
    var stringValue: String { String(self) }
}
