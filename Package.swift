// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "VaporDocs",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
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
