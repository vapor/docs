# Custom Tags

You can create custom Leaf tags using the [`TagRenderer`](https://api.vapor.codes/template-kit/latest/TemplateKit/Protocols/TagRenderer.html) protocol. 

To demonstrate this, let's take a look at creating a custom tag `#now` that prints the current timestamp. The tag will also support a single, optional parameter for specifying the date format.

## Tag Renderer

First create a class called `NowTag` and conform it to `TagRenderer`.

```swift
final class NowTag: TagRenderer {
    init() { }
    
    func render(tag: TagContext) throws -> EventLoopFuture<TemplateData> {
        ...
    }
}
```

Now let's implement the `render(tag:)` method. The `TagContext` context passed to this method has everything we should need.

```swift
let formatter = DateFormatter()
switch tag.parameters.count {
case 0: formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
case 1:
    guard let string = tag.parameters[0].string else {
        throw ...
    }
    formatter.dateFormat = string
default:
    throw ...
}

let string = formatter.string(from: .init())
return tag.container.future(.string(string))
```

## Configure Tag

Now that we've implemented `NowTag`, we just need to configure it. You can configure any `TagRenderer` like this--even if they come from a separate package.

```swift
services.register { container -> LeafTagConfig in
    var config = LeafTagConfig.default()
    config.use(NowTag(), as: "now")
    return config
}
```

And that's it! We can now use our custom tag in Leaf.

```leaf
The time is #now()
```
