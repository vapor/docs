// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "VaporDocs",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/brokenhandsio/kiln.git", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "VaporDocs",
            dependencies: [
                .product(name: "Kiln", package: "kiln"),
            ]
        ),
    ]
)
