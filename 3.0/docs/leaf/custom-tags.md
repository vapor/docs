# Custom Tags

You can extend Leaf to provide your own tags that add custom functionality. To demonstrate this, let's look at a basic example by recreating `#uppercase` together. This tag will take one argument, which is the string to uppercase.

When working with custom tags, there are four important things to know:

1. You should call `requireParameterCount()` with the number of parameters you expect to receive. This will throw an error if your tag is used incorrectly.
2. If you do or do not require a body, you should use either `requireBody()` or `requireNoBody()`. Again, this will throw an error if your tag is used incorrectly.
3. You can read individual parameters using the `parameters` array. Each parameter will be of type `TemplateData`, which you can convert to concrete data types using properties such as `.string`, `.dictionary`, and so on.
4. You must return a `Future<TemplateData>` containing what should be rendered. In the example below we wrap the resulting uppercase string in a `TemplateData` string, then send that back wrapped in a future.

Here’s example code for a `CustomUppercase` Leaf tag:

```swift
import Async
import Leaf

public final class CustomUppercase: TagRenderer {
    public init() {}
    public func render(tag: TagContext) throws -> Future<TemplateData> {
        // ensure we receive precisely one parameter
        try tag.requireParameterCount(1)
        
        // pull out our lone parameter as a string then uppercase it, or use an empty string
        let string = tag.parameters[0].string?.uppercased() ?? ""
        
        // send it back wrapped in a TemplateData
        return Future.map(on: tag) { .string(string) }
    }
}
```

We can now register this Tag in our `configure.swift` file with:

```swift
services.register { container -> LeafTagConfig in
    // take a copy of LeafTagConfig's default
    var leafTagConfig = LeafTagConfig.default()

    // add our custom tag
    leafTagConfig.use(CustomUppercase(), as: "customuppercase")

    // return it
    return leafTagConfig
}
```

Once that is complete, you can use `#customuppercase(some_variable)` to run your custom code.

> Note: Use of non-alphanumeric characters in tag names is **strongly discouraged** and may be disallowed in future versions of Leaf.
