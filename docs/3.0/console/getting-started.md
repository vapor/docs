# Getting Started with Console

The Console module is provided as a part of Vapor's Console package ([vapor/console](https://github.com/vapor/console)).  This module provides APIs for performing console I/O including things like outputting stylized text, requesting user input, and displaying activity indicators like loading bars.

!!! tip
    For an in-depth look at all of Console's APIs, check out the [Console API docs](https://api.vapor.codes/console/latest/Console/index.html).

## Usage

This package is included with Vapor and exported by default. You will have access to all `Console` APIs when you import `Vapor`.

```swift
import Vapor // implies import Console
```

### Standalone

The Console module, part of the larger Vapor Console package, can also be used on its own with any Swift project.

To include it in your package, add the following to your `Package.swift` file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        /// 💻 APIs for creating interactive CLI tools.
        .package(url: "https://github.com/vapor/console.git", from: "3.0.0"),
    ],
    targets: [
      .target(name: "Project", dependencies: ["Console", ... ])
    ]
)
```

Use `import Console` to access the APIs.

## Overview

Continue to [Console → Overview](overview.md) for an overview of Console's features.