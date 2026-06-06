# Leaf

Leaf is a powerful templating language with Swift-inspired syntax. You can use it to generate dynamic HTML pages for a front-end website or generate rich emails to send from an API.

## Package

The first step to using Leaf is adding it as a dependency to your project in your SPM package manifest file.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        /// Any other dependencies ...
        .package(url: "https://github.com/vapor/leaf.git", from: "4.4.0"),
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

Once you have added the package to your project, you can configure Vapor to use it. This is usually done in [`configure.swift`](../getting-started/folder-structure.md#configureswift).

```swift
import Leaf

app.views.use(.leaf)
```

This tells Vapor to use the `LeafRenderer` when you call `req.view` in your code.

!!! warning 
    For Leaf to be able to find the templates when running from Xcode, you must set the [custom working directory](../getting-started/xcode.md#custom-working-directory) for you Xcode workspace.

### Cache for Rendering Pages

Leaf has an internal cache for rendering pages. When the `Application`'s environment is set to `.development`, this cache is disabled, so that changes to templates take effect immediately. In `.production` and all other environments, the cache is enabled by default. Any changes made to templates will not take effect until the application is restarted.

To disable Leaf's cache do the following:

```swift
app.leaf.cache.isEnabled = false
```

!!! warning
    While disabling cache is helpful for debugging, it's not recommended for production environments as it can significantly impact performance due to the need to recompile templates on every request.

## Folder Structure

Once you have configured Leaf, you will need to ensure you have a `Views` folder to store your `.leaf` files in. By default, Leaf expects the views folder to be a `./Resources/Views` relative to your project's root.

You will also likely want to enable Vapor's [`FileMiddleware`](https://api.vapor.codes/vapor/documentation/vapor/filemiddleware) to serve files from your `/Public` folder if you plan on serving Javascript and CSS files for instance.

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

!!! tip
    If you're using VSCode as your code editor, we recommend installing the Vapor extension to enable syntax highlighting: [Vapor for VS Code](https://marketplace.visualstudio.com/items?itemName=Vapor.vapor-vscode).

Then, register a route (usually done in `routes.swift` or a controller) to render the view.

```swift
app.get("hello") { req -> EventLoopFuture<View> in
    return req.view.render("hello", ["name": "Leaf"])
}

// or

app.get("hello") { req async throws -> View in
    return try await req.view.render("hello", ["name": "Leaf"])
}
```

This uses the generic `view` property on `Request` instead of calling Leaf directly. This allows you to switch to a different renderer in your tests.


Open your browser and visit `/hello`. You should see `Hello, Leaf!`. Congratulations on rendering your first Leaf view!
