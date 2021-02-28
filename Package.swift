// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "FoggyCMS",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/vapor/fluent.git", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/vapor/leaf.git", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/mcritz/TextBundle.git", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "TextBundle", package: "TextBundle"),
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .target(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
