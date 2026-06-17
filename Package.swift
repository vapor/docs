// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "VaporDocs",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // TODO: revert to the released package once the navbar/footer
        // localisation changes (customStrings + #t tag) ship in a Kiln release.
        // .package(url: "https://github.com/brokenhandsio/kiln.git", from: "1.0.0"),
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
