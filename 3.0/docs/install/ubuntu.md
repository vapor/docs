# Install on Ubuntu

Installing Vapor on Ubuntu only takes a couple of minutes.

## Supported

Vapor supports the same versions of Ubuntu that Swift supports.

| Version | Codename     |
|---------|--------------|
| 16.10   | Yakkety Yak  |
| 16.04   | Xenial Xerus |
| 14.04   | Trusty Tahr  |

## APT Repo

Add Vapor's APT repo to get access to all of Vapor's Ubuntu packages.

### Quick Script

Easily add Vapor's APT repo with this handy script.

```sh
eval "$(curl -sL https://apt.vapor.sh)"
```

!!! tip
	This command requires `curl` which can be installed using `sudo apt-get install curl`

### Dockerfile
When configuring Ubuntu from a Dockerfile, adding the APT repo can be done via this command:
```sh
RUN /bin/bash -c "$(wget -qO- https://apt.vapor.sh)"
```

### Manual

Or add the repo manually.

```sh
wget -q https://repo.vapor.codes/apt/keyring.gpg -O- | sudo apt-key add -
echo "deb https://repo.vapor.codes/apt $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/vapor.list
sudo apt-get update
```

## Install Vapor

Now that you have added Vapor's APT repo, you can install the required dependencies.

```sh
sudo apt-get install swift vapor
```

### Verify Installation

Double check everything worked with the following commands.

#### Swift

```sh
swift --version
```

You should see output similar to:

```sh
Apple Swift version 4.1.0 (swiftlang-900.0.69.2 clang-900.0.38)
Target: x86_64-apple-macosx10.9
```

Vapor requires Swift 4.1 or greater.

#### Vapor Toolbox

```sh
vapor --help
```

You should see a long list of available commands.

## Done

Now that you have installed Vapor, create your first app in [Getting Started &rarr; Hello, world](../getting-started/hello-world.md).

## Swift.org

Check out [Swift.org](https://swift.org)'s guide to [using downloads](https://swift.org/download/#using-downloads) if you need more detailed instructions for installing Swift 4.1.
