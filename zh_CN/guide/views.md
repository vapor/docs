---
currentMenu: guide-views
---

# Views

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

Views 从你的程序中返回 HTML 数据。它们可以从一个 HTML 文档被创建，或者通过 Mustache、 Stencil 被渲染创建。

## Views Directory

Views 被放在 `Resources/Views` 目录。通过在 `Droplet` 调用 `view` 方法可以创建它们。

## HTML

返回 HTML 或者其他不需要渲染的文档是很简单的。只需要使用文档相对于 views 目录的路径即可。

```swift
drop.get("html") { request in
    return try drop.view.make("index.html")
}
```

## 模板 （Templating）

像 [Leaf](./leaf.html)、 Mustache、 Stencil 这样的模板文档可以获得一个 `Context`。

```swift
drop.get("template") { request in
	return try drop.view.make("welcome", [
		"message": "Hello, world!"
	])
}
```

## Public Resources

任何你的 vewis 需要的资源，例如图片、样式、脚本（images, styles, scripts）都需要被防止在你的应用的根目录的 `Public` 文件夹中。

## View Renderer

任何实现了 `ViewRenderer` 协议的类都可以被添加到我们的 droplet 中。

```swift
let drop = Droplet()

drop.view = LeafRenderer(viewsDir: drop.viewsDir)
```

## Available Renderers

这些 Renderer 可以通过 Providers 添加到你的程序中。

- [Leaf](https://github.com/vapor/leaf)
- [Mustache](https://github.com/vapor/mustache-provider)
