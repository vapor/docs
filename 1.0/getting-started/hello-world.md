---
currentMenu: getting-started-hello-world
---

# Hello, World

This section assumes you have installed Swift 3 and the Vapor Toolbox and have verified they are working.

> Note: If you don't want to use the Toolbox, follow the [manual guide](manual.md).

## New Project

Let's start by creating a new project called Hello, World

```sh
vapor new Hello
```

Vapor's folder structure will probably look familiar to you if you have worked with other web frameworks.

```
Hello
├── Sources
│   └── App
│       └── Controllers
│       └── Middleware
│       └── Models
│       └── main.swift
├── Public
├── Resources
│   └── Views
└── Package.swift
```

For our Hello, World project, we will be focusing on the `main.swift` file.

```
Hello
└── Sources
    └── App
        └── main.swift
```

Note: The `vapor new` command creates a new project with examples and comments about how to use the framework. You can delete these if you want.

## Droplet

Look for the following line in the `main.swift` file.

```swift
let drop = Droplet()
```

This is where the one and only `Droplet `for this example will be created. The `Droplet` class has a plethora of useful functions on it, and is used extensively.

## Routing

Right after the creation of `drop`, add the following code snippet.

```swift
drop.get("hello") { request in
    return "Hello, world!"
}
```

This creates a new route on the `Droplet` that will match all `GET` requests to `/hello`.

All route closures are passed an instance of [Request](../http/request.md) that contains information such as the URI requested and data sent.

This route simply returns a string, but anything that is [ResponseRepresentable](../http/response-representable.md) can be returned. Learn more in the [Routing](../routing/basic.md) section of the guide.

Note: Xcode autocomplete may add extraneous type information to your closure's input arguments. This can be deleted to keep the code clean. If you'd like to keep the type information add `import HTTP` to the top of the file.

## Running

At the bottom of the main file, make sure to serve your `Droplet`.

```swift
drop.run()
```

Save the file, and switch back to the terminal.

## Compiling

A big part of what makes Vapor so great is Swift's state of the art compiler. Let's fire it up. Make sure you are in the root directory of the project and run the following command.

```swift
vapor build
```

Note: `vapor build` runs `swift build` in the background.

The Swift Package Manager will first start by downloading the appropriate dependencies from git. It will then compile and link these dependencies together.

When the process has completed, you will see `Building Project [Done]`

Note: If you see a message like `unable to execute command: Killed`, you need to increase your swap space. This can happen if you are running on a machine with limited memory.

## Run

Boot up the server by running the following command.

```swift
vapor run serve
```

You should see a message `Server starting...`. You can now visit `http://localhost:8080/hello` in your browser.

Note: Certain port numbers require super user access to bind. Simply run `sudo vapor run` to allow access. If you decide to run on a port besides `80`, make sure to direct your browser accordingly.

## Note for sudo usage

On some Linux based systems, you might get an error while using sudo. In that case, if you need to run the server as root, at first switch the user using this command:

```
sudo -i
```
Then either add the previously installed path of Swift to the root users $PATH variable.

```
PATH=$PATH:/your_path_to_swift
# Example command can be like this
# PATH=$PATH:/swift-3.0/usr/bin
# In this case /swift-3.0/usr/bin is the location of my swift installation.

```


## Hello, World

You should see the following output in your browser window.

```
Hello, world!
```
