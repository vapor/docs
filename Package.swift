// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "VaporDocs",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // Local path dependency during the Kiln migration. Switch to the
        // published package once Kiln is released:
        //   .package(url: "https://github.com/brokenhandsio/kiln.git", from: "1.0.0")
        .package(path: "../../BH/kiln"),
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
