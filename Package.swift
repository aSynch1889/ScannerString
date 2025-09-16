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
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
    ],
    targets: [
        .target(
            name: "ScannerString",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax")
            ]),
        .testTarget(
            name: "ScannerStringTests",
            dependencies: ["ScannerString"]),
    ]
) 