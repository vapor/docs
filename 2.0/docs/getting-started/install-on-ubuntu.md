# Install on Ubuntu

Installing Vapor on Ubuntu only takes a couple of minutes. 

## APT Repo

Add Vapor's APT repo to get access to all of Vapor's system packages.

### Quick Script

Easily add Vapor's APT repo with this handy script.

```sh
eval "$(curl -sL https://apt.vapor.sh)"
```

### Manual 

Or add the repo manually.

```sh
wget -q https://repo.vapor.codes/apt/keyring.gpg -O- | sudo apt-key add -
echo "deb https://repo.vapor.codes/apt $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/vapor.list
```

## Install Vapor

Now that you have added Vapor's APT repo, you can install the required dependencies.

```sh
sudo apt-get install swift vapor
```

## Verify Installation

Double check the installation was successful by running:

```sh
eval "$(curl -sL check2.vapor.sh)"
```

## Next

Learn more about the Vapor toolbox CLI in the [Toolbox section](toolbox.md) of the Getting Started section.

## Swift.org

Check out [Swift.org](https://swift.org)'s guide to [using downloads](https://swift.org/download/#using-downloads) if you need more detailed instructions for installing Swift 3.1.
