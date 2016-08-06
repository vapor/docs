---
currentMenu: getting-started-install-toolbox
---

# Install Toolbox

Vapor's command line interface provides shortcuts and assistance for commons tasks.

![Vapor Toolbox](https://cloud.githubusercontent.com/assets/1342803/17454691/97e549e2-5b6d-11e6-979a-f0cd6b6f1b0a.png)

> If you do not want to install the Toolbox, checkout the [Manual](manual.md) quickstart.

## Install

Run the following script to install the [Toolbox](https://github.com/vapor/toolbox).

```sh
curl -sL toolbox.vapor.sh | bash
```

> Note: You must have the correct version of Swift 3 installed.

## Verify

Make sure the Toolbox installed successfully by running the help query. You should see a print out of the available commands. You can run the `--help` option on any Toolbox command.

```sh
vapor --help
```

## Updating

The toolbox can update itself. This may be useful if you experience any issues in the future.

```sh
vapor self update
```