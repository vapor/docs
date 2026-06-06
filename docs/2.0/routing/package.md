# Using Routing

## With Vapor

This package is included with Vapor by default, just add:

```Swift
import Routing
```

## Without Vapor

Routing providers a performant, pure-Swift router to use in any server-side Swift project. To include it in your package, add the following to your `Package.swift` file.

```Swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .Package(url: "https://github.com/vapor/routing.git", majorVersion: 2)
    ],
    exclude: [ ... ]
)
```

Use `import Routing` to access Routing's APIs
