import Vapor

extension Session {
    public func set<T: Encodable>(_ type: T, key: String) {
        if let data = try? JSONEncoder().encode(type.self) {
            self.data[key] = String(data: data, encoding: .utf8)
        }
    }

    public func get<T: Decodable>(_ type: T.Type, key: String, isDeleted: Bool = false) throws -> T {
        guard 
            let data = self.data[key]?.data(using: .utf8),
            let result = try? JSONDecoder().decode(T.self, from: data)
        else {
            throw Exception(type: type, key: key)
        }
        if isDeleted { self.data[key] = nil }
        return result
    }
    
    // thrown when get(:key:isDeleted) can not find value for key
    public struct Exception<T>: Error, LocalizedError {
        let type: T
        let key: String
        
        public var errorDescription: String? { "No value for '\(key)' in session." }
    }
    
    @discardableResult
    public func delete<T: Decodable>(_ type: T.Type, key: String) throws -> T {
        try get(type, key: key, isDeleted: true)
    }
    
    public static let errorKey = "error_key"
    
    public func set<T: Error>(_ error: T, key: String? = nil) {
        if let codable = error as? Codable {
            set(codable, key: key ?? Self.errorKey)
        } else {
            set(error.localizedDescription, key: key ?? Self.errorKey)
        }
    }
    
    public func setError(_ message: String, key: String? = nil) {
        set(message, key: key ?? Self.errorKey)
    }
    
    public func getError<T: Decodable>(_ type: T.Type, key: String? = nil, isDeleted: Bool = false) throws -> T {
        try get(type, key: key ?? Self.errorKey, isDeleted: isDeleted)
    }
    
    public func getErrorMessage(key: String? = nil, isDeleted: Bool = false) throws -> String {
        try get(String.self, key: key ?? Self.errorKey, isDeleted: isDeleted)
    }
}
