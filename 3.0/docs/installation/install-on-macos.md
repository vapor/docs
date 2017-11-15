# Install on macOS

If you're on a Mac, you can develop your Vapor 3 project using Xcode 9 or greater.
You can build, run, and stop your server from within Xcode, as well as use breakpoints and instruments to debug your code.

<img width="1072" alt="screen shot 2017-05-15 at 7 14 48 pm" src="https://cloud.githubusercontent.com/assets/1342803/26072406/4d74dfca-39a3-11e7-98c7-d9a678d3fe17.png">

To use Vapor on macOS, you just need to have Xcode 9 or greater installed.

## Install Xcode

Install [Xcode 9 or greater](https://itunes.apple.com/us/app/xcode/id497799835?mt=12) from the Mac App Store.

[![Xcode 8](https://cloud.githubusercontent.com/assets/1342803/18537674/2ddd8e9c-7ad5-11e6-9bc2-7155d57d20ec.png)](https://itunes.apple.com/us/app/xcode/id497799835?mt=12)

### Open Xcode

After Xcode has been downloaded, you must open it to finish the installation. This may take a while.

## Verify Swift Installation

Double check the installation was successful by opening Terminal and running:

```sh
eval "$(curl -sL check.vapor.sh)"
```

## Install Vapor

Now that you have Swift 4, let's install the Vapor toolbox.

The toolbox includes all of Vapor's dependencies as well as a handy CLI tool for creating new projects.

### Install Homebrew

If you don't already have Homebrew installed, install it! It's incredibly useful for installing software dependencies like MySQL, Postgres, MongoDB, Redis and more.

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

## Next

We have more detailed information about managing your project and dependencies [here](package.md).
