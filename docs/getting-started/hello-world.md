# Hello, world

This guide will take you step by step through creating a new Vapor project, building it, and running the server.

If you have not yet installed Swift or Vapor Toolbox, check out the install section.

- [Install &rarr; macOS](../install/macos.md)
- [Install &rarr; Linux](../install/linux.md)

## New Project

The first step is to create a new Vapor project on your computer. Open up your terminal and use Toolbox's new project command. This will create a new folder in the current directory containing the project.

```sh
vapor new hello -n
```

!!! tip
	The `-n` flag gives you a bare bones template by automatically answering no to all questions.

!!! tip
	Vapor and the template now uses `async`/`await` by default.
	If you cannot update to macOS 12 and/or need to continue to use `EventLoopFuture`s, 
	use flag `--branch macos10-15`.

Once the command finishes, change into the newly created folder:


```sh
cd hello
``` 

## Build & Run

### Xcode

First, open the project in Xcode:

```sh
open Package.swift
```

It will automatically begin downloading Swift Package Manager dependencies. This can take some time the first time you open a project. When dependency resolution is complete Xcode will populate the available schemes. 

At the top of the window, to the right of the Play and Stop buttons, click on your project name to select the project's Scheme, and select an appropriate run target—most likely, "My Mac". Click the play button to build and run your project.

You should see the Console pop up at the bottom of the Xcode window.

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

### Linux

On Linux and other OSes (and even on macOS if you don't want to use Xcode) you can edit the project in your favorite editor of choice, such as Vim or VSCode. See the [Swift Server Guides](https://github.com/swift-server/guides/blob/main/docs/setup-and-ide-alternatives.md) for up to date details on setting up other IDEs.

To build and run your project, in Terminal run:

```sh
swift run
```

That will build and run the project. The first time you run this it will take some time to fetch and resolve the dependencies. Once running you should see the following in your console:

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

## Visit Localhost

Open your web browser, and visit <a href="http://localhost:8080/hello" target="_blank">localhost:8080/hello</a> or <a href="http://127.0.0.1:8080/hello" target="_blank">http://127.0.0.1:8080/hello</a>

You should see the following page.

```html
Hello, world!
```

Congratulations on creating, building, and running your first Vapor app! 🎉
