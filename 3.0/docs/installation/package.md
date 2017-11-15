# Managing your project

In Server Side Swift, the SPM (Swift Package Manager) is used for managing your project and it's dependencies. At the heart of your project is the `Package.swift` file. This is a file that's written in Swift and is used for defining the dependencies, target projects and other aspects of your project. All of this is expressed in Swift.

## Generate Project

To use Xcode, you will first need to generate a `*.xcodeproj` file.

### Vapor Toolbox

To generate a new Xcode project for a project, use:

```sh
vapor xcode
```

!!! tip
    If you'd like to automatically open the Xcode project, use `vapor xcode -y`

### Select 'Run'

Make sure after generating your Xcode project that you properly select the executable if you're trying to run your application.

<img src="https://cloud.githubusercontent.com/assets/6710841/26517851/72841fd6-426f-11e7-9e6c-945d22933094.png" alt="select 'run' from dropdown" width="300">

### Manual

To generate a new Xcode project manually.

```sh
swift package generate-xcodeproj
```

Open the project and continue normally.

## Changing dependencies

To change dependencies you need to add your `Package.swift` file in the root of your project. The dependency should specify what needs to be added/changed in their readme or documentation.

After changing your `Package.swift` file you'll need to instruct Vapor Toolbox or SPM to update your dependencies.

### Vapor Toolbox

The first step is to update your dependencies.

```sh
vapor update
```

After changing the dependencies you will have to update your xcode project as well.

```sh
vapor xcode
```

### Manual

To manually update your dependencies

```sh
swift package update
```

After updating, you'll need to update your xcode project as well.

```swift
swift packge generate-xcodeproj
```

## Troubleshooting

If you're experiencing issues (after) updating you should try cleaning the project and updating the dependencies.

### Vapor Toolbox

```sh
vapor clean
```

### Manual

```sh
swift package clean
```
