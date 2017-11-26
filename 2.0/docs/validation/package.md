!!! error "Work in Progress"
    The subject of this page is Work in Progress and is not recommended for Production use.

!!! error "Outdated"
    This page contains outdated information.

# Using Validation

This section outlines how to import the Validation package both with or without a Vapor project.

## With Vapor

The easiest way to use Validation with Vapor is to include the Validation provider. 

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/validation-provider.git", majorVersion: 1)
    ],
    exclude: [ ... ]
)
```

The Validation provider package adds Validation to your project and adds some additional, vapor-specific conveniences like validation middleware. 

Using `import ValidationProvider` will import the Validation middleware and the Validation module. 

## Just Validation

At the core of the Validation provider is a Validation module.

```swift
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .Package(url: "https://github.com/vapor/validation.git", majorVersion: 1)
    ],
    exclude: [ ... ]
)
```

Use `import Validation` to access the core validation class.
