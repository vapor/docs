# Install on macOS

To use Vapor on macOS, you just need to have Xcode 9.3 or greater installed.

!!! tip
    You need to install Xcode to install Swift, but after that you can use any text editor 
    you like to develop Vapor apps.

## Install Xcode

Install [Xcode 9.3 or greater](https://itunes.apple.com/us/app/xcode/id497799835?mt=12) from the Mac App Store.\*

<img width="1112" alt="Xcode 9.1" src="https://user-images.githubusercontent.com/1342803/32911091-1b55b434-cad9-11e7-8ab2-fbd7ea0084da.png">

!!! warning
    After Xcode has been downloaded, you must open it to finish the installation. This may take a while.

!!! warning
    \*While Xcode 9.3 is still in beta it can only be downloaded from [Apple Developer Download page](https://developer.apple.com/download/). After installation, run the following command in the terminal: `sudo xcode-select -s /Applications/Xcode-beta.app`.

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

Vapor requires Swift 4.1.

## Install Vapor

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
