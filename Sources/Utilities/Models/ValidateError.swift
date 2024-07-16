// provide user feedback to forms
public struct ValueMessage: Codable {
    public let value: String?      // entered by user and returned for display
    public let message: String?    // error or helpful guidance
    
    public init(_ value: String? = nil, _ message: String? = nil) {
        self.value = value
        self.message = message
    }
}

public struct ValidateResults<K>: Error, Codable where K: Codable, K: Hashable {
    private var _results: [K: ValueMessage] = [:]
    
    public var results: [K: (String, String)] {
        var r = [K: (String, String)]()
        for (key, vm) in _results {
            if let value = vm.value,
               let message = vm.message {
                r[key] = (value, message)
            }
        }
        return r
    }
    
    // true if no error messages
    public var isEmpty: Bool {
        return _results
            .compactMap{ $0.1.message }
            .isEmpty
    }
    
    /// Create error separate from validation test
    /// For example...
    /// guard password == confirmPassword else {
    ///    throw ValidateResults<CodingKeys>(.confirmPassword, confirmPassword.value, "Does not match password.")
    /// }
    public init(_ key: K, _ value: String, _ message: String) {
        self.init([key : .init(value, message)])
    }
    
    /// Create empty container
    /// For example...
    /// var error = ValidateResults<CodingKeys>()
    /// (self.value, error[.value]) = value.validate(Self.valueValidations)
    public init(_ results: [K: ValueMessage] = [:]) {
        self._results = results
    }
 
    public subscript(key: K) -> ValueMessage? {
        get { _results[key] }
        set(newValue) { _results[key] = newValue }
    }
    
    public mutating func setMessage(_ message: String, _ key: K) {
        guard let vm = _results[key] else { return }
        _results[key] = .init(vm.value, message)
    }
}
