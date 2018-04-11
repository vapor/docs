# Getting Started with Validation

Validation ([vapor/validation](https://github.com/vapor/validation)) is a framework for validating data sent to your application. It can help validate things like names, emails and more. It is also extensible, allowing you to easily create custom validators.

The rest of this guide will show you how to add and import the `Validation` module. For more information on using this package, check out [Validation &rarr; Overview](overview.md).

## Vapor

This package is included with Vapor and exported by default. You will have access to all `Validation` APIs when you import `Vapor`.

```swift
import Vapor
```

## Standalone

The Service package is lightweight, pure-Swift, and has very few dependencies. This means it can be used as a validation framework for any Swift project&mdash;even one not using Vapor.

To include it in your package, add the following to your `Package.swift` file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/validation.git", from: "2.0.0"),
    ],
    targets: [
      .target(name: "Project", dependencies: ["Validation", ... ])
    ]
)
```

Use `import Validation` to access the APIs.

!!! warning
	Some of this guide may contain Vapor-specific APIs, however most of it should be applicable to the Validation package in general.
	Visit the [API Docs](https://api.vapor.codes/validation/latest/Validation/index.html) for Validation-specific API info.

