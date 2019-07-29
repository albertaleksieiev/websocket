// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "VaporWebSocket",
    products: [
        .library(name: "VaporWebSocket", type: .dynamic, targets: ["VaporWebSocket"]),
    ],
    dependencies: [
        // 🌎 Utility package containing tools for byte manipulation, Codable, OS APIs, and debugging.
        .package(url: "https://github.com/readdle/vapor-core.git", .upToNextMajor(from: "3.4.4")),

        // 🔑 Hashing (BCrypt, SHA2, HMAC), encryption (AES), public-key (RSA), and random data generation.
        .package(url: "https://github.com/readdle/vapor-crypto.git", .upToNextMajor(from: "3.2.3")),

        // 🚀 Non-blocking, event-driven HTTP for Swift built on Swift NIO.
        .package(url: "https://github.com/readdle/vapor-http.git", .upToNextMajor(from: "3.1.5")),

        // Event-driven network application framework for high performance protocol servers & clients, non-blocking.
        .package(url: "https://github.com/readdle/swift-nio.git", .upToNextMajor(from: "1.9.4")),

        // Bindings to OpenSSL-compatible libraries for TLS support in SwiftNIO
        .package(url: "https://github.com/readdle/swift-nio-ssl.git", .upToNextMajor(from: "1.2.3")),
        .package(url: "https://github.com/readdle/swift-openssl-prebuilt.git", .exact("0.0.3"))
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
