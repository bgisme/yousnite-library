import Vapor

extension ViewController {
    private static let errorKey = "ViewController.error"
    
    public struct Exception: Error, Codable {
        enum Method: Codable {
            case email(_ address: String? = nil)
            case apple
            case google
        }
        let method: Method
        let message: String
    }
    
    static func setException(_ error: Error, method: Exception.Method, req: Request) {
        setException(error.localizedDescription, method: method, req: req)
    }
    
    static func setException(_ message: String, method: Exception.Method, req: Request) {
        setException(Exception(method: method, message: message), req: req)
    }
    
    static func setException(_ exception: Exception, req: Request) {
        req.session.set(exception, key: errorKey)
    }
    
    static func exception(isDeleted: Bool = false, req: Request) throws -> Exception {
        try req.session.get(Exception.self, key: errorKey, isDeleted: isDeleted)
    }
}
