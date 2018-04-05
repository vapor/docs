# Getting Started with Logging

The Logging module is provided as a part of Vapor's Console package ([vapor/console](https://github.com/vapor/console)).  This module provides convenience APIs for creating log 

!!! tip
    For an in-depth look at all of Logging's APIs, check out the [Logging API docs](https://api.vapor.codes/console/latest/Logging/index.html).

## Usage

This package is included with Vapor and exported by default. You will have access to all `Logging` APIs when you import `Vapor`.

```swift
import Vapor // implies import Logging
```

### Standalone

The Logging module, part of the larger Vapor Console package, can also be used on its own with any Swift project.

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
      .target(name: "Project", dependencies: ["Logging", ... ])
    ]
)
```

Use `import Logging` to access the APIs.

## Overview

Continue to [Logging → Overview](overview.md) for an overview of Logging's features.