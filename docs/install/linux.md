# Install on Linux

To use Vapor, you will need Swift 5.2 or greater. This can be installed using the toolchains available on [Swift.org](https://swift.org/download/)

## Supported Distributions and Versions

Vapor supports the same versions of Linux distributions that Swift 5.2 or newer versions supports.

!!! note
    The supported versions listed below may be outdated at any time. You can check which operating systems are officially supported on the [Swift Releases](https://swift.org/download/#releases) page.

|Distribution|Version|Swift Version|
|-|-|-|
|Ubuntu|16.04, 18.04|>= 5.2|
|Ubuntu|20.04|>= 5.2.4|
|Fedora|>= 30|>= 5.2|
|CentOS|8|>= 5.2.4|
|Amazon Linux|2|>= 5.2.4|

Linux distributions not officially supported may also run Swift by compiling the source code, but Vapor cannot prove stability. Learn more about compiling Swift from the [Swift repo](https://github.com/apple/swift#getting-started).

## Install Swift

Visit Swift.org's [Using Downloads](https://swift.org/download/#using-downloads) guide for instructions on how to install Swift on Linux.

### Fedora

Fedora users can simply use the following command to install Swift:

```sh
sudo dnf install swift-lang
```

If you're using Fedora 30, you'll need to add EPEL 8 to get Swift 5.2 or newer versions. 

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

After you have installed Swift, create your first app in [Getting Started &rarr; Hello, world](../hello-world.md).
