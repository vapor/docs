# Using Bits

## With Vapor

This package is included with Vapor by default, just add:

```Swift
import Bits
```

## Without Vapor

Bits provides a lot of byte-manipulation conveniences for any server-side Swift project. To include it in your package, add the following to your `Package.swift` file.

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .Package(url: "https://github.com/vapor/bits.git", majorVersion: 1)
    ],
    exclude: [ ... ]
)
```

Use `import Bits` to access Bits' APIs.