# Using Debugging

## With Vapor

This package is included with Vapor by default, just add:

```Swift
import Debugging
```

## Without Vapor

Debugging is a convenient protocol for providing more information about error messages. You can use it in any of your Swift projects.

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .Package(url: "https://github.com/vapor/debugging.git", majorVersion: 1)
    ],
    exclude: [ ... ]
)
```

Use `import Debugging` to access Debugging' APIs.
