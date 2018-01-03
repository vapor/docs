# Install on macOS

To use Vapor on macOS, you just need to have Xcode 8 or later installed.

## Install Xcode

Install [Xcode 9](https://itunes.apple.com/us/app/xcode/id497799835?mt=12) from the Mac App Store.

[![Xcode 9](https://cloud.githubusercontent.com/assets/1342803/18537674/2ddd8e9c-7ad5-11e6-9bc2-7155d57d20ec.png)](https://itunes.apple.com/us/app/xcode/id497799835?mt=12)

(Xcode 8 is the minimum required to use Vapor 2.0 on macOS. If you have an Apple Developer membership you can download older versions of Xcode from Apple's developer [downloads page](https://developer.apple.com/download/more/))

### Open Xcode

After Xcode has been downloaded, you must open it to finish the installation. This may take a while.

## Verify Swift Installation

Double check the installation was successful by opening Terminal and running:

```sh
eval "$(curl -sL check.vapor.sh)"
```

## Install Vapor

Now that you have Swift 4 (or Swift 3.1 if you installed Xcode 8), let's install the Vapor toolbox. 

The toolbox includes all of Vapor's dependencies as well as a handy CLI tool for creating new projects.

### Install Homebrew

If you don't already have Homebrew installed, install it! It's incredibly useful for installing software dependencies like OpenSSL, MySQL, Postgres, Redis, SQLite, and more.

```sh
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

For more information on installing Homebrew, visit [brew.sh](https://brew.sh).

### Add Homebrew Tap

Vapor's Homebrew tap will give your Homebrew installation access to all of Vapor's macOS packages.

```sh
brew tap vapor/homebrew-tap
brew update
```

### Install

Now that you've added Vapor's tap, you can install Vapor's toolbox and dependencies.

```sh
brew install vapor
```

### Upgrade

If you've previously installed Vapor upgrades to Homebrew and Vapor may be required to work with the latest versions of macOS, Swift, or the instructions in this guide.

```sh
brew update
brew upgrade vapor
```

## Next

Learn more about the Vapor toolbox CLI in the [Toolbox section](toolbox.md) of the Getting Started section.

## Swift.org

Check out [Swift.org](https://swift.org)'s extensive guides if you need more detailed instructions for installing Swift.
