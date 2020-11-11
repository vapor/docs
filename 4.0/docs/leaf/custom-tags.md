# Custom Tags

You can create custom Leaf tags using the [`LeafTag`](https://api.vapor.codes/leaf-kit/latest/LeafKit/LeafSyntax/LeafTag.html) protocol. 

To demonstrate this, let's take a look at creating a custom tag `#now` that prints the current timestamp. The tag will also support a single, optional parameter for specifying the date format.

## Tag Renderer

First create a class called `NowTag` and conform it to `LeafTag`.

```swift
struct NowTag: LeafTag {
    
    func render(_ ctx: LeafContext) throws -> LeafData {
        ...
    }
}
```

Now let's implement the `render(_:)` method. The `LeafContext` context passed to this method has everything we should need.

```swift
struct NowTagError: Error {}

let formatter = DateFormatter()
switch ctx.parameters.count {
case 0: formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
case 1:
    guard let string = ctx.parameters[0].string else {
        throw NowTagError()
    }
    formatter.dateFormat = string
default:
    throw NowTagError()
}

let dateAsString = formatter.string(from: Date())
return LeafData.string(dateAsString)
```

## Configure Tag

Now that we've implemented `NowTag`, we just need to tell Leaf about it. You can add any tag like this - even if they come from a separate package. You do this typically in `configure.swift`:

```swift
app.leaf.tags["now"] = NowTag()
```

And that's it! We can now use our custom tag in Leaf.

```leaf
The time is #now()
```
