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

Then import individual modules where necessary:
```swift
import Email
import Authenticate
import Utilities
```

## Xcode Environment Variables

Include the following keys and values:

```
BASE_WEB_URI
BASE_APP_URI
APPLE_APP_ID
SIWA_SERVICES_ID
APPLE_JWK_KEY       
APPLE_JWK_ID
APPLE_TEAM_ID
GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET
```    

## Authenticate

**STEP 1**
Enable sessions for all website traffic in `Sources > App > routes.swift > func routes(_ app: Application)`

```swift
let sessioned = app.grouped(app.sessions.middleware)    // session for all website traffic
try sessioned.register(collection: WebController())
```

**STEP 2**
The API routes use stateless tokens. If you want to require user authentication, add to the same method...

```swift
let api = app.grouped("api")
let userRequired = api.grouped([
    User.authenticator(),           // via username + password... continues after fail
    User.guardMiddleware()          // fails if no user
])
try userRequired.register(collection: Authenticate.APIController())
```

**STEP 3**
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

**STEP 4**
In the `configure.swift` file, add...

```swift
try Authenticate.APIController.configure(app: app,
                                          source: User.self,
                                          NotificationDelegate: <any Protocol>,
                                          emailSender: <Name on emails>,
                                          ViewDelegate: <any Protocol>)

```

Other libraries, like `User` and `Email`, contain pre-made classes for `APIDelegate`, `NotificationDelegate` and `ViewDelegate`. 


## Ngrok

**STEP 1**
Open Terminal

**STEP 2**
Run this command...
`> ngrok http 8080`

**STEP 3**
Copy the `Forwarding address`

For example...
`https://8f22-71-247-25-109.ngrok-free.app`


## Xcode
**STEP 1**
Open Run supplied Arguments

**STEP 2**
• Paste Ngrok address into field for 'BASE_WEB_URI'
• For example... `8f22-71-247-25-109.ngrok-free.app`
• Paste application address into field 'BASE_APP_URI'
• For example... 'yousnite'

## Sign In With Apple (SIWA)

**STEP 1**
• Go to Apple Developer Website... `https://developer.apple.com`
• Sign into your Account

**STEP 2**
• Go to Certificates, Identifiers & Profiles
• Select 'Services' from the left-hand list
• Then click 'Yousnite' on the right-hand side 
• Click the 'Configure' button next to 'Sign In With Apple'

**STEP 3**
• Click the blue '+' button next to 'Website URLs'
• A dialog box will appear
• In the 'Domains and Subdomains' field, paste the base Ngrok URL
• For example... `8f22-71-247-25-109.ngrok-free.app` (remove the `https://`)
• In the 'Return URLs' field, paste the full redirect URI path
• For example... `https://8f22-71-247-25-109.ngrok-free.app/auth/apple/redirect`
• Click the 'Done' button on the dialog box
• Click the blue 'Continue' button on the 'Edit your Services ID Configuration' page
• Click the blue 'Save' button

## Sign In With Google

**STEP 1**
• Go to the Credentials page of the Google APIs console `https://console.developers.google.com/apis`
• In the 'Authorized JavaScript origins' field, paste the full Ngrok address
• For example... `https://8f22-71-247-25-109.ngrok-free.app` 
• In the 'Authorized Redirect URIs' field, paste the full redirect URI path
• For example... `https://8f22-71-247-25-109.ngrok-free.app/auth/google/redirect`
• Click the blue 'Save' button
