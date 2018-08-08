# Leaf

Leaf is a powerful templating language with Swift-inspired syntax. You can use it to generate dynamic HTML pages for a front-end website or generate rich emails to send from an API.

## Package

The first step to using Leaf is adding it as a dependency to your project in your SPM package manifest file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Any other dependencies ...
        .package(url: "https://github.com/vapor/leaf.git", from: "3.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: ["Leaf", ...]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
```

## Configure

Once you have added the package to your project, you can configure Vapor to use it. This is usually done in [`configure.swift`](../getting-started/structure.md#configureswift).

```swift
import Leaf

try services.register(LeafProvider())
```

If your application supports multiple view renderers, you may need to specify that you would like to use Leaf.

```swift
config.prefer(LeafRenderer.self, for: ViewRenderer.self)
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

## Syntax Highlighting

You may also wish to install one of these third-party packages that provide support for syntax highlighting in Leaf templates.

### Sublime

Install the package [Leaf](https://packagecontrol.io/packages/Leaf) from package control.

### Atom

[language-leaf](https://atom.io/packages/language-leaf) by ButkiewiczP

### Xcode

It is not currently possible to implement Leaf Syntax Highlighting in Xcode, however, using Xcode's HTML Syntax Coloring can help a bit. Select one or more Leaf files and then choose Editor > Syntax Coloring > HTML.  Your selected Leaf files will now use Xcode's HTML Syntax Coloring.  Unfortunately the usefulness of this is limited because this association will be removed when `vapor xcode` is run.

There appears to be a way to [make Xcode file associations persist](http://stackoverflow.com/questions/9050035/how-to-make-xcode-recognize-a-custom-file-extension-as-objective-c-for-syntax-hi) but that requires a bit more kung-fu.

### VS Code

[html-leaf](https://marketplace.visualstudio.com/items?itemName=Francisco.html-leaf) by FranciscoAmado

### CLion & AppCode

Some preliminary work has been done to implement a Leaf Plugin for CLion & AppCode but lack of skill and interest in Java has slowed progress! If you have IntelliJ SDK experience and want to help with this, message Tom Holland on [Vapor Slack](http://vapor.team)

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
