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
- Body: An optional body can be supplied to some tags using a semicolon and a closing tag

There can be many different usages of these four elements depending on the tag's implementation. Let's look at a few examples of how Leaf's built-in tags might be used:

```leaf
#(variable)
#extend("template"): I'm added to a base template! #endextend
#export("title"): Welcome to Vapor #endexport
#import("body")
#count(friends)
#for(friend in friends): <li>#(friend.name)</li> #endfor
```

Leaf also supports many expressions you are familiar with in Swift.

- `+`
- `%`
- `>`
- `==`
- `||`
- etc.

```leaf
#if(1 + 1 == 2):
    Hello!
#endif

#if(index % 2 == 0):
    This is even index.
#else:
    This is odd index.
#endif
```

## Context

In the example from [Getting Started](getting-started.md), we used a `[String: String]` dictionary to pass data to Leaf. However, you can pass anything that conforms to `Encodable`. It's actually preferred to use `Encodable` structs since `[String: Any]` is not supported. This means you *can not* pass in an array, and should instead wrap it in a struct:

```swift
struct WelcomeContext: Encodable {
    var title: String
    var numbers: [Int]
}
return req.view.render("home", WelcomeContext(title: "Hello!", numbers: [42, 9001]))
```

That will expose `title` and `numbers` to our Leaf template, which can then be used inside tags. For example:

```leaf
<h1>#(title)</h1>
#for(number in numbers):
    <p>#(number)</p>
#endfor
```

## Usage

Here are some common Leaf usage examples.

### Conditions

Leaf is able to evaluate a range of conditions using its `#if` tag. For example, if you provide a variable it will check that variable exists in its context:

```leaf
#if(title):
    The title is #(title)
#else:
    No title was provided.
#endif
```

You can also write comparisons, for example:

```leaf
#if(title == "Welcome"):
    This is a friendly web page.
#else:
    No strangers allowed!
#endif
```

If you want to use another tag as part of your condition, you should omit the `#` for the inner tag. For example:

```leaf
#if(count(users) > 0):
    You have users!
#else:
    There are no users yet :(
#endif
```

You can also use `#elseif` statements:

```leaf
#if(title == "Welcome"):
    Hello new user!
#elseif(title == "Welcome back!"):
    Hello old user
#else:
    Unexpected page!
#endif
```

### Loops

If you provide an array of items, Leaf can loop over them and let you manipulate each item individually using its `#for` tag.

For example, we could update our Swift code to provide a list of planets:

```swift
struct SolarSystem: Codable {
    let planets = ["Venus", "Earth", "Mars"]
}

return req.view.render("solarSystem", SolarSystem())
```

We could then loop over them in Leaf like this:

```leaf
Planets:
<ul>
#for(planet in planets):
    <li>#(planet)</li>
#endfor
</ul>
```

This would render a view that looks like:

```
Planets:
- Venus
- Earth
- Mars
```

### Extending templates

Leaf’s `#extend` tag allows you to copy the contents of one template into another. When using this, you should always omit the template file's .leaf extension.

Extending is useful for copying in a standard piece of content, for example a page footer, advert code or table that's shared across multiple pages:

```leaf
#extend("footer")
```

This tag is also useful for building one template on top of another. For example, you might have a layout.leaf file that includes all the code required to lay out your website – HTML structure, CSS and JavaScript – with some gaps in place that represent where page content varies.

Using this approach, you would construct a child template that fills in its unique content, then extends the parent template that places the content appropriately. To do this, you can use the `#export` and `#import` tags to store and later retrieve content from the context.

For example, you might create a `child.leaf` template like this:

```leaf
#extend("master"):
    #export("body"):
        <p>Welcome to Vapor!</p>
    #endexport
#endextend
```

We call `#export` to store some HTML and make it available to the template we're currently extending. We then render `master.leaf` and use the exported data when required along with any other context variables passed in from Swift. For example, `master.leaf` might look like this:

```leaf
<html>
    <head>
        <title>#(title)</title>
    </head>
    <body>#import("body")</body>
</html>
```

Here we are using `#import` to fetch the content passed to the `#extend` tag. When passed `["title": "Hi there!"]` from Swift, `child.leaf` will render as follows:

```html
<html>
    <head>
        <title>Hi there!</title>
    </head>
    <body><p>Welcome to Vapor!</p></body>
</html>
```

### Other tags

#### `#count`

The `#count` tag returns the number of items in an array. For example:

```leaf
Your search matched #count(matches) pages.
```

#### `#lowercased`

The `#lowercased` tag lowercases all letters in a string.

```leaf
#lowercased(name)
```

#### `#uppercased`

The `#uppercased` tag uppercases all letters in a string.

```leaf
#uppercased(name)
```

#### `#capitalized`

The `#capitalized` tag uppercases the first letter in each word of a string and lowercases the others. See [`String.capitalized`](https://developer.apple.com/documentation/foundation/nsstring/1416784-capitalized) for more information.

```leaf
#capitalized(name)
```

#### `#contains`

The `#contains` tag accepts an array and a value as its two parameters, and returns true if the array in parameter one contains the value in parameter two.

```leaf
#if(contains(planets, "Earth")):
    Earth is here!
#else:
    Earth is not in this array.
#endif
```

#### `#date`

The `#date` tag formats dates into a readable string. By default it uses ISO8601 formatting.

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

#### `#unsafeHTML`

The `#unsafeHTML` tag acts like a variable tag - e.g. `#(variable)`. However it does not escape any HTML that `variable` may contain:

```leaf
The time is #unsafeHTML(styledTitle)
```

!!! note 
    You should be careful when using this tag to ensure that the variable you provide it does not expose your users to an XSS attack.
