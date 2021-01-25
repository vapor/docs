# Hello, world

This guide will take you step by step through creating a new Vapor project, building it, and running the server.

If you have not yet installed Swift or Vapor Toolbox, check out the install section.

- [Install &rarr; macOS](install/macos.md)
- [Install &rarr; Linux](install/linux.md)

## New Project

The first step is to create a new Vapor project on your computer. Open up your terminal and use Toolbox's new project command. This will create a new folder in the current directory containing the project.

```sh
vapor new hello -n
```

!!! tip
	The `-n` flag gives you a bare bones template by automatically answering no to all questions.

Once the command finishes, change into the newly created folder and open Xcode.

```sh
cd hello
open Package.swift
```

## Linux Development

If you are working on Linux, consider to add an empty file called `LinuxMain.swift` under the `Sources/Tests/` folder. This allows the [Language Server Protocol](https://github.com/apple/sourcekit-lsp) included in your Swift toolchain to works properly, and if you are working on an editor that supports it, you can have a better development experience.

## Xcode Dependencies

You should now have Xcode open. It will automatically begin downloading Swift Package Manager dependencies.

At the top of the window, to the right of the Play and Stop buttons, click on your project name to select the project's Scheme, and select an appropriate run target—most likely, "My Mac".

## Build & Run

Once the Swift Package Manager dependencies have finished downloading, click the play button to build and run your project.

You should see the Console pop up at the bottom of the Xcode window.

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

## Visit Localhost

Open your web browser, and visit <a href="http://localhost:8080/hello" target="_blank">localhost:8080/hello</a> or <a href="http://127.0.0.1:8080" target="_blank">http://127.0.0.1:8080</a>

You should see the following page.

```html
Hello, world!
```

Congratulations on creating, building, and running your first Vapor app! 🎉
