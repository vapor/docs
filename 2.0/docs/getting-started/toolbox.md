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

### Application Commands

The `vapor run` command is a special toolbox command that forwards to your Vapor application.

Once you've built your application with `vapor build` you can use `vapor run serve` to boot your application, or `vapor run help` to view all available application-level commands. This includes custom commands you may have added to your application.

!!! warning
	Using `vapor run --help` will provide information about the `run` command itself and will not forward to your Vapor application.

## Updating

The toolbox should be updated by the package manager it was installed with.

### Homebrew

```sh
brew upgrade vapor
```

### APT

```
sudo apt-get update
sudo apt-get install vapor
```

## Templates

The toolbox can create a project from the Vapor basic-template or any other git repo.

```sh
vapor new <name> [--template]
```

| Name | Flag           | Description                       |
|------|----------------|-----------------------------------|
| API  | --template=api | JSON API with Fluent database.    |
| Web  | --template=web | HTML website with Leaf templates. |

View a list of all [templates](https://github.com/search?utf8=✓&q=topic%3Avapor+topic%3Atemplate&type=Repositories) on GitHub.

!!! note
    If you do not specify a template option, the API template will be used.
    This may change in the future.

### Options

The toolbox will build an absolute URL based on what you pass as the template option. 

- `--template=web` clones `http://github.com/vapor/web-template`
- `--template=user/repo` clones `http://github.com/user/repo`.
- `--template=http://example.com/repo-path` clones the full url given.
- `--branch=foo` can be used to specify a branch besides `master`.

