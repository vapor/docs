# Install Swift 3.1: Ubuntu

Installing Swift 3.1 on Ubuntu only takes a couple of minutes. 

## Quick

Don't want to type? Run the following script to quickly install Swift 3.1.

```sh
curl -sL swift.vapor.sh/ubuntu | bash
```

!!! note
    The install script adds Swift to your `~/.bashrc` profile automatically.

## Manual

To install manually, you just need to install Swift's dependencies with `apt-get` and download the Swift toolchain.

### Version

Swift 3.1 supports the following Ubuntu versions:

- 14.04 LTS (Trusty Tahr)
- 16.04 LTS (Xenial Xerus)
- 16.10 (Yakkety Yak)

To check which version of Ubuntu you have, run:

```bash
lsb_release -a
```

### Dependencies

Depending on your version of Ubuntu, you may need some additional tools for the compiler. We'll err on the safe side and install everything you should need

```sh
sudo apt-get update
sudo apt-get install clang libicu-dev binutils git libpython2.7-dev libcurl3
```

### Download

Download the Swift 3.1 toolchain for your Ubuntu version.

```sh
# Ubuntu 14.04
wget https://swift.org/builds/swift-3.1-release/ubuntu1404/swift-3.1-RELEASE/swift-3.1-RELEASE-ubuntu14.04.tar.gz

# Ubuntu 16.04
wget https://swift.org/builds/swift-3.1-release/ubuntu1604/swift-3.1-RELEASE/swift-3.1-RELEASE-ubuntu16.04.tar.gz

# Ubuntu 16.10
wget https://swift.org/builds/swift-3.1-release/ubuntu1610/swift-3.1-RELEASE/swift-3.1-RELEASE-ubuntu16.10.tar.gz
```

### Decompress

After Swift has downloaded, decompress it.

```sh
# Ubuntu 14.04
tar zxf swift-3.1-RELEASE-ubuntu14.04.tar.gz

# Ubuntu 16.04
tar zxf swift-3.1-RELEASE-ubuntu16.04.tar.gz

# Ubuntu 16.10
tar zxf swift-3.1-RELEASE-ubuntu16.10.tar.gz
```

### Install

Move Swift 3.1 to a safe, permanent place on your computer. We'll use `/swift-3.1`, but feel free to choose wherever you like.

```sh
# Ubuntu 14.04
mv swift-3.1-RELEASE-ubuntu14.04 /swift-3.1

# Ubuntu 16.04
mv swift-3.1-RELEASE-ubuntu16.04 /swift-3.1

# Ubuntu 16.10
mv swift-3.1-RELEASE-ubuntu16.10 /swift-3.1
```

!!! warning
    You may need to use `sudo`.

### Export

Edit your bash profile using your text editor of choice.

```sh
vim ~/.bashrc
```

Add the following line:

```sh
export PATH=/swift-3.1/usr/bin:"${PATH}"
```

!!! warning
    If you moved Swift 3.1 to a folder other than `/swift-3.1`, your path will be different.

## Check

Double check the installation was successful by running:

```sh
curl -sL check.vapor.sh | bash
```

## Toolbox

You can now move on to [Install Toolbox](install-toolbox.md)

## Swift.org

Check out [Swift.org](https://swift.org)'s guide to [using downloads](https://swift.org/download/#using-downloads) if you need more detailed instructions for installing Swift 3.1.
