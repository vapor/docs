# Install on Linux

To use Vapor, you will need Swift 6.4 or greater.
It can be installed using the official installer [Swiftly](https://www.swift.org/install/linux/) (recommended), or the toolchains available on [Swift.org](https://www.swift.org/install/linux/).

## Supported Distributions and Versions

Vapor supports the same versions of Linux distributions that Swift 6.4 or newer versions supports.
Please refer to [Swift.org](https://www.swift.org/install/linux/) in order to find updated information about which operating systems are officially supported.

Linux distributions not officially supported may also run Swift by compiling the source code, but Vapor cannot prove stability.
Learn more about compiling Swift from the [Swift repo](https://github.com/apple/swift#getting-started).

## Install Swift

### Automated installation using Swiftly CLI tool (recommended)

Visit the [Swift website](https://www.swift.org/install/linux/) for instructions on how to install Swiftly and Swift on Linux.
After that, install Swift with the following command:

```sh
$ swiftly install latest
```

Check the installed version with:

```sh
$ swift --version

Swift version 6.4.1 (swift-6.4.1-RELEASE)
Target: x86_64-unknown-linux-gnu
```

### Manual installation with the toolchain

Visit Swift.org's [Alternate Install Options](https://www.swift.org/install/linux/fedora/41/) guide for instructions on how to install Swift on Linux.

## Docker

You can also use Swift's official Docker images which come with the compiler preinstalled. Learn more at [Swift's Docker Hub](https://hub.docker.com/_/swift).

## Install Toolbox

Now that you have Swift installed, let's install the [Vapor Toolbox](https://github.com/vapor/toolbox).
This CLI tool is not required to use Vapor, but it helps to create new Vapor projects.

### Homebrew

The Toolbox is distributed via Homebrew.
If you do not have Homebrew yet, visit <a href="https://brew.sh" target="_blank">brew.sh</a> for install instructions.

```sh
brew install vapor
```

Double check to ensure that the installation was successful by printing help.

```sh
vapor --help
```

You should see a list of available commands.

### Makefile

If you want, you can also build the Toolbox from source.
View the Toolbox's <a href="https://github.com/vapor/toolbox/releases" target="_blank">releases</a> on GitHub to find the latest version.

```sh
git clone https://github.com/vapor/toolbox.git
cd toolbox
git checkout <desired version>
make install
```

Double check the installation was successful by printing help.

```sh
vapor --help
```

You should see a list of available commands.

## Next

Now that you have installed Swift and the Vapor Toolbox, create your first app in [Getting Started &rarr; Hello, world](../getting-started/hello-world.md).
