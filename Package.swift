// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "VaporDocs",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // Local path dep while the shared-layer/head features are unreleased; swap
        // back to the tagged release once Kiln + the design package are published.
        // .package(url: "https://github.com/brokenhandsio/kiln.git", from: "1.3.1"),
        .package(path: "../../BrokenHands/kiln"),
        // Shared Vapor design templates (footer/head), consumed as a Kiln theme layer.
        .package(path: "../design"),
    ],
    targets: [
        .executableTarget(
            name: "VaporDocs",
            dependencies: [
                .product(name: "Kiln", package: "kiln"),
                .product(name: "VaporDesignTheme", package: "design"),
            ]
        ),
    ]
)
