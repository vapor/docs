# Folder Structure

Now that you've created, built, and run your first Vapor app, let's take a moment to familiarize you with Vapor's folder structure. The structure is based on [SPM](spm.md)'s folder structure, so if you've worked with SPM before it should be familiar. 

```
.
├── Public
├── Sources
│   ├── App
│   │   ├── Controllers
│   │   ├── Migrations
│   │   ├── Models
│   │   ├── configure.swift 
│   │   ├── entrypoint.swift
│   │   └── routes.swift
│       
├── Tests
│   └── AppTests
└── Package.swift
```

The sections below explain each part of the folder structure in more detail.

## Public

This folder contains any public files that will be served by your app if `FileMiddleware` is enabled. This is usually images, style sheets, and browser scripts. For example, a request to `localhost:8080/favicon.ico` will check to see if `Public/favicon.ico` exists and return it.

You will need to enable `FileMiddleware` in your `configure.swift` file before Vapor can serve public files.

```swift
// Serves files from `Public/` directory
let fileMiddleware = FileMiddleware(
    publicDirectory: app.directory.publicDirectory
)
app.middleware.use(fileMiddleware)
```

## Sources

This folder contains all of the Swift source files for your project. 
The top level folder, `App`, reflect your package's module, 
as declared in the [SwiftPM](spm.md) manifest.

### App

This is where all of your application logic goes. 

#### Controllers

Controllers are great way of grouping together application logic. Most controllers have many functions that accept a request and return some sort of response.

#### Migrations

The migrations folder is where your database migrations go if you are using Fluent.

#### Models

The models folder is a great place to store your `Content` structs or Fluent `Model`s.

#### configure.swift

This file contains the `configure(_:)` function. This method is called by `entrypoint.swift` to configure the newly created `Application`. This is where you should register services like routes, databases, providers, and more. 

#### entrypoint.swift

This file contains the `@main` entry point for the application that sets up, configures and runs your Vapor application.

#### routes.swift

This file contains the `routes(_:)` function. This method is called near the end of `configure(_:)` to register routes to your `Application`. 

## Tests

Each non-executable module in your `Sources` folder can have a corresponding folder in `Tests`. This contains code built on the `XCTest` module for testing your package. Tests can be run using `swift test` on the command line or pressing ⌘+U in Xcode. 

### AppTests

This folder contains the unit tests for code in your `App` module.

## Package.swift

Finally is [SPM](spm.md)'s package manifest.

