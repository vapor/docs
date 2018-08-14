# Hello, world

Now that you've installed Vapor, let's create your first Vapor app!
This guide will take you step by step through creating a new project, building, and running it.

## New Project

The first step is to create a new Vapor project on your computer.
For this guide, we will call the project `Hello`.

Open up your terminal, and use [Vapor Toolbox's `new`](toolbox.md#new) command.

```sh
vapor new Hello
```

Once that finishes, change into the newly created directory.

```sh
cd Hello
```

## Generate Xcode Project

Let's now use the [Vapor Toolbox's `xcode`](toolbox.md) command to generate an Xcode project.
This will allow us to build and run our app from inside of Xcode, just like an iOS app.

```sh
vapor xcode
```

The toolbox will ask you if you'd like to open Xcode automatically, select `yes`.

## Build & Run

You should now have Xcode open and running. Select the [run scheme](xcode.md#run) from the scheme menu and **My Mac** as the deployment target,
then click the play button.

You should see the terminal pop up at the bottom of the screen.

```sh
Server starting on http://localhost:8080
```

## Visit Localhost

Open your web browser, and visit <a href="http://localhost:8080/hello" target="_blank">localhost:8080/hello &rarr;</a>

You should see the following page.

```html
Hello, world!
```

Congratulations on creating, building, and running your first Vapor app! 🎉
