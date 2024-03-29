# Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) (SPM) is used for building your project's source code and dependencies. Since Vapor relies heavily on SPM, it's a good idea to understand the basics of how it works.

SPM is similar to Cocoapods, Ruby gems, and NPM. You can use SPM from the command line with commands like `swift build` and `swift test` or with compatible IDEs. However, unlike some other package managers, there is no central package index for SPM packages. SPM instead leverages URLs to Git repositories and versions dependencies using [Git tags](https://git-scm.com/book/en/v2/Git-Basics-Tagging). 

## Package Manifest

The first place SPM looks in your project is the package manifest. This should always be located in the root directory of your project and named `Package.swift`.

Take a look at this example Package manifest.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
```

Each part of the manifest is explained in the following sections.

### Tools Version

The very first line of a package manifest indicates the Swift tools version required. This specifies the minimum version of Swift that the package supports. The Package description API may also change between Swift versions, so this line ensures Swift will know how to parse your manifest. 

### Package Name

The first argument to `Package` is the package's name. If the package is public, you should use the last segment of the Git repo's URL as the name.

### Platforms

The `platforms` array specifies which platforms this package supports. By specifying `.macOS(.v12)` this package requires macOS 12 or later. When Xcode loads this project, it will automatically set the minimum deployment version to macOS 12 so that you can use all available APIs.

### Dependencies

Dependencies are other SPM packages that your package relies on. All Vapor applications rely on the Vapor package, but you can add as many other dependencies as you want.

In the above example, you can see [vapor/vapor](https://github.com/vapor/vapor) version 4.76.0 or later is a dependency of this package. When you add a dependency to your package, you must next signal which [targets](#targets) depend on
the newly available modules.

### Targets

Targets are all of the modules, executables, and tests that your package contains. Most Vapor apps will have two targets, although you can add as many as you like to organize your code. Each target declares which modules it depends on. You must add module names here in order to import them in your code. A target can depend on other targets in your project or any modules exposed by packages you've added to
the [main dependencies](#dependencies) array.

## Folder Structure

Below is the typical folder structure for an SPM package.

```
.
├── Sources
│   └── App
│       └── (Source code)
├── Tests
│   └── AppTests
└── Package.swift
```

Each `.target` or `.executableTarget` corresponds to a folder in the `Sources` folder. 
Each `.testTarget` corresponds to a folder in the `Tests` folder.

## Package.resolved

The first time you build your project, SPM will create a `Package.resolved` file that stores the version of each dependency. The next time you build your project, these same versions will be used even if newer versions are available. 

To update your dependencies, run `swift package update`.

## Xcode

If you are using Xcode 11 or greater, changes to dependencies, targets, products, etc will happen automatically whenever the `Package.swift` file is modified. 

If you want to update to the latest dependencies, use File &rarr; Swift Packages &rarr; Update To Latest Swift Package Versions.

You may also want to add the `.swiftpm` file to your `.gitignore`. This is where Xcode will store your Xcode project configuration.
