# Basics

Welcome to Leaf. Leaf's goal is to be a simple templating language that can make generating views easier. There are plenty of great templating languages, so use what's best for you – maybe that's Leaf! The goals of Leaf are:

- Small set of strictly enforced rules
- Consistency
- Parser first mentality
- Extensibility
- Asynchronous and reactive


## Rendering a template

Once you have Leaf installed, you should create a directory called “Resources” inside your project folder, and inside that create another directory called “Views”. This Resources/Views directory is the default location for Leaf templates, although you can change it if you want.

Firstly, import Leaf to routes.swift

```swift
import Leaf
```

Then, to render a basic Leaf template from a route, add this code:

```swift
router.get { req -> Future<View> in
    let leaf = try req.make(LeafRenderer.self)
    let context = [String: String]()
    return try leaf.render("home", context)
}
```

That will load home.leaf in the Resources/Views directory and render it. The `context` dictionary is there to let you provide custom data to render inside the template, but you might find it easier to use codable structs instead because they provide extra type safety. For example:

```swift
struct HomePage: Codable {
    var title: String
    var content: String
}
```

### Async

Leaf's engine is completely reactive, supporting both streams and futures. One of the only ones of its kind.

When working with Future results, simply pass the `Future` in your template context.
Streams that carry an encodable type need to be encoded before they're usable within Leaf.

```swift
struct Profile: Codable {
    var friends: EncodableStream
    var currentUser: Future<User>
}
```

In the above context, the `currentUser` variable in Leaf will behave as being a `User` type. Leaf will not read the user Future if it's not used during rendering.

`EncodableStream` will behave as an array of LeafData, only with lower memory impact and better performance. It is recommended to use `EncodableStream` for (large) database queries.

```
Your name is #(currentUser.name).

#for(friend in friends) {
    #(friend.name) is a friend of you.
}
```

## Template syntax
### Structure

Leaf tags are made up of four elements:

- Token: `#` is the token
- Name: A `string` that identifies the tag
- Parameter List: `()` May accept 0 or more arguments
- Body (optional): `{}` Must be separated from the parameter list by a space

There can be many different usages of these four elements depending on the tag's implementation. Let's look at a few examples of how Leaf's built-in tags might be used:

  - `#()`
  - `#(variable)`
  - `#embed("template")`
  - `#set("title") { Welcome to Vapor }`
  - `#count(friends)`
  - `#for(friend in friends) { <li>#(friend.name)</li> }`


### Working with context

In our Swift example from earlier, we used an empty `[String: String]` dictionary for context, which passes no custom data to Leaf. To try rendering content, use this code instead:

```swift
let context = ["title": "Welcome", "message": "Vapor and Leaf work hand in hand"]
return try leaf.make("home", context)
```

That will expose `title` and `message` to our Leaf template, which can then be used inside tags. For example:

```
<h1>#(title)</h1>
<p>#(message)</p>
```

### Checking conditions

Leaf is able to evaluate a range of conditions using its `#if` tag. For example, if you provide a variable it will check that variable exists in its context:

```
#if(title) {
    The title is #(title)
} else {
    No title was provided.
}
```

You can also write comparisons, for example:

```
#if(title == "Welcome") {
    This is a friendly web page.
} else {
    No strangers allowed!
}
```

If you want to use another tag as part of your condition, you should omit the `#` for the inner tag. For example:

```
#if(lowercase(title) == "welcome") {
    This is a friendly web page.
} else {
    No strangers allowed!
}
```


### Loops

If you provide an array of items, Leaf can loop over them and let you manipulate each item individually using its `#for` tag. For example, we could update our Swift code to provide a list of names in a team:

```swift
let context = ["team": ["Malcolm", "Kaylee", "Jayne"]]
```

We could then loop over them in Leaf like this:

```
#for(name in team) {
    <p>#(name) is in the team.</p>
}
```

Leaf provides some extra variables inside a `#for` loop to give you more information about the loop's progress:

- The `loop.isFirst` variable is true when the current iteration is the first one.
- The `loop.isLast` variable is true when it's the last iteration.
- The `loop.index` variable will be set to the number of the current iteration, counting from 0.


### Embedding templates

Leaf’s `#embed` tag allows you to copy the contents of one template into another. When use this, you should always omit the template file's .leaf extension.

Embedding is useful for copying in a standard piece of content, for example a page footer or advert code:

```
#embed("footer")
```

This tag is also useful for building one template on top of another. For example, you might have a master.leaf file that includes all the code required to lay out your website – HTML structure, CSS and JavaScript – with some gaps in place that represent where page content varies.

Using this approach, you would construct a child template that fills in its unique content, then embeds the parent template that places the content appropriately.

For example, you might create a child.leaf template like this:

```
#set("body") {
<p>Welcome to Vapor!</p>
}

#embed("master")
```

That configures one item of context, `body`, but doesn’t display it directly. Instead, it embeds master.leaf, which can render `body` along with any other context variables passed in from Swift. For example, master.leaf might look like this:

```
<html>
<head><title>#(title)</title></head>
<body>#get(body)</body>
</html>
```

When given the context `["title": "Hi there!"]`, child.leaf will render as follows:

```
<html>
<head><title>Hi there!</title></head>
<body><p>Welcome to Vapor!</p></body>
</html>
```

### Other tags

#### `#capitalize`

The `#capitalize` tag uppercases the first letter of any string. For example, “taylor” will become “Taylor”.

```
#capitalize(name)
```

#### `#contains`

The `#contains` tag accepts an array and a value as its two parameters, and returns true if the array in parameter one contains the value in parameter two. For example, given the array `team`:

```
#if(contains(team, "Jayne")) {
    You're all set!
} else {
    You need someone to do PR.
}
```

#### `#count`

The `#count` tag returns the number of items in an array. For example:

```
Your search matched #count(matches) pages.
```

#### `#lowercase`

The `#lowercase` tag lowercases all letters in a string. For example, “Taylor” will become “taylor”.

```
#lowercase(name)
```

#### `#uppercase`

The `#uppercase` tag uppercases all letters in a string. For example, “Taylor” will become “TAYLOR”.

```
#uppercase(name)
```
