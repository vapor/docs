# Install on macOS

To use Vapor on macOS, you just need to have Xcode 9 or greater installed.

!!! tip
    You need to install Xcode to install Swift, but after that you can use any text editor
    you like to develop Vapor apps.

## Install Xcode

Install [Xcode 9 or greater](https://itunes.apple.com/us/app/xcode/id497799835?mt=12) from the Mac App Store.

You can install Xcode 9.3 (currently in beta) or download the latest **Swift 4.1** snapshot for usage with previous Xcode 9 releases at <a href="https://swift.org/download/#swift-41-development" target="_blank">swift.org &rarr;</a>

<img width="1112" alt="Xcode 9.1" src="https://user-images.githubusercontent.com/1342803/32911091-1b55b434-cad9-11e7-8ab2-fbd7ea0084da.png">

!!! warning
    After Xcode has been downloaded, you must open it to finish the installation. This may take a while.

### Verify Installation

Double check the installation was successful by opening Terminal and running:

```sh
swift --version
```

You should see output similar to:

```sh
Apple Swift version 4.1 (swiftlang-902.0.34 clang-902.0.30)
Target: x86_64-apple-darwin17.4.0
```

## Install Vapor

!!! tip
    If you're familiar with SPM and don't need the unique Vapor Toolbox features you can use SPM instead.

Now that you have Swift 4.1, let's install the [Vapor Toolbox](../getting-started/toolbox.md).

The toolbox includes all of Vapor's dependencies as well as a handy CLI tool for creating new projects.

```sh
brew install vapor/tap/vapor
```

!!! tip
    If you don't already have Homebrew installed, install it at <a href="https://brew.sh" target="_blank">brew.sh &rarr;</a>

### Verify Installation

Double check the installation was successful by opening Terminal and running:

```sh
vapor --help
```

You should see a long list of available commands.

## Done

Now that you have installed Vapor, create your first app in [Getting Started &rarr; Hello, world](../getting-started/hello-world.md).
