# Getting Started with Command

The Command module is provided as a part of Vapor's Console package ([vapor/console](https://github.com/vapor/console)).  This module provides APIs for creating command-line interfaces (CLIs). It's what powers the [Vapor Toolbox](../getting-started/toolbox.md).

!!! tip
    For an in-depth look at all of Command's APIs, check out the [Command API docs](https://api.vapor.codes/console/latest/Command/index.html).

## Usage

This package is included with Vapor and exported by default. You will have access to all `Command` APIs when you import `Vapor`.

```swift
import Vapor // implies import Command
```

### Standalone

The Command module, part of the larger Vapor Console package, can also be used on its own with any Swift project.

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
      .target(name: "Project", dependencies: ["Command", ... ])
    ]
)
```

Use `import Command` to access the APIs.

## Overview

Continue to [Command → Overview](overview.md) for an overview of Command's features.