# yousnite-library

A collection of libraries to help build yousnite.


## Install

Add this dependency via the Swift Package Manager:

```swift
.package(url: "https://github.com/bgisme/yousnite-library.git", from: "0.0.1"),
```

Add the `YousniteLibrary` product from the `yousnite-library` package as a dependency to your target:
```swift
.product(name: "YousniteLibrary", package: "yousnite-library"),
```

Then import individual modules:
```swift
import Authenticate
import Email
import NestRoute
import SessionStorage
import User
import Utilities
import Validate
```

## Xcode Environment Variables

Include the following keys and values:

```
BASE_URI
APPLE_APP_ID
SIWA_SERVICES_ID
APPLE_JWK_KEY       
APPLE_JWK_ID
APPLE_TEAM_ID
GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET
```    

## Authenticate

Enable sessions in `configure.swift` to use this module.

Cookies must have `sameSite: .lax` or `.strict` so the session is returned in the Apple redirect handler.

```swift
app.sessions.configuration = .init(cookieName: "cookie-name") { sessionID in
    return HTTPCookies.Value(
        string: sessionID.string,
        expires: Date(
            timeIntervalSinceNow: 60 * 60 * 24 * 7 // one week
        ),
        maxAge: nil,
        domain: nil,
        path: "/",
        isSecure: false,
        isHTTPOnly: false,
        sameSite: .lax
    )
}
```  

In the `configure.swift` file, add...

```swift
try Authenticate.MainController.configure(app: app,
                                          source: User.self,
                                          emailSource: <any Protocol>,
                                          emailSender: <Name on emails>,
                                          viewControllerSource: <any Protocol>)

```

Other libraries, like `User` and `Email`, contain pre-made classes for `MainControllerSource`, `EmailSource` and `ViewControllerSource`. 
