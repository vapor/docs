# Install Toolbox

Vapor's command line interface provides shortcuts and assistance for common tasks.

<img width="682" alt="Vapor Toolbox" src="https://cloud.githubusercontent.com/assets/1342803/23553208/26af9a0e-0020-11e7-8ed5-1ce09407ae8e.png">

!!! tip
    If you do not want to use the Toolbox or templates, checkout the [Manual](manual.md) quickstart.


## Help

Help prints useful information about available commands and flags. You can also run the `--help` option on any Toolbox command.

```sh
vapor --help
```

## Updating

The toolbox should be updated by the package manager it was installed with.

### Homebrew

```sh
brew upgrade vapor
```

### APT

```
apt-get update
apt-get install vapor
```

## Templates

The toolbox can create a project from the Vapor basic-template or any other git repo.

```sh
vapor new <name> [--template=<repo-url-or-github-path>]
```

### Options

The toolbox will build an absolute URL based on what you pass as the template option. 

- `--template=web` clones `http://github.com/vapor/web-template`
- `--template=user/repo` clones `http://github.com/user/repo`.
- `--template=http://example.com/repo-path` clones the full url given.

!!! note
    If you do not specify a template option, the project will be built from Vapor's [API template](https://github.com/vapor/api-template).
