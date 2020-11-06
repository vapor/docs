# Leaf

Leaf is a powerful templating language with Swift-inspired syntax. You can use it to generate dynamic HTML pages for a front-end website or generate rich emails to send from an API.

## Package

The first step to using Leaf is adding it as a dependency to your project in your SPM package manifest file.

```swift
// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        /// Any other dependencies ...
        .package(url: "https://github.com/vapor/leaf.git", from: "4.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "Leaf", package: "leaf"),
            // Any other dependencies
        ]),
        // Other targets
    ]
)
```

## Configure

Once you have added the package to your project, you can configure Vapor to use it. This is usually done in [`configure.swift`](../folder-structure.md#configureswift).

```swift
import Leaf

app.views.use(.leaf)
```

## Folder Structure

Once you have configured Leaf, you will need to ensure you have a `Views` folder to store your `.leaf` files in. By default, Leaf expects the views folder to be a `./Resources/Views` relative to your project's root.

You will also likely want to enable Vapor's [`FileMiddleware`](https://api.vapor.codes/vapor/latest/Vapor/Classes/FileMiddleware.html) to serve files from your `/Public` folder. 

```
VaporApp
├── Package.swift
├── Resources
│   ├── Views
│   │   └── hello.leaf
├── Public
│   ├── images (images resources)
│   ├── styles (css resources)
└── Sources
    └── ...
```

## Rendering a View

Now that Leaf is configured, let's render your first template. Inside of the `Resources/Views` folder, create a new file called `hello.leaf` with the following contents:

```leaf
Hello, #(name)!
```

Then, register a route (usually done in `routes.swift` or a controller) to render the view.

```swift
import Leaf

router.get("hello") { req -> Future<View> in
    return try req.view().render("hello", ["name": "Leaf"])
}
```

Open your browser and visit `/hello`. You should see `Hello, Leaf!`. Congratulations on rendering your first Leaf view!
