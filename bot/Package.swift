// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "barebonesBot",
    products: [
        .executable(name: "Run", targets: ["Run"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "2.1.0")),
        .package(url: "https://github.com/vapor/fluent-provider.git", .upToNextMajor(from: "1.2.0")),
        .package(url: "https://github.com/vapor/mysql-provider.git", .revision("2.0.0")),
        .package(url: "https://github.com/czechboy0/Jay.git", .revision("1.0.1")),
        .package(url: "https://github.com/vapor-community/swiftybeaver-provider.git", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/vapor/leaf-provider.git", .upToNextMajor(from: "1.1.0")),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", .upToNextMajor(from: "1.5.9")),
        .package(url: "https://github.com/bsuvorov/swiftfbbotanalytics.git", .upToNextMajor(from: "1.0.3")),
    ],
    targets: [
        .target(name: "Run", dependencies: ["Vapor", "FluentProvider", "MySQLProvider", "Jay", "LeafProvider", "SwiftyBeaverProvider", "SwiftSoup", "BotAnalytics"]),
    ]
)
