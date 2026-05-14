// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "music",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(
            url: "https://github.com/vapor/postgres-nio.git",
            from: "1.21.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "music",
            dependencies: [
                .product(name: "PostgresNIO", package: "postgres-nio")
            ]
        )
    ]
)
