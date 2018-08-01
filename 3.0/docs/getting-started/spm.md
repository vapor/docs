# Managing your project

The Swift Package Manager (SPM for short) is used for building your project's source code and dependencies. 
It's a similar idea to Cocoapods, Ruby gems, and NPM. Most of the time the [Vapor Toolbox](toolbox.md) will 
interact with SPM on your behalf. However, it's important to understand the basics.

!!! tip
    Learn more about SPM on <a href="https://swift.org/package-manager/" target="_blank">Swift.org &rarr;</a> 

## Package Manifest

The first place SPM looks in your project is the package manifest. This should always be located in the root
directory of your project and named `Package.swift`.

### Dependencies

Dependencies are other SPM packages that your package relies on. All Vapor applications rely on the Vapor package,
but you can add as many other dependencies as you want.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "VaporApp",
    dependencies: [
        // 💧 A server-side Swift web framework. 
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0-rc"),
    ],
    targets: [ ... ]
)
```

In the above example, you can see <a href="https://github.com/vapor/vapor" target="_blank">vapor/vapor &rarr;</a> version 3.0
or later is a dependency of this package.
When you add a dependency to your package, you must next signal which [targets](#targets) depend on
the newly available modules.

!!! warning
    Anytime you modify the package manifest, call `vapor update` to effect the changes.

### Targets

Targets are all of the modules, executables, and tests that your package contains. 

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "VaporApp",
    dependencies: [ ... ],
    targets: [
        .target(name: "App", dependencies: ["Vapor"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
```

Most Vapor apps will have three targets, although you can add as many as you like to organize your code.
Each target declares which modules it depends on. You must add module names here in order to `import` them in your code.
A target can depend on other targets in your project or any modules exposed by packages you've added to
the [main dependencies](#dependencies) array.

!!! tip
    Executable targets (targets that contain a `main.swift` file) cannot be imported by other modules.
    This is why Vapor has both an `App` and a `Run` target.
    Any code you include in `App` can be tested in the `AppTests`.

## Folder Structure

Below is the typical folder structure for an SPM package.

```
.
├── Sources
│   ├── App
│   │   └── (Source code)
│   └── Run
│       └── main.swift
├── Tests
│   └── AppTests
└── Package.swift
```

Each `.target` corresponds to a folder in the `Sources` folder. 
Each `.testTarget` corresponds to a folder in the `Tests` folder.

## Troubleshooting

If you are experiencing problems with SPM, sometimes cleaning your project can help.

```sh
vapor clean
```
