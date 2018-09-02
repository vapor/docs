# Install Toolbox

Vapor's command line interface provides shortcuts and assistance for common tasks.

<img width="682" alt="Vapor Toolbox" src="https://cloud.githubusercontent.com/assets/1342803/23553208/26af9a0e-0020-11e7-8ed5-1ce09407ae8e.png">

Help prints useful information about available commands and flags.

```sh
vapor --help
```

You can also run the `--help` option on any Toolbox command.

```sh
vapor new --help
```

The `--help` flag should be your goto for learning about the toolbox as it is the most up-to-date.

## New

The Toolbox's most important feature is helping you create a new project.

```sh
vapor new <name>
```

Just pass the name of your project as the first argument to the `new` command.

!!! note
    Project names should be <a href="http://wiki.c2.com/?PascalCase" target="_blank">PascalCase &rarr;</a>, like `HelloWorld` or `MyProject`.

### Templates

By default, Vapor will create your new project from the API template. You can choose
a different template by passing the `--template` flag.

| Name | Flag             | Description                       |
|------|------------------|-----------------------------------|
| API  | `--template=api` | JSON API with Fluent database.    |
| Web  | `--template=web` | HTML website with Leaf templates. |
| Auth | `--template=auth-template`| JSON API with Fluent DB and Auth. |

!!! info
    There are lots of unofficial Vapor templates on GitHub under the <a href="https://github.com/search?utf8=✓&q=topic%3Avapor+topic%3Atemplate&type=Repositories" target="_blank">`vapor` + `template` topics &rarr;</a>.
    You can use these by passing the full GitHub URL to the `--template` option.

## Build & Run

You can use the toolbox to build and run your Vapor app.

```sh
vapor build
vapor run
```

!!! tip
    We recommend building and running through [Xcode](xcode.md) if you have a Mac. 
    It's a bit faster and you can set breakpoints! 
    Just use `vapor xcode` to generate an Xcode project.

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
