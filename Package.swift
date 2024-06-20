// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "yousnite-library",
    platforms: [
        .iOS(.v13),
        .macOS(.v12),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "Emails",
                 targets: [
                    "Users",
                    "Emails",
                 ]),
        .library(name: "Users",
                 targets: [
                    "Utilities",
                    "Users",
                 ]),
        .library(name: "Utilities", 
                 targets: [
                    "Utilities"
                 ]),
        .library(name: "YousniteLibrary", targets: ["YousniteLibrary"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.89.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0-rc"),
        .package(url: "https://github.com/awslabs/aws-sdk-swift", from: "0.32.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(name: "Emails",
                dependencies: [
                    .product(name: "Vapor", package: "vapor"),
                    .product(name: "AWSSESv2", package: "aws-sdk-swift"),
                    "Users",
                ]),
        .target(name: "Users",
                dependencies: [
                    .product(name: "Vapor", package: "vapor"),
                    .product(name: "Fluent", package: "fluent"),
                    .product(name: "JWT", package: "jwt"),
                    "Utilities",
                ]),
        .target(name: "Utilities",
                dependencies: [
                    .product(name: "Vapor", package: "vapor"),
                ]),
        .target(name: "YousniteLibrary"),
        .testTarget(name: "YousniteLibraryTests",
                    dependencies: [
                        .product(name: "Vapor", package: "vapor"),
                        .product(name: "Fluent", package: "fluent"),
                        .product(name: "JWT", package: "jwt"),
                        "Emails",
                        "Users",
                        "Utilities",
                    ]),
    ]
)
