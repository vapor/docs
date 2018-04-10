# Getting Started with Template Kit

Template Kit ([vapor/template-kit](https://github.com/vapor/template-kit)) is a framework for implementing templating languages in Swift. It is currently used to power Leaf ([vapor/leaf](https://github.com/vapor/leaf)) and hopefully more languages in the future.

Template Kit is designed to make implementing a templating language easy by defining a common template structure and handling the entire serialization step.

!!! warning
	These docs are for developers interested in implementing a templating language using Template Kit. See [Leaf &rarr; Getting Started](../leaf/getting-started.md) for information about using Leaf.

## Vapor

This package is included with Vapor and exported by default. You will have access to all `TemplateKit` APIs when you import `Vapor`.

```swift
import Vapor
```

## Standalone

The Template Kit package is lightweight, pure-Swift, and has very few dependencies. This means it can be used as a templating framework for any Swift project&mdash;even one not using Vapor.

To include it in your package, add the following to your `Package.swift` file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/template-kit.git", from: "1.0.0"),
    ],
    targets: [
      .target(name: "Project", dependencies: ["TemplateKit", ... ])
    ]
)
```

Use `import TemplateKit` to access the APIs.


## Overview

Let's take a look at how Leaf uses Template Kit to render views.

Assume we have a template `greeting.leaf` with the following contents:

```leaf
Hello, #capitalize(name)!
```

This first step in rendering this view is to parse the syntax into an abstract syntax tree (AST). This is the part of view rendering that Leaf is responsible for, since Leaf has a unique syntax.

Leaf does this by creating a `LeafParser` that conforms to [`TemplateParser`](https://api.vapor.codes/template-kit/latest/TemplateKit/Protocols/TemplateParser.html). 


```
greeting.leaf -> LeafParser -> AST
```

In code, this looks like:

```swift
func parse(scanner: TemplateByteScanner) throws -> [TemplateSyntax]
```

The AST for our example `greeting.leaf` file would look something like this:

```swift
[
	.raw(data: "Hello. "), 
	.tag(
		name: "capitalize", 
		parameters: [.identifier("name")]
	),
	.raw(data: "!"), 
]
```

Now that Leaf has created an AST, it's job is done! Template Kit will handle converting this AST into a rendered view. All it needs is a `TemplateData` to use for filling in any variables.

```swift
let data = TemplateData.dictionary(["name": "vapor"])
```

The above data will be combined with the AST and used by the [`TemplateSerializer`](https://api.vapor.codes/template-kit/latest/TemplateKit/Classes/TemplateSerializer.html) to create a rendered view.

```
AST + Data -> TemplateSerializer -> View
```

Our rendered view will look something like:

```html
Hello, Vapor!
```

All of these steps are handled by `LeafRenderer` which conforms to [`TemplateRenderer`](https://api.vapor.codes/template-kit/latest/TemplateKit/Protocols/TemplateRenderer.html). A template renderer is simply an object that contains both a parser and a serializer. When you implement one, you will get several helpful extensions from Template Kit for free that help load files and cache parsed ASTs. It's what the end user will use to render views.

The entire pipeline looks like this:

```
                            LeafRenderer
                                 |
|----------------------------------------------------------------|
 greeting.leaf -> LeafParser -> AST -> TemplateSerializer -> View
 								 ^
 								/
 				   TemplateData
```

In code, the [method](https://api.vapor.codes/template-kit/latest/TemplateKit/Protocols/TemplateRenderer.html#/s:11TemplateKit0A8RendererPAAE6renderXeXeF) looks like this:

```swift
public func render(_ path: String, _ context: TemplateData) -> Future<View>
```

Check out Template Kit's [API docs](https://api.vapor.codes/template-kit/latest/TemplateKit/index.html) for detailed information about all of the protocols, structs, and classes Template Kit offers.


