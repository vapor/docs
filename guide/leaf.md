---
currentMenu: guide-leaf
---

# Leaf

Welcome to Leaf. Leaf's goal is to be a simple templating language that can make generating views easier. There's a lot of great templating languages, use what's best for you, maybe that's Leaf! The goals of Leaf are as follows:

- Small set of strictly enforced rules
- Consistency
- Parser first mentality
- Extensibility

## Syntax
### Structure

Leaf Tags are made up of 4 Elements:
  - Token: `#` is the Token
  - Name: A `string` that identifies the tag
  - Parameter List: `()` May accept 0 or more arguments
  - Body (optional): `{}` Must be separated from the Parameter List by a space

There can be many different usages of these 4 elements depending on the Tag's implementation. Let's look at a few examples of how Leaf's built-in Tags might be used:

  - `#()`
  - `#(variable)`
  - `#import("template")`
  - `#export("link") { <a href="#()"></a> }`
  - `#index(friends, "0")`
  - `#loop(friends, "friend") { <li>#(friend.name)</li> }`
  - `#raw() { <a href="#raw">Anything goes!@#$%^&*</a> }`

### Using the `#` token in HTML

The `#` token cannot be escaped. Use the `#()` or `#raw() {}` Tag to output a `#` in a Leaf Template. `#()` => `#`

### Raw HTML

All Leaf output is escaped by default. Use the `#raw() {}` Tag for unescaped output.
`#raw() { <a href="#link">Link</a> }` => `<a href="#link">Link</a>`
> IMPORTANT!  Make sure you are not using the `#raw() {}` Tag with user input.

### Chaining

The double token: `##` indicates a chain. It can be applied to any standard Tag. If the previous Tag fails, the chained Tag will be given an opportunity to run.

```
#if(hasFriends) ##embed("getFriends")
```

### Leaf's built-in Tags

#### Token: `#()`

```
#() #()hashtags #()FTW => # #Hashtags #FTW
```

#### Raw: `#raw() {}`

```
#raw() {
    Do whatever w/ #'s here, this code won't be rendered as leaf document and is not escaped.
    It's a great place for things like Javascript or large HTML sections.
}
```

#### Equal: `#equal(lhs, rhs) {}`

```
#equal(leaf, leaf) { Leaf == Leaf } => Leaf == Leaf
#equal(leaf, mustache) { Leaf == Mustache } =>
```

#### Variable: `#(variable)`

```
Hello, #(name)!
```

#### Loop: `#loop(object, "index")`

```
#loop(friends, "friend") {
  Hello, #(friend.name)!
}
```
#### Index: `#index(object, _ index: Int|String)`

```
Hello, #index(friends, 0)!
Hello, #index(friends, "best")!
```

#### If - Else: `#if(bool) ##else() { this }`

```
#if(entering) {
  Hello, there!
} ##if(leaving) {
  Goodbye!
} ##else() {
  I've been here the whole time.
}
```

#### Import: `#import("template")`
#### Export: `#export("template") { Leaf/HTML }`
#### Extend: `#extend("template")`
#### Embed: `#embed("template")`

> When using these Layout Tags, omit the template file's .leaf extension.

```
/// base.leaf
<!DOCTYPE html>
#import("html")

/// html.leaf
#extend("base")

#export("html") { <html>#embed("body")</html> }

/// body.leaf
<body></body>
```

Leaf renders `html.leaf` as:

```
<!DOCTYPE html>
<html><body></body></html>
```

### Custom Tags

Look at the existing tags for advanced scenarios, let's look at a basic example by creating `Index` together. This tag will take two arguments, an array, and an index to access.

```swift
class Index: BasicTag {
  let name = "index"

  func run(arguments: [Argument]) throws -> Node? {
    guard
      arguments.count == 2,
      let array = arguments[0].value?.nodeArray,
      let index = arguments[1].value?.int,
      index < array.count
    else { return nil }
        return array[index]
    }
}
```

We can now register this Tag in our `main.swift` file with:

```swift
if let leaf = drop.view as? LeafRenderer {
    leaf.stem.register(Index())
}
```

And use it just like we did [above](#index).

> Note: Use of non-alphanumeric characters in Tag Names is **strongly discouraged** and may be disallowed in future versions of Leaf.

## Syntax Highlighting

### Atom

[language-leaf](https://atom.io/packages/language-leaf) by ButkiewiczP

### Xcode

It is not currently possible to implement Leaf Syntax Highlighting in Xcode, however, using Xcode's HTML Syntax Coloring can help a bit. Select one or more Leaf files and then choose Editor > Syntax Coloring > HTML.  Your selected Leaf files will now use Xcode's HTML Syntax Coloring.  Unfortunately the usefulness of this is limited because this association will be removed when `vapor xcode` is run.

There appears to be a way to [make Xcode file associations persist](http://stackoverflow.com/questions/9050035/how-to-make-xcode-recognize-a-custom-file-extension-as-objective-c-for-syntax-hi) but that requires a bit more kung-fu.

### VS Code

[html-leaf](https://marketplace.visualstudio.com/items?itemName=Francisco.html-leaf) by FranciscoAmado

### CLion & AppCode

Some preliminary work has been done to implement a Leaf Plugin for CLion & AppCode but lack of skill and interest in Java has slowed progress! If you have IntelliJ SDK experience and want to help with this, message Tom Holland on [Vapor Slack](http://vapor.team)
