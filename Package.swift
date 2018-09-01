// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "VaporWebSocket",
    products: [
        .library(name: "VaporWebSocket", targets: ["VaporWebSocket"]),
    ],
    dependencies: [
        // 🌎 Utility package containing tools for byte manipulation, Codable, OS APIs, and debugging.
        .package(url: "https://github.com/readdle/vapor-core.git", .exact("3.4.3")),

        // 🔑 Hashing (BCrypt, SHA2, HMAC), encryption (AES), public-key (RSA), and random data generation.
        .package(url: "https://github.com/albertaleksieiev/vapor-crypto.git", .exact("3.2.1")),

        // 🚀 Non-blocking, event-driven HTTP for Swift built on Swift NIO.
        .package(url: "https://github.com/albertaleksieiev/http.git", .exact("3.1.3")),

        // Event-driven network application framework for high performance protocol servers & clients, non-blocking.
        .package(url: "https://github.com/readdle/swift-nio.git", .exact("1.9.3")),

        // Bindings to OpenSSL-compatible libraries for TLS support in SwiftNIO
        .package(url: "https://github.com/readdle/swift-nio-ssl.git", .exact("1.2.2")),
    ],
    targets: [
        .target(
                name: "VaporWebSocket",
                dependencies: ["Core", "Crypto", "HTTP", "NIO", "NIOWebSocket"],
                path: "Sources/WebSocket"
        ),
        .testTarget(name: "WebSocketTests", dependencies: ["VaporWebSocket"]),
    ]
)
