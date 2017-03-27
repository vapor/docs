# Install Swift 3.1: macOS

To use Swift 3.1 on macOS, you just need to have Xcode 8 installed.

## Install Xcode

Install [Xcode 8](https://itunes.apple.com/us/app/xcode/id497799835?mt=12) from the Mac App Store.

[![Xcode 8](https://cloud.githubusercontent.com/assets/1342803/18537674/2ddd8e9c-7ad5-11e6-9bc2-7155d57d20ec.png)](https://itunes.apple.com/us/app/xcode/id497799835?mt=12)

### Open Xcode

After Xcode 8 has been downloaded, you must open it to finish the installation. This may take a while.

## Verify Swift Installation

Double check the installation was successful by running:

```sh
eval "$(curl -sL check2.vapor.sh)"
```

## Install TLS

Vapor 2.+ requires a TLS library like OpenSSL or LibreSSL to be installed and linked. This gives you the option to choose which security library you would like to use and helps ensure your app behaves similarly across macOS and Linux.

### OpenSSL (Recommended)

Installing OpenSSL is the easiest way to get up and running with Vapor.

This quick start script will guide you through the installation process.

```sh
eval "$(curl -sL openssl.vapor.sh)"
```

### LibreSSL / Other (Advanced)

To use a different TLS library, install the library to your computer (through `brew` or downloading from the site). Once the library is installed, you can link it during `swift build` using:

```sh
swift build -Xswiftc -I/path/to/headers -Xlinker -L/path/to/libs
```

This method should work with any OpenSSL alternative that implements the methods required by Vapor's [TLS](https://github.com/vapor/tls) and [Crypto](https://github.com/vapor/crypto) packages.

#### Homebrew LibreSSL

As a concrete example, here is how you can use LibreSSL with Vapor. First, install LibreSSL through Homebrew.

```sh
brew install libressl
```

Then link LibreSSL against your Vapor project when building.

```sh
swift build -Xswiftc -I/usr/local/opt/libressl/include -Xlinker -L/usr/local/opt/libressl/lib
```

## Toolbox

You can now move on to [Install Toolbox](install-toolbox.md).

## Swift.org

Check out [Swift.org](https://swift.org)'s extensive guides if you need more detailed instructions for installing Swift 3.1.
