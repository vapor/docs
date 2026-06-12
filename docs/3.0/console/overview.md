# Console Overview

This guide will give you a brief introduction to the Console module, showing you how to output stylized text and request user input.

## Terminal

A default implementation of the [`Console`](https://api.vapor.codes/console/latest/Console/Protocols/Console.html) protocol called [`Terminal`](https://api.vapor.codes/console/latest/Console/Classes/Terminal.html) is provided for you to use.

```swift
let terminal = Terminal()
print(terminal is Console) // true
terminal.print("Hello")
```
The rest of this guide will assume a generic `Console`, but using `Terminal`  directly will also work fine.  You can use any available  [`Container`](https://api.vapor.codes/service/latest/Service/Protocols/Container.html) to create a console.

```swift
let console = try req.make(Console.self)
console.print("Hello")
```

## Output

[`Console`](https://api.vapor.codes/console/latest/Console/Protocols/Console.html) provides several convenience methods for outputting strings, like `print(_:)` and `warning(_:)`. All of these methods eventually call `output(_:)` which is the most powerful output method. This method accepts [`ConsoleText`](https://api.vapor.codes/console/latest/Console/Structs/ConsoleText.html) which supports independently styled string components.

```swift
/// Prints "Hello, world", but the word 'world' is blue.
console.output("Hello, " + "world".consoleText(color: .blue))
```

You can combine as many differently styled fragments to a [`ConsoleText`](https://api.vapor.codes/console/latest/Console/Structs/ConsoleText.html) as you like. All [`Console`](https://api.vapor.codes/console/latest/Console/Protocols/Console.html) methods that output text should have an overload for accepting [`ConsoleText`](https://api.vapor.codes/console/latest/Console/Structs/ConsoleText.html).

## Input

[`Console`](https://api.vapor.codes/console/latest/Console/Protocols/Console.html) offers several methods for requesting input from the user, the most basic of which is `input(isSecure:)`.

```swift
/// Accepts input from the terminal until the first newline.
let input = console.input()
console.print("You wrote: \(input)")
```

### Ask

Use `ask(_:)` to supply a prompt and input indicator to the user.

```swift
/// Outputs the prompt then requests input.
let name = console.ask("What is your name?")
console.print("You said: \(name)")
```

The above code will output:

```sh
What is your name?
> Vapor
You said: Vapor
```

### Confirm

Use `confirm(_:)` to prompt the user for yes / no input.

```swift
/// Prompts the user for yes / no input.
if console.confirm("Are you sure?") {
    // they are sure
} else {
    // don't do it!
}
```

The above code will output:

```swift
Are you sure?
y/n> yes
```

!!! note
    `confirm(_:)` will continue to prompt the user until they respond with something recognized as yes or no.
    