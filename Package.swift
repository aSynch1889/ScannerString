// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ScannerString",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ScannerString",
            targets: ["ScannerString"]),
        .executable(
            name: "scannerstring",
            targets: ["ScannerStringCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "ScannerString",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax")
            ]),
        .executableTarget(
            name: "ScannerStringCLI",
            dependencies: [
                "ScannerString",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .testTarget(
            name: "ScannerStringTests",
            dependencies: ["ScannerString"]),
    ]
) 