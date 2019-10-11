# Install on macOS

To use Vapor on macOS, you will need Swift 5.1 or greater. Swift and all of its dependencies come bundled with Xcode.

## Install Xcode

Install [Xcode 11 or greater](https://itunes.apple.com/us/app/xcode/id497799835?mt=12) from the Mac App Store.

<img width="1112" alt="Xcode 9.1" src="https://user-images.githubusercontent.com/1342803/32911091-1b55b434-cad9-11e7-8ab2-fbd7ea0084da.png">

After Xcode has been downloaded, you must open it to finish the installation. This may take a while.

Double check the installation was successful by opening Terminal and printing Swift's version.

```sh
swift --version
```

You should see Swift's version information printed.

```sh
Apple Swift version 5.1.0 (swiftlang-900.0.69.2 clang-900.0.38)
Target: x86_64-apple-macosx10.15
```

Vapor 4 requires Swift 5.1 or greater.

## Install Toolbox

Now that you have Swift installed, let's install the [Vapor Toolbox](../getting-started/toolbox.md). This CLI tool is not required to use Vapor, but it includes helpful utilities. 

The toolbox is distributed via Homebrew. If you don't have Homebrew yet, visit <a href="https://brew.sh" target="_blank">brew.sh</a> for install instructions.

```sh
brew install vapor/tap/vapor-beta
```

Double check the installation was successful by printing help.

```sh
vapor-beta --help
```

You should see a list of available commands.

## Next

Now that you have installed Vapor, create your first app in [Getting Started &rarr; Hello, world](../getting-started/hello-world.md).
