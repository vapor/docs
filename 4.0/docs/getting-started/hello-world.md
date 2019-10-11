# Hello, world

This guide will take you step by step through creating a new Vapor project, building it, and running the server.

If you have not yet installed Swift or Vapor Toolbox, check out the install section.

- [Install &rarr; macOS](../install/macos.md)
- [Install &rarr; Ubuntu](../install/ubuntu.md)

## New Project

The first step is to create a new Vapor project on your computer. Open up your terminal and use Toolbox's new project command. This will create a new folder in the current directory containing the project.

```sh
vapor-beta new hello -n
```

!!! tip
	The `-n` flag gives you a bare bones template by automatically answering no to all questions.

Once the command finishes, change into the newly created folder and open Xcode.

```sh
cd hello
open Package.swift
```

## Build & Run

You should now have Xcode open. Click the play button to build and run your project.

You should see the terminal pop up at the bottom of the screen.

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

## Visit Localhost

Open your web browser, and visit <a href="http://localhost:8080/hello" target="_blank">localhost:8080/hello</a>

You should see the following page.

```html
Hello, world!
```

Congratulations on creating, building, and running your first Vapor app! 🎉
