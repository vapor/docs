# Custom Tags

You can create custom Leaf tags using the [`LeafTag`](https://api.vapor.codes/leaf-kit/main/LeafKit/LeafTag) protocol. 

To demonstrate this, let's take a look at creating a custom tag `#now` that prints the current timestamp. The tag will also support a single, optional parameter for specifying the date format.

## `LeafTag`

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

func render(_ ctx: LeafContext) throws -> LeafData {
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
}
```

!!! tip
	If your custom tag renders HTML you should conform your custom tag to `UnsafeUnescapedLeafTag` so the HTML is not escaped. Remember to check or sanitize any user input.

## Configure Tag

Now that we've implemented `NowTag`, we just need to tell Leaf about it. You can add any tag like this - even if they come from a separate package. You do this typically in `configure.swift`:

```swift
app.leaf.tags["now"] = NowTag()
```

And that's it! We can now use our custom tag in Leaf.

```leaf
The time is #now()
```

## Context Properties

The `LeafContext` contains two important properties. `parameters` and `data` that has everything we should need.

- `parameters`: An array that contains the parameters of the tag.
- `data`: A dictionary that contains the data of the view passed to `render(_:_:)` as the context.

### Example Hello Tag

To do see how to use this, let's implement a simple hello tag using both properties.

#### Using Parameters

We can access the first parameter that would contain the name.

```swift
struct HelloTagError: Error {}

public func render(_ ctx: LeafContext) throws -> LeafData {

        guard let name = ctx.parameters[0].string else {
            throw HelloTagError()
        }

        return LeafData.string("<p>Hello \(name)</p>'")
    }
}
```

```leaf
#hello("John")
```

#### Using Data

We can access the name value by using the "name" key inside the data property.

```swift
struct HelloTagError: Error {}

public func render(_ ctx: LeafContext) throws -> LeafData {

        guard let name = ctx.data["name"]?.string else {
            throw HelloTagError()
        }

        return LeafData.string("<p>Hello \(name)</p>'")
    }
}
```

```leaf
#hello()
```

_Controller_:

```swift
return req.view.render("home", ["name": "John"])
```
