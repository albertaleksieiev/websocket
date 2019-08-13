// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "VaporWebSocket",
    products: [
        .library(name: "VaporWebSocket", type: .dynamic, targets: ["VaporWebSocket"]),
    ],
    dependencies: [
        // 🌎 Utility package containing tools for byte manipulation, Codable, OS APIs, and debugging.
        .package(url: "https://github.com/readdle/vapor-core.git", .branch("3.9.1-android")),

        // 🔑 Hashing (BCrypt, SHA2, HMAC), encryption (AES), public-key (RSA), and random data generation.
        .package(url: "https://github.com/readdle/vapor-crypto.git", .branch("3.3.3-android")),

        // 🚀 Non-blocking, event-driven HTTP for Swift built on Swift NIO.
        .package(url: "https://github.com/readdle/vapor-http.git", .branch("3.2.1-android")),

        // Event-driven network application framework for high performance protocol servers & clients, non-blocking.
        .package(url: "https://github.com/readdle/swift-nio.git", .branch("1.14.1-android")),

        // Bindings to OpenSSL-compatible libraries for TLS support in SwiftNIO
        .package(url: "https://github.com/readdle/swift-nio-ssl.git", .branch("1.4.0-android")),
    ],
    targets: [
        .target(
                name: "VaporWebSocket",
                dependencies: ["Core", "Crypto", "HTTP", "NIO", "NIOWebSocket"],
                path: "Sources/WebSocket"
        ),
        .testTarget(name: "WebSocketTests", dependencies: ["VaporWebSocket"]),
    ],
    swiftLanguageVersions: [.v5],
    cLanguageStandard: .c11
)
