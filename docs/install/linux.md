# Install on Linux

To use Vapor, you will need Swift 5.6 or greater. This can be installed using the CLI tool [Swiftly](https://swift-server.github.io/swiftly/) provided by the Swift Server Workgroup (reccommended), or the toolchains available on [Swift.org](https://swift.org/download/).

## Supported Distributions and Versions

Vapor supports the same versions of Linux distributions that Swift 5.6 or newer versions supports.

!!! note
    The supported versions listed below may be outdated at any time. You can check which operating systems are officially supported on the [Swift Releases](https://swift.org/download/#releases) page.

|Distribution|Version|Swift Version|
|-|-|-|
|Ubuntu|20.04|>= 5.6|
|Fedora|>= 30|>= 5.6|
|CentOS|8|>= 5.6|
|Amazon Linux|2|>= 5.6|

Linux distributions not officially supported may also run Swift by compiling the source code, but Vapor cannot prove stability. Learn more about compiling Swift from the [Swift repo](https://github.com/apple/swift#getting-started).

## Install Swift

### Automated installation using Swiftly CLI tool (recommended)

Visit the [Swiflty website](https://swift-server.github.io/swiftly/) for instructions on how to install Swiftly and Swift on Linux. After that, install Swift with the following command:

#### Basic usage

```sh
$ swiftly install latest

Fetching the latest stable Swift release...
Installing Swift 5.8.1
Downloaded 488.5 MiB of 488.5 MiB
Extracting toolchain...
Swift 5.8.1 installed successfully!

$ swift --version

Swift version 5.8.1 (swift-5.8.1-RELEASE)
Target: x86_64-unknown-linux-gnu
```

### Manual installation with the toolchain

Visit Swift.org's [Using Downloads](https://swift.org/download/#using-downloads) guide for instructions on how to install Swift on Linux.

### Fedora

Fedora users can simply use the following command to install Swift:

```sh
sudo dnf install swift-lang
```

If you're using Fedora 30, you'll need to add EPEL 8 to get Swift 5.6 or newer versions. 

## Docker

You can also use Swift's official Docker images which come with the compiler preinstalled. Learn more at [Swift's Docker Hub](https://hub.docker.com/_/swift).

## Install Toolbox

Now that you have Swift installed, let's install the [Vapor Toolbox](https://github.com/vapor/toolbox). This CLI tool is not required to use Vapor, but it includes helpful utilities. 

On Linux, you will need to build the toolbox from source. View the toolbox's <a href="https://github.com/vapor/toolbox/releases" target="_blank">releases</a> on GitHub to find the latest version.

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

After you have installed Swift, create your first app in [Getting Started &rarr; Hello, world](../getting-started/hello-world.md).
