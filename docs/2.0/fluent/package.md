# Using Fluent

This section outlines how to import the Fluent package both with or without a Vapor project.

## With Vapor

Fluent comes included with most Vapor templates. However, if you have created a project from scratch you will need to add the provider to your `Package.swift` file.

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/fluent-provider.git", majorVersion: 1)
    ],
    exclude: [ ... ]
)
```

The Fluent provider package adds Fluent to your project and adds some additional, Vapor-specific conveniences like HTTP conformances. 

Using `import FluentProvider` will import both Fluent and Fluent's Vapor-specific APIs. 

## Without Vapor

Fluent is a powerful, pure-Swift ORM that can be used with any Server-Side Swift framework. To include it in your package, add it to your `Package.swift` file.

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .Package(url: "https://github.com/vapor/fluent.git", majorVersion: 2)
    ],
    exclude: [ ... ]
)
```

Use `import Fluent` to access Fluent's APIs.

!!! warning
    `Model` is a Vapor + Fluent type, use `Entity` instead.

## Drivers

Fluent drivers allow Fluent models and queries to communicate with various database technologies like MySQL or Mongo. For a full list of drivers, check out the [`fluent-driver`](https://github.com/search?utf8=✓&q=topic%3Afluent-driver&type=Repositories) tag on GitHub.
