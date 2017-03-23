# Install Toolbox

Vapor's command line interface provides shortcuts and assistance for common tasks.

<img width="682" alt="Vapor Toolbox" src="https://cloud.githubusercontent.com/assets/1342803/23553208/26af9a0e-0020-11e7-8ed5-1ce09407ae8e.png">

!!! tip
    If you do not want to install the Toolbox, checkout the [Manual](manual.md) quickstart.

## Install

Run the following script to install the [Toolbox](https://github.com/vapor/toolbox).

```sh
curl -sL toolbox.vapor.sh | bash
```

!!! warning
    Vapor Toolbox is written in Swift, so you must have Swift 3.1 installed. See the earlier steps of Getting Started for instructions on installing Swift.

### Verify

Make sure the Toolbox installed successfully by running the help query. You should see a print out of the available commands. You can run the `--help` option on any Toolbox command.

```sh
vapor --help
```
## Create A Project

Now that you have installed the Toolbox, you can create your first Vapor project following the [Hello, World guide](hello-world.md).

## Updating

The toolbox can update itself. This may be useful if you experience any issues in the future.

```sh
vapor self update
```

## Templates

The toolbox can create a project from the Vapor basic-template or any other git repo.

```sh
vapor new <name> [--template=<repo-url-or-github-path>]
```

### Options

The toolbox will build an absolute URL based on what you pass as the template option. 

- `--template=light` clones `http://github.com/vapor/light-template`.
- `--template=user/repo` clones `http://github.com/user/repo`.
- `--template=http://example.com/repo-path` clones the full url given.

!!! note
    If you do not specify a template option, the project will be built from Vapor's [basic template](https://github.com/vapor/basic-template).


