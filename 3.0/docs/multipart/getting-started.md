# Getting Started with Multipart

Multipart ([vapor/multipart](https://github.com/vapor/multipart)) is a small package that helps you parse and serialize `multipart` encoded data. Multipart is a widely-supported encoding on the web. It's most often used for serializing web forms, especially ones that contain rich media like images.

The Multipart package makes it easy to use this encoding by integrating directly with `Codable`.

## Vapor

This package is included with Vapor and exported by default. You will have access to all `Multipart` APIs when you import `Vapor`.

```swift
import Vapor
```

## Standalone

The Multipart package is lightweight, pure-Swift, and has very few dependencies. This means it can be used to work with multipart-encoded data for any Swift project&mdash;even one not using Vapor.

To include it in your package, add the following to your `Package.swift` file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/multipart.git", from: "3.0.0"),
    ],
    targets: [
      .target(name: "Project", dependencies: ["Multipart", ... ])
    ]
)
```

Use `import Multipart` to access the APIs.

!!! warning
	Some of this guide may contain Vapor-specific APIs, however most of it should be applicable to the Multipart package in general.
	Visit the [API Docs](https://api.vapor.codes/multipart/latest/Multipart/index.html) for Multipart-specific API info.

