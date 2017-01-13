---
currentMenu: getting-started-install-toolbox
---

# Install Toolbox

Vapor's command line interface provides shortcuts and assistance for common tasks.

![Vapor Toolbox](https://cloud.githubusercontent.com/assets/1342803/17454691/97e549e2-5b6d-11e6-979a-f0cd6b6f1b0a.png)

> If you do not want to install the Toolbox, checkout the [Manual](manual.md) quickstart.

### Install

Run the following script to install the [Toolbox](https://github.com/vapor/toolbox).

```sh
curl -sL toolbox.vapor.sh | bash
```

> Note: You must have the correct version of Swift 3 installed.

### Verify

Make sure the Toolbox installed successfully by running the help query. You should see a print out of the available commands. You can run the `--help` option on any Toolbox command.

```sh
vapor --help
```
## Create A Project

Now that you have installed the Toolbox, you can create your first Vapor project following the [Hello, World guide](hello-world.md).

### Updating

The toolbox can update itself. This may be useful if you experience any issues in the future.

```sh
vapor self update
```

### Templates

The toolbox can create a project from the Vapor basic-template or any other git repo.

```sh
vapor new <name> [--template=<repo-url-or-github-path>]
```

The toolbox will build an absolute URL based on what you pass as the template option. If you do not specify a template option, the project will be built from the  Vapor basic-template.

```sh
Default(no template option specified) => https://github.com/vapor/basic-template
http(s)://example.com/repo-path => http(s)://example.com/repo-path
user/repo => https://github.com/user/repo
light => https://github.com/vapor/light-template
```
