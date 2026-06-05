# Using Leaf

This section outlines how to import the Leaf package both with or without a Vapor project.

## Example Folder Structure

```
Hello
├── Config
│   ├── app.json
│   ├── crypto.json
│   ├── droplet.json
│   ├── fluent.json
│   └── server.json
├── Package.pins
├── Package.swift
├── Public
├── README.md
├── Resources
│   ├── Views
│   │   │   └── hello.leaf
├── Public
│   ├── images (images resources)
│   ├── styles (css resources) 
├── Sources
│   ├── App
│   │   ├── Config+Setup.swift
│   │   ├── Controllers
│   │   │   └── PostController.swift
│   │   ├── Droplet+Setup.swift
│   │   ├── Models
│   │   │   └── Post.swift
│   │   └── Routes.swift
│   └── Run
│       └── main.swift
├── Tests
│   ├── AppTests
│   │   ├── PostControllerTests.swift
│   │   ├── RouteTests.swift
│   │   └── Utilities.swift
│   └── LinuxMain.swift
├── circle.yml
└── license
```

## With Vapor

The easiest way to use Leaf with Vapor is to include the Leaf provider. 

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/leaf-provider.git", majorVersion: 1)
    ],
    exclude: [ ... ]
)
```

The Leaf provider package adds Leaf to your project and adds some additional, Vapor-specific conveniences like `drop.stem()`. 

Use `import LeafProvider`.

## Just Leaf

At the core of the Leaf provider is a fast, pure Swift templating engine. You can use it with any of your Swift packages or server-side Swift applications.

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .Package(url: "https://github.com/vapor/leaf.git", majorVersion: 2)
    ],
    exclude: [ ... ]
)
```

Use `import Leaf` to access the `Leaf.Stem` class.
