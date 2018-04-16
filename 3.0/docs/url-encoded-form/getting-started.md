# Getting Started with URL-Encoded Form

URL-Encoded Form ([vapor/url-encoded-form](https://github.com/vapor/url-encoded-form)) is a small package that helps you parse and serialize `application/x-www-form-urlencoded` data. URL-encoded forms are a widely-supported encoding on the web. It's most often used for serializing web forms sent via POST requests.

The URL-Encoded Form package makes it easy to use this encoding by integrating directly with `Codable`.

## Vapor

This package is included with Vapor and exported by default. You will have access to all `URLEncodedForm` APIs when you import `Vapor`.

```swift
import Vapor
```

## Standalone

The URL-Encoded Form package is lightweight, pure-Swift, and has very few dependencies. This means it can be used to work with `form-urlencoded` data for any Swift project&mdash;even one not using Vapor.

To include it in your package, add the following to your `Package.swift` file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/url-encoded-form.git", from: "1.0.0"),
    ],
    targets: [
      .target(name: "Project", dependencies: ["URLEncodedForm", ... ])
    ]
)
```

Use `import URLEncodedForm` to access the APIs.

!!! warning
	Some of this guide may contain Vapor-specific APIs, however most of it should be applicable to the URL-Encoded Form package in general.
	Visit the [API Docs](https://api.vapor.codes/url-encoded-form/latest/URLEncodedForm/index.html) for specific API info.

