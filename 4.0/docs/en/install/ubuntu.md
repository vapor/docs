# Install on Ubuntu

To use Vapor on Ubuntu, you will need Swift 5.2 or greater. This can be installed using the toolchains available on [Swift.org](https://swift.org/download/)

## Supported Versions

Vapor supports the same versions of Ubuntu that Swift 5.2 supports.

| Version | Codename          |
|---------|-------------------|
| 18.04   | Bionic Beaver     |
| 16.04   | Xenial Xerus      |

## Installation

Visit Swift.org's [Using Downloads](https://swift.org/download/#using-downloads) guide for instructions on how to install Swift on Linux.

## Docker

You can also use Swift's official Docker images which come with the compiler preinstalled. Learn more at [Swift's Docker Hub](https://hub.docker.com/_/swift).

## Install Toolbox

Now that you have Swift installed, let's install the [Vapor Toolbox](https://github.com/vapor/toolbox). This CLI tool is not required to use Vapor, but it includes helpful utilities. 

On Linux, you will need to build the toolbox from source. View the toolbox's <a href="https://github.com/vapor/toolbox/releases" target="_blank">releases</a> on GitHub to find the latest version.

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

## Next

After you have installed Swift, create your first app in [Getting Started &rarr; Hello, world](../hello-world.md).
