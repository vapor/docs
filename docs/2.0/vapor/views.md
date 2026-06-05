# Views

Views return HTML data from your application. They can be created from pure HTML documents or passed through renderers such as [Leaf](../leaf/leaf.md).

## Views Directory

Views are stored in `Resources/Views`. They are created by calling the `view` method on `Droplet`.

## HTML

Returning HTML, or any other non-rendered document, is simple. Just use the path of the document relative to the views directory.

```swift
drop.get("html") { request in
    return try drop.view.make("index.html")
}
```

## Templating

Templated documents like [Leaf](../leaf/leaf.md) can take a `Context`.

```swift
drop.get("template") { request in
	return try drop.view.make("welcome", [
		"message": "Hello, world!"
	])
}
```

This context will be rendered in the view dynamically based on the `ViewRenderer` used.

## Public Resources

Any resources that your views need, such as images, styles, and scripts, should be placed in the `Public` folder at the root of your application.

## View Renderer

Any class that conforms to `ViewRenderer` can be added to our droplet. 

```swift
import Vapor
import VaporLeaf

let drop = Droplet()

drop.view = LeafRenderer(viewsDir: drop.viewsDir)
```

## Available Renderers

[Search GitHub](https://github.com/search?utf8=✓&q=topic%3Avapor-provider+topic%3Aviews&type=Repositories) for Vapor view [providers](provider.md) that can be added to your application.
