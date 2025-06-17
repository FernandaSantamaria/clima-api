// swift-tools-version:6.0
// app.views.use(.leaf)
import PackageDescription

let package = Package(
    name: "ClimaApi",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/thebarndog/swift-dotenv.git", from: "1.0.0"),
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // 🐬 Fluent driver for MySQL.
        .package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.4.0"),
        // 🍃 An expressive, performant, and extensible templating language built for Swift.
        .package(url: "https://github.com/vapor/leaf.git", from: "4.3.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        //     Mysql
        .package(url: "https://github.com/vapor/mysql-kit.git", from: "4.0.0"),
        //DotEnv
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.15.0"),
        //
    ],

    targets: [
        .executableTarget(
            name: "ClimaApi",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentMySQLDriver", package: "fluent-mysql-driver"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "MySQLKit", package: "mysql-kit"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "SwiftDotenv", package: "swift-dotenv"),

            ],
            swiftSettings: swiftSettings
        ),
        //.testTarget(
          //  name: "ClimaApiTests",

            //dependencies: [
              //  .target(name: "ClimaApi"),
                //.product(name: "VaporTesting", package: "vapor"),
            //],
            //path:"Sources/ClimaApi",
            //swiftSettings: swiftSettings
        //),
    ] 
      
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
