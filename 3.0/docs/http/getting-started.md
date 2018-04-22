# Getting Started with HTTP

HTTP ([vapor/http](https://github.com/vapor/http)) is a non-blocking, event-driven HTTP library built on SwiftNIO. It makes working with SwiftNIO's HTTP handlers easy and offers higher-level functionality like media types, client upgrading, streaming bodies, and more. Creating an HTTP echo server takes just a few lines of code.

!!! tip
    If you use Vapor, most of HTTP's APIs will be wrapped by more convenient methods. Usually the only HTTP type you
    will interact with is the `http` property of `Request` or `Response`.

## Vapor

This package is included with Vapor and exported by default. You will have access to all `HTTP` APIs when you import `Vapor`.

```swift
import Vapor
```

## Standalone

The HTTP package is lightweight, pure Swift, and only depends on SwiftNIO. This means it can be used as an HTTP framework in any Swift project&mdash;even one not using Vapor.

To include it in your package, add the following to your `Package.swift` file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/http.git", from: "3.0.0"),
    ],
    targets: [
      .target(name: "Project", dependencies: ["HTTP", ... ])
    ]
)
```

Use `import HTTP` to access the APIs.

The rest of this guide will give you an overview of what is available in the HTTP package. As always, feel free to visit the [API docs](https://api.vapor.codes/http/latest/HTTP/index.html) for more in-depth information.
