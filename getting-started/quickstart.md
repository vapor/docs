---
currentMenu: getting-started-quick-start
---

# Vapor Quickstart

This document assumes that the appropriate version of Swift is installed for Vapor. Right now, this is visible on the [vapor](https://github.com/qutheory/vapor#-environment) section of the repository.

You can run the following to check compatibility:

```bash
curl -sL check.qutheory.io | bash
```

> If you'd prefer to use our built in tool, you can find information [here](install-toolbox.md)

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

```Swift
import PackageDescription

let package = Package(
    name: "HelloVapor",
    dependencies: [
        .Package(url: "https://github.com/qutheory/vapor.git", majorVersion: 0, minor: 15)
    ]
)
```

> We try to keep this document up to date, however, you can view latest releases [here](https://github.com/qutheory/vapor/releases)

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
