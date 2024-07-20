// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "yousnite-library",
    platforms: [
        .iOS(.v13),
        .macOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "Authenticate",
                 targets: [
                    "Utilities",
                    "Authenticate",
                 ]),
        .library(name: "Clubs",
                 targets: [
                    "Utilities",
                    "Clubs",
                 ]),
        .library(name: "Email",
                 targets: [
                    "Authenticate",
                    "Email",
                 ]),
        .library(name: "Registration",
                 targets: [
                    "Utilities",
                    "Registration",
                 ]),
        .library(name: "Users",
                 targets: [
                    "Authenticate",
                    "Users",
                 ]),
        .library(name: "Utilities",
                 targets: [
                    "Utilities"
                 ]),
        .library(name: "YousniteLibrary",
                 targets: [
                    "Authenticate",
                    "Clubs",
                    "Email",
                    "Registration",
                    "Users",
                    "Utilities",
                 ]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.89.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0-rc"),
        .package(url: "https://github.com/soto-project/soto.git", from: "6.0.0"),
        // Authentication via Google, Facebook, etc.
        .package(path: "/Users/bradgourley/Documents/Programming/Learning/Swift/Testing/Imperial"),
//        .package(url: "https://github.com/vapor-community/Imperial.git", from: "1.0.0"),
//        .package(url: "https://github.com/bgisme/Imperial.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(name: "Authenticate",
                dependencies: [
                    .product(name: "Vapor", package: "vapor"),
                    .product(name: "Fluent", package: "fluent"),
                    .product(name: "JWT", package: "jwt"),
                    .product(name: "ImperialGoogle", package: "Imperial"),
                    "Utilities",
                ]),
        .target(name: "Clubs",
               dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                "Utilities",
               ]),
        .target(name: "Email",
                dependencies: [
                    .product(name: "Vapor", package: "vapor"),
                    .product(name: "SotoSESv2", package: "soto"),
                    "Authenticate",
                ]),
        .target(name: "Registration",
               dependencies: [
                "Utilities",
               ]),
        .target(name: "Users",
                dependencies: [
                    .product(name: "Vapor", package: "vapor"),
                    .product(name: "Fluent", package: "fluent"),
                    "Authenticate",
                ]),
        .target(name: "Utilities",
                dependencies: [
                    .product(name: "Vapor", package: "vapor"),
                    .product(name: "Fluent", package: "fluent"),
                ]),
        .target(name: "YousniteLibrary", dependencies: [
            "Authenticate",
            "Clubs",
            "Email",
            "Registration",
            "Users",
            "Utilities",
        ]),
        .testTarget(name: "YousniteLibraryTests",
                    dependencies: [
                        .product(name: "Vapor", package: "vapor"),
                        .product(name: "Fluent", package: "fluent"),
                        .product(name: "JWT", package: "jwt"),
                        "Authenticate",
                        "Clubs",
                        "Email",
                        "Registration",
                        "Users",
                        "Utilities",
                    ]),
    ]
)
