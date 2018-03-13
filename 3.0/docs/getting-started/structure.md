# Structure

This section explains the structure of a typical Vapor application to help get
you familiar with where things go.

## Folder Structure

Vapor's folder structure builds on top of [SPM's folder structure](spm#folder-structure).

```
.
├── Public
├── Sources
│   ├── App
│   │   ├── Controllers
│   │   ├── Models
│   │   ├── boot.swift
│   │   ├── configure.swift
│   │   └── routes.swift
│   └── Run
│       └── main.swift
├── Tests
│   └── AppTests
└── Package.swift
```

Let's take a look at what each of these folders and files does.

## Public

This folder contains any public files that will be served by your app.
This is usually images, style sheets, and browser scripts.

Whenever Vapor responds to a request, it will first check if the requested
item is in this folder. If it is, it skips your application logic and returns
the file immediately.

For example, a request to `localhost:8080/favicon.ico` will check to see
if `Public/favicon.ico` exists. If it does, Vapor will return it.

## Sources

This folder contains all of the Swift source files for your project. 
The top level folders (`App` and `Run`) reflect your package's modules, 
as declared in the [package manifest](spm#targets).

### App

This is the most important folder in your application, it's where all of
the application logic goes!

#### Controllers

Controllers are great way of grouping together application logic. Most controllers
have many functions that accept a request and return some sort of response.

!!! tip
	Vapor supports, but does not enforce the MVC pattern

#### Models

The `Models` folder is a great place to store your [`Content`](content.md) structs or
Fluent [`Model`](../fluent/models.md)s.

#### boot.swift

This file contains a function that will be called _after_ your application has booted,
but _before_ it has started running. This is a great place do things that should happen 
every time your application starts.

You have access to the [`Application`](application.md) here which you can use to create
any [services](application.md#services) you might need.

#### configure.swift

This file contains a function that receives the config, environment, and services for your
application as input. This is a great place to make changes to your config or register 
[services](application.md#services) to your application.

#### routes.swift

This file contains a function for adding routes to your router.

You will notice there's one example route in there that returns the "hello, world" response we saw earlier.

You can create as many methods as you want to further organize your code. Just make sure to call them in this main route collection. 

## Tests

Each non-executable module in your `Sources` folder should have a corresponding `...Tests` folder.

### AppTests

This folder contains the unit tests for code in your `App` module. 
Learn more about testing in [Testing &rarr; Getting Started](../testing/getting-started.md).

## Package.swift

Finally is SPM's [package manifest](spm.md#package-manifest).