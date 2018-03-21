# Hello, World

This section assumes you have installed Swift 3.1 and the Vapor Toolbox and have verified they are working.

!!! tip
    Note: If you don't want to use the Toolbox, follow the [manual guide](manual.md).

## New Project

Let's start by creating a new project called "Hello, World".

```sh
vapor new Hello --template=api
```

Vapor's folder structure will probably look familiar to you if you have worked with other web frameworks.

```
Hello
├── Config
│   ├── app.json
│   ├── crypto.json
│   ├── droplet.json
│   ├── fluent.json
│   └── server.json
├── Package.pins
├── Package.swift
├── Public
├── README.md
├── Sources
│   ├── App
│   │   ├── Config+Setup.swift
│   │   ├── Controllers
│   │   │   └── PostController.swift
│   │   ├── Droplet+Setup.swift
│   │   ├── Models
│   │   │   └── Post.swift
│   │   └── Routes
│   │       └── Routes.swift
│   └── Run
│       └── main.swift
├── Tests
│   ├── AppTests
│   │   ├── PostControllerTests.swift
│   │   ├── RouteTests.swift
│   │   └── Utilities.swift
│   └── LinuxMain.swift
├── circle.yml
└── license
```

For our Hello, World project, we will be focusing on the `Routes.swift` file.

```
Hello
└── Sources
    └── App
        └── Routes.swift
```
!!! tip
    The `vapor new` command creates a new project with examples and comments about how to use the framework. You can delete these if you want.

## Code

### Droplet

Look for the following line in the `Routes.swift` file.

```swift
func setupRoutes() throws
```

This method is where all the routes for our application will be added. 

### Routing

In the scope of the `setupRoutes` method, look for the following statement.

```swift
get("plaintext") { req in
    return "Hello, world!"
}
```

This creates a new route that will match all `GET` requests to `/plaintext`.

All route closures are passed an instance of [Request](../http/request.md) that contains information such as the URI requested and data sent.

This route simply returns a string, but anything that is [ResponseRepresentable](../http/response-representable.md) can be returned. Learn more in the [Routing](../routing/overview.md) section of the guide.

!!! tip
    Xcode autocomplete may add extraneous type information to your closure's input arguments. This can be deleted to keep the code clean. If you'd like to keep the type information add `import HTTP` to the top of the file.

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

You should see a message `Server starting...`. 

You can now visit `localhost:8080/plaintext` in your browser or run 

```sh
curl localhost:8080/plaintext
```

!!! note
    Certain port numbers require super user access to bind. Simply run `sudo vapor run` to allow access. If you decide to run on a port besides `80`, make sure to direct your browser accordingly.

### Hello, World

You should see the following output in your browser window.

```
Hello, world!
```

!!! success
    Like Vapor so far? Click the button below and star the repo to help spread the word! 

<iframe src="https://ghbtns.com/github-btn.html?user=vapor&repo=vapor&type=star&count=true&size=large" frameborder="0" scrolling="0" width="160px" height="30px"></iframe>


#### Production

Serving your application in the production environment increases its security and performance.

```sh
vapor run serve --env=production
```

Some debug messages will be silenced while in the production environment, so make sure to check your logs for errors.

!!! warning 
    If you compiled your application with `--release`, make sure to add that flag to the `vapor run` command as well. e.g., `vapor run serve --env=production --release`.

For more information on deploying your code, check out the [deploy section](../deploy/nginx.md).

