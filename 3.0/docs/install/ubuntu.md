# Install on Ubuntu

Installing Vapor on Ubuntu only takes a couple of minutes.

## Supported

Vapor supports the same versions of Ubuntu that Swift supports.

| Version | Codename          |
|---------|-------------------|
| 18.10   | Cosmic Cuttlefish |
| 18.04   | Bionic Beaver     |
| 16.10   | Yakkety Yak       |
| 16.04   | Xenial Xerus      |
| 14.04   | Trusty Tahr       |

## Installation

Visit Swift.org's [Using Downloads](https://swift.org/download/#using-downloads) guide for instructions on how to install Swift on Linux.

Double check the Swift installation was successful by printing the version.

```sh
swift --version
```

You should see output similar to:

```sh
Apple Swift version 4.1.0 (swiftlang-900.0.69.2 clang-900.0.38)
Target: x86_64-apple-macosx10.9
```

## Docker

You can also use Swift's official Docker images which come with the compiler preinstalled. Learn more at [Swift's Docker Hub](https://hub.docker.com/_/swift).

## Install Toolbox

Now that you have Swift installed, let's install the [Vapor Toolbox](https://github.com/vapor/toolbox). This CLI tool is not required to use Vapor, but it includes helpful utilities. 

On Linux, you will need to build the toolbox from source. View the toolbox's <a href="https://github.com/vapor/toolbox/releases" target="_blank">releases</a> on GitHub to find the latest version.

!!! warning
    Vapor 3 compatible versions of the toolbox are semver major 3.

```sh
git clone https://github.com/vapor/toolbox.git
cd toolbox
git checkout <desired version>
swift build -c release --disable-sandbox
mv .build/release/vapor /usr/local/bin
```

Double check the installation was successful by printing help.

```sh
vapor --help
```

You should see a list of available commands.

## Done

Now that you have installed Vapor, create your first app in [Getting Started &rarr; Hello, world](../getting-started/hello-world.md).

## Swift.org

Check out [Swift.org](https://swift.org)'s guide to [using downloads](https://swift.org/download/#using-downloads) if you need more detailed instructions for installing Swift 4.1.
