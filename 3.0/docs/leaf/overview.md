# Leaf Overview

Leaf is a powerful templating language with Swift-inspired syntax. You can use it to generate dynamic HTML pages for a front-end website or generate rich emails to send from an API.

This guide will give you an overview of Leaf's syntax and the available tags.

## Template syntax

Here is an example of a basic Leaf tag usage.

```leaf
There are #count(users) users. 
```

Leaf tags are made up of four elements:

- Token `#`: This signals the leaf parser to begin looking for a tag.
- Name `count`: that identifies the tag.
- Parameter List `(users)`: May accept zero or more arguments.
- Body: An optional body can be supplied to some tags. This is similar to Swift's trailing-closure syntax.

There can be many different usages of these four elements depending on the tag's implementation. Let's look at a few examples of how Leaf's built-in tags might be used:

```leaf
#(variable)
#embed("template")
#set("title") { Welcome to Vapor }
#count(friends)
#for(friend in friends) { <li>#(friend.name)</li> }
```

Leaf also supports many expressions you are familiar with in Swift. 

- `+`
- `>`
- `==`
- `||`
- etc.

```leaf
#if(1 + 1 == 2) {
    Hello!
}
```

## Context

In the example from [Getting Started](./getting-started.md), we used a `[String: String]` dictionary to pass data to Leaf. However, you can pass anything that conforms to `Encodable`. It's actually preferred to use `Encodable` structs since `[String: Any]` is not supported.

```swift
struct WelcomeContext: Encodable {
    var title: String
    var number: Int
}
return try req.view().make("home", WelcomeContext(title: "Hello!", number: 42))
```

That will expose `title` and `message` to our Leaf template, which can then be used inside tags. For example:

```leaf
<h1>#(title)</h1>
<p>#(number)</p>
```

## Usage

Here are some common Leaf usage examples.

### Conditions

Leaf is able to evaluate a range of conditions using its `#if` tag. For example, if you provide a variable it will check that variable exists in its context:

```leaf
#if(title) {
    The title is #(title)
} else {
    No title was provided.
}
```

You can also write comparisons, for example:

```leaf
#if(title == "Welcome") {
    This is a friendly web page.
} else {
    No strangers allowed!
}
```

If you want to use another tag as part of your condition, you should omit the `#` for the inner tag. For example:

```leaf
#if(lowercase(title) == "welcome") {
    This is a friendly web page.
} else {
    No strangers allowed!
}
```

Just like in Swift, you can also use `else if` statement.s

```leaf
#if(title == "Welcome") {
    This is a friendly web page.
} else if (1 == 2) {
    What?
} else {
    No strangers allowed!
}
```

### Loops

If you provide an array of items, Leaf can loop over them and let you manipulate each item individually using its `#for` tag. 

For example, we could update our Swift code to provide a list of planets:

```swift
struct SolarSystem: Codable {
    let planets = ["Venus", "Earth", "Mars"]
}

return try req.view().render(..., SolarSystem())
```

We could then loop over them in Leaf like this:

```leaf
Planets:
<ul>
#for(planet in planets) {
    <li>#(planet)</li>
}
</ul>
```

This would render a view that looks like:

```
Planets:
- Venus
- Earth
- Mars
```

Leaf provides some extra variables inside a `#for` loop to give you more information about the loop's progress:

- The `isFirst` variable is true when the current iteration is the first one.
- The `isLast` variable is true when it's the last iteration.
- The `index` variable will be set to the number of the current iteration, counting from 0.

Here's how we could use a loop variable to print just the first name in our array:

```leaf
#for(planet in planets) {
    #if(isFirst) { #(planet) is first! }
}
```

### Embedding templates

Leaf’s `#embed` tag allows you to copy the contents of one template into another. When use this, you should always omit the template file's .leaf extension.

Embedding is useful for copying in a standard piece of content, for example a page footer or advert code:

```leaf
#embed("footer")
```

This tag is also useful for building one template on top of another. For example, you might have a master.leaf file that includes all the code required to lay out your website – HTML structure, CSS and JavaScript – with some gaps in place that represent where page content varies.

Using this approach, you would construct a child template that fills in its unique content, then embeds the parent template that places the content appropriately.

For example, you might create a child.leaf template like this:

```leaf
#set("body") {
    <p>Welcome to Vapor!</p>
}

#embed("master")
```

That configures one item of context, `body`, but doesn’t display it directly. Instead, it embeds master.leaf, which can render `body` along with any other context variables passed in from Swift. For example, master.leaf might look like this:

```leaf
<html>
    <head>
        <title>#(title)</title>
    </head>
    <body>#get(body)</body>
</html>
```

When given the context `["title": "Hi there!"]`, child.leaf will render as follows:

```html
<html>
    <head>
        <title>Hi there!</title>
    </head>
    <body><p>Welcome to Vapor!</p></body>
</html>
```

### Comments

You can write single or multiline comments with Leaf. They will be discarded when rendering the view.

```leaf
#// Say hello to the user
Hello, #(name)!
```

Multi-line comments are opened with `#/*` and closed with `*/`.

```leaf
#/*
     Say hello to the user
*/
Hello, #(name)!
```

### Other tags

#### `#date`

The `#date` tag formats dates into a readable string.

```swift
render(..., ["now": Date()])
```

```leaf
The time is #date(now)
```

You can pass a custom date formatter string as the second argument. See Swift's [`DateFormatter`](https://developer.apple.com/documentation/foundation/dateformatter) for more information.

```leaf
The date is #date(now, "yyyy-MM-dd")
```

#### `#capitalize`

The `#capitalize` tag uppercases the first letter of any string.

```leaf
#capitalize(name)
```

#### `#contains`

The `#contains` tag accepts an array and a value as its two parameters, and returns true if the array in parameter one contains the value in parameter two.

```leaf
#if(contains(planets, "Earth")) {
    Earth is here!
} else {
    Earth is not in this array.
}
```

#### `#count`

The `#count` tag returns the number of items in an array. For example:

```leaf
Your search matched #count(matches) pages.
```

#### `#lowercase`

The `#lowercase` tag lowercases all letters in a string. 

```leaf
#lowercase(name)
```

#### `#uppercase`

The `#uppercase` tag uppercases all letters in a string.

```leaf
#uppercase(name)
```
