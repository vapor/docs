---
currentMenu: guide-views
---

# Views

Views return HTML data from your application. They can be created from pure HTML documents or passed through renderers such as Mustache or Stencil.

## Views Directory

Views are stored in `Resources/Views`. They are created by calling the `view` method on `Droplet`.

## HTML

Returning HTML, or any other non-rendered document, is simple. Just use the path of the document relative to the views directory.

```swift
drop.get("html") { request in
    return try drop.view("index.html")
}
```

## Templating

Templated documents like mustache or stencil templates can take a `Context`.

```swift
drop.get("template") { request in
	return try drop.view("index.template", [
		"message": "Hello, world!"
	])
}
```

## Public Resources

Any resources that your views need, such as images, styles, and scripts, should be placed in the `Public` folder at the root of your application.

## View Renderer

Any class that conforms to `ViewRenderer` can be set to render views with a given context.

```swift
class MustacheRenderer: RenderDriver {
    ...
}

View.renderers[".mustache"] = MustacheRenderer()
```

## Available Renderers

These renderers can be added to your application through Providers.

- [Mustache](https://github.com/vapor/mustache-provider)
- [Stencil](https://github.com/vapor/stencil-provider)