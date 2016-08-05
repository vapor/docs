---
currentMenu: getting-started-install-swift-3
---

# Install Swift 3

This section assumes you have followed the operating system specific instructions for either [macOS](install-swift-3-macos.md) or [Ubuntu](install-swift-3-ubuntu.md).

To use Vapor, you must have Swift 3 installed. Each version of Vapor relies on a single Development Snapshot of Swift 3. Vapor 0.16 relies on `DEVELOPMENT-SNAPSHOT-2016-07-25-a`.

## Swiftenv

[Swiftenv](https://github.com/kylef/swiftenv) allows you to easily install, and switch between multiple versions of Swift.

### Install

Clone the program to your home directory.

```sh
git clone https://github.com/kylef/swiftenv.git ~/.swiftenv
```

Initialize Swiftenv in your Bash profile. 

```sh
export SWIFTENV_ROOT="$HOME/.swiftenv"
export PATH="$SWIFTENV_ROOT/bin:$PATH"
eval "$(swiftenv init -)"
```

> Note: macOS uses `~/.bash_profile` and Ubuntu uses `~/.bashrc`

### Verify

Open a new terminal window and run `swiftenv --version`. You should see something like the following.

```sh
$ swiftenv --version
swiftenv 1.1.0
```

## Download Snapshot

Now that Swiftenv has been installed, the development snapshot of Swift 3 can be downloaded.

```sh
swiftenv install DEVELOPMENT-SNAPSHOT-2016-07-25-a
```

This will download and install the snapshot. You can then make that snapshot globally available as `swift`.

```sh
swiftenv global DEVELOPMENT-SNAPSHOT-2016-07-25-a
```

### Verify

Run `swiftenv versions` to list the versions of Swift 3 installed.

```sh
$ swiftenv versions
* DEVELOPMENT-SNAPSHOT-2016-07-25-a (set by /Users/vapor/.swiftenv/version)
```

## Check

To ensure that your environment has been correctly configured, run the check script.

```sh
curl -sL check.vapor.sh | bash
```
