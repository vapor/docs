# Hello, World

This section assumes you have installed Swift 3.1 and the Vapor Toolbox and have verified they are working.

!!! tip
    Note: If you don't want to use the Toolbox, follow the [manual guide](manual.md).

## New Project

Let's start by creating a new project called "Hello, World".

```sh
vapor new Hello --template=api
```

!!! warning
    Use `vapor new Hello --template=api --branch=beta` while Vapor 2 is in beta

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
!!! tip
    The `vapor new` command creates a new project with examples and comments about how to use the framework. You can delete these if you want.

## Code

### Droplet

Look for the following line in the `main.swift` file.

```swift
let drop = try Droplet()
```

This is where the one and only `Droplet `for this example will be created. The [Droplet](../vapor/droplet.md) class has a plethora of useful functions on it, and is used extensively.

### Routing

Right after the creation of `drop`, add the following code snippet.

```swift
drop.get("hello") { request in
    return "Hello, world!"
}
```

This creates a new route on the `Droplet` that will match all `GET` requests to `/hello`.

All route closures are passed an instance of [Request](../http/request.md) that contains information such as the URI requested and data sent.

This route simply returns a string, but anything that is [ResponseRepresentable](../http/response-representable.md) can be returned. Learn more in the [Routing](../routing/basic.md) section of the guide.

!!! tip
    Xcode autocomplete may add extraneous type information to your closure's input arguments. This can be deleted to keep the code clean. If you'd like to keep the type information add `import HTTP` to the top of the file.

### Serving

At the bottom of the main file, make sure to run your `Droplet`.

```swift
drop.run()
```

Save the file, and switch back to the terminal.

## Compile & Run

### Building

A big part of what makes Vapor so great is Swift's state of the art compiler. Let's fire it up. Make sure you are in the root directory of the project and run the following command.

```swift
vapor build
```

!!! note
    `vapor build` runs `swift build` in the background.

The Swift Package Manager will first start by downloading the appropriate dependencies from git. It will then compile and link these dependencies together.

When the process has completed, you will see `Building Project [Done]`

!!! tip
    If you see a message like `unable to execute command: Killed`, you need to increase your swap space. This can happen if you are running on a machine with limited memory.

#### Release

Building your application in release mode takes longer, but increases performance.

```sh
vapor build --release
```

### Serving

Boot up the server by running the following command.

```sh
vapor run serve
```

You should see a message `Server starting...`. You can now visit `http://localhost:8080/hello` in your browser.

!!! note
    Certain port numbers require super user access to bind. Simply run `sudo vapor run` to allow access. If you decide to run on a port besides `80`, make sure to direct your browser accordingly.

#### Production

Serving your application in the production environment increases its security and performance.

```sh
vapor run serve --env=production
```

Debug errors will be silenced while in the production environment, so make sure to check your logs for errors.

!!! warning 
    If you compiled your application with `--release`, make sure to add that flag to the `vapor run` command as well. e.g., `vapor run serve --env=production --release`.

### Hello, World

You should see the following output in your browser window.

```
Hello, world!
```

!!! success
    Like Vapor so far? Click the button below and star the repo to help spread the word! 

<iframe src="https://ghbtns.com/github-btn.html?user=vapor&repo=vapor&type=star&count=true&size=large" frameborder="0" scrolling="0" width="160px" height="30px"></iframe>

