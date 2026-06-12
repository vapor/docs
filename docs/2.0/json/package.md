# Using JSON

## With Vapor

This package is included with Vapor by default, just add:

```Swift
import JSON
```

## Without Vapor

JSON provides easy-to-use JSON support for any server-side, or client side Swift project. To include it in your package, add the following to your `Package.swift` file.

```Swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .Package(url: "https://github.com/vapor/json.git", majorVersion: 2)
    ],
    exclude: [ ... ]
)
```

Use `import JSON` to access JSON's APIs
