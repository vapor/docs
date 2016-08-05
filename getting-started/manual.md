---
currentMenu: getting-started-manual
---

# Manual Quickstart

Learn how to create a Vapor project without the Vapor Toolbox using just Swift 3 and the Swift Package Manager.

> If you'd prefer to use the toolbox, learn how to install it [here](install-toolbox.md).

This document assumes that the appropriate version of Swift is installed for Vapor 0.16.

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
mkdir HelloVapor
cd HelloVapor
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
    name: "HelloVapor",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 0, minor: 16)
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

try drop.serve()
```

## Build and Run

The first `build` command can take a while to fetch dependencies.

```
swift build
.build/debug/HelloVapor
```

> If different, replace `HelloVapor` above with the name of your executable.

## View

Go to your favorite browser and visit `http://localhost:8000/hello`
