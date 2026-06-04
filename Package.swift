// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "VaporDocs",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // Kiln is fetched from GitHub (used by CI, Docker and deployment).
        // For local development against a checkout of Kiln, comment this out
        // and use the path dependency below instead.
        .package(url: "https://github.com/brokenhandsio/kiln.git", branch: "main"),
        // .package(path: "../../BH/kiln"),
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
