---
currentMenu: getting-started-manual
---

# Manual Quickstart

Learn how to create a Vapor project _without_ the Toolbox using just Swift 3 and the Swift Package Manager.

> If you'd prefer to use the Toolbox, learn how to install it [here](install-toolbox.md).

This document assumes that you have Swift 3 installed.

> Note: If you've installed the Toolbox, follow the toolbox guide [here](hello-world.md).

## Check

To check that your environment is compatible, run the following script:

```bash
curl -sL check.vapor.sh | bash
```

## Make new project using SwiftPM

Open your terminal

> For our example, we'll be using the Desktop folder.

```bash
cd ~/Desktop
mkdir Hello
cd Hello
swift package init --type executable
```

Your folder should look like this:

```
├── Package.swift
├── Sources
│   └── main.swift
└── Tests
```

## Edit `Package.swift`

Open your `Package.swift` file:

```bash
open Package.swift
```

And add Vapor as a dependency. Here's how your file will look.

#### Package.swift

```swift
import PackageDescription

let package = Package(
    name: "Hello",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1, minor: 1)
    ]
)
```

> We try to keep this document up to date, however, you can view latest releases [here](https://github.com/vapor/vapor/releases)

## Edit `main.swift`

A simple hello world:

```
import Vapor

let drop = Droplet()

drop.get("/hello") { _ in
  return "Hello Vapor"
}

drop.run()
```

## Build and Run

The first `build` command can take a while to fetch dependencies.

```
swift build
.build/debug/Hello
```

> If different, replace `Hello` above with the name of your executable.

## View

Go to your favorite browser and visit `http://localhost:8080/hello`
