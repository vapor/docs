---
currentMenu: getting-started-install-swift-3-ubuntu
---

# Install Swift 3: Ubuntu

Installing Swift 3 on Ubuntu only takes a couple of minutes. 

## Quick

Don't want to type? Run the following script to quickly install Swift 3.0.

```sh
curl -sL swift.vapor.sh/ubuntu | bash
```

> Note: The install script adds Swift to your `~/.bashrc` profile automatically.

## Manual

### Dependencies

Depending on your version of Ubuntu, you may need some additional tools for the compiler. We'll err on the safe side and install everything you should need

```sh
sudo apt-get update
sudo apt-get install clang libicu-dev binutils git libpython2.7-dev libcurl3
```

### Download

Download the Swift 3 toolchain for your Ubuntu version.

```sh
# Ubuntu 14.04
wget https://swift.org/builds/swift-3.0-release/ubuntu1404/swift-3.0-RELEASE/swift-3.0-RELEASE-ubuntu14.04.tar.gz

# Ubuntu 15.10
wget https://swift.org/builds/swift-3.0-release/ubuntu1510/swift-3.0-RELEASE/swift-3.0-RELEASE-ubuntu15.10.tar.gz
```

### Decompress

After Swift 3 has downloaded, decompress it.

```sh
# Ubuntu 14.04
tar zxf swift-3.0-RELEASE-ubuntu14.04.tar.gz

# Ubuntu 15.10
tar zxf swift-3.0-RELEASE-ubuntu15.10.tar.gz
```

### Install

Move Swift 3.0 to a safe, permanent place on your computer. We'll use `/swift-3.0`, but feel free to choose wherever you like.

```sh
# Ubuntu 14.04
mv swift-3.0-RELEASE-ubuntu14.04 /swift-3.0

# Ubuntu 15.10
mv swift-3.0-RELEASE-ubuntu15.10 /swift-3.0
```

> Note: You may need to use `sudo`.

### Export

Edit your bash profile using your text editor of choice.

```sh
vim ~/.bashrc
```

Add the following line:

```sh
export PATH=/swift-3.0/usr/bin:"${PATH}"
```

> Note: If you moved Swift 3.0 to a folder other than `/swift-3.0`, your path will be different.

## Check

Double check the installation was successful by running:

```sh
curl -sL check.vapor.sh | bash
```

## Toolbox

You can now move on to [Install Toolbox](install-toolbox.md)

## Swift.org

Check out [Swift.org](https://swift.org)'s extensive guides if you need more detailed instructions for installing Swift 3.0.