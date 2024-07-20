import Vapor

public struct UsersController: Sendable {
    public init() {}
}

extension UsersController {
    public static func configure(app: Application) throws {
        app.migrations.add(User.Migration())
    }
}
