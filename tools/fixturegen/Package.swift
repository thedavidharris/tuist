// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FixtureGenerator",
    platforms: [
        .macOS(.v10_13),
    ],
    products: [
        .executable(name: "fixturegen", targets: ["FixtureGenerator"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-tools-support-core", from: "0.0.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "FixtureGenerator",
            dependencies: [
                "SwiftToolsSupport",
            ]
        ),
    ]
)
