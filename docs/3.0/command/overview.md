# Command Overview

This guide will introduce you to the Command module by showing you how to create your own CLI. For this example, we will implement [`cowsay`](https://en.wikipedia.org/wiki/Cowsay), a command that prints an ASCII picture of a cow with a message.

!!! tip
    You can install the real `cowsay` program using `brew install cowsay`.

```sh
$ cowsay Hello
  -----
< Hello >
  -----
          \   ^__^
           \  (oo\_______
              (__)\       )\/\
                   ||----w |
                   ||     ||
```

## Command

The first step is to create a type that conforms to [`Command`](https://api.vapor.codes/console/latest/Command/Protocols/Command.html).

```swift
/// Generates ASCII picture of a cow with a message.
struct CowsayCommand: Command {
    ...
}
```

Now let's implement the required methods.

### Arguments

Commands can have zero or more [`CommandArgument`](https://api.vapor.codes/console/latest/Command/Structs/CommandArgument.html)s. These arguments will be required for the command to run.

```swift
/// Generates ASCII picture of a cow with a message.
struct CowsayCommand: Command {
    /// See `Command`
    var arguments: [CommandArgument] {
        return [.argument(name: "message")]
    }
    
    ...
}
```

Here we are defining one argument, the `message` that the cow will say. This is required to run the `cowsay` command.

### Options

Commands can have zero or more [`CommandOption`](https://api.vapor.codes/console/latest/Command/Structs/CommandOption.html)s. These options are not required for the command to run and can be passed using `--` or `-` syntax.

```swift
/// Generates ASCII picture of a cow with a message.
struct CowsayCommand: Command {
    ...
    /// See `Command`
    var options: [CommandOption] {
        return [
            .value(name: "eyes", short: "e", default: "oo", help: ["Change cow's eyes"]),
            .value(name: "tongue", short: "t", default: " ", help: ["Change cow's tongue"]),
        ]
    }
    ...
}
```

Here we are defining two options, `eyes` and `tongue`. These will let the user optionally change how the cow looks.

### Help

Next we can define an optional help message to display when the user passes `--help`.

```swift
/// Generates ASCII picture of a cow with a message.
struct CowsayCommand: Command {
    ...
    /// See `Command`
    var help: [String] {
        return ["Generates ASCII picture of a cow with a message."]
    }
    ...
}
```

Let's take a look at how this will look once our command is complete:

```sh
Usage: <executable> cowsay <message> [--eyes,-e] [--tongue,-t] 

Generates ASCII picture of a cow with a message.

Arguments:
  message n/a

Options:
     eyes Change cow's eyes
   tongue Change cow's tongue
```

### Run

Finally, we need to write our implementation:

```swift
/// Generates ASCII picture of a cow with a message.
struct CowsayCommand: Command {
    ...
    
    /// See `Command`.
    func run(using context: CommandContext) throws -> Future<Void> {
        let message = try context.argument("message")
        /// We can use requireOption here since both options have default values
        let eyes = try context.requireOption("eyes")
        let tongue = try context.requireOption("tongue")
        let padding = String(repeating: "-", count: message.count)
        let text: String = """
          \(padding)
        < \(message) >
          \(padding)
                  \\   ^__^
                   \\  (\(eyes)\\_______
                      (__)\\       )\\/\\
                        \(tongue)  ||----w |
                           ||     ||
        """
        context.console.print(text)
        return .done(on: context.container)
    }
}
```

The [`CommandContext`](https://api.vapor.codes/console/latest/Command/Structs/CommandContext.html) gives you access to everything you will need, including a `Container`. Now that we have a complete `Command`, the next step is to configure it.

## Config

Use the [`CommandConfig`](https://api.vapor.codes/console/latest/Command/Structs/CommandConfig.html) struct to register commands to your container. This is usually done in [`configure.swift`](../getting-started/structure.md#configureswift)

```swift
/// Create a `CommandConfig` with default commands.
var commandConfig = CommandConfig.default()
/// Add the `CowsayCommand`.
commandConfig.use(CowsayCommand(), as: "cowsay")
/// Register this `CommandConfig` to services.
services.register(commandConfig)
```

Check that your command was properly configured using `--help`.

```swift
swift run Run cowsay --help
```

That's it!

```swift
$ swift run Run cowsay 'Good job!' -e ^^ -t U
  ---------
< Good job! >
  ---------
          \   ^__^
           \  (^^\_______
              (__)\       )\/\
                U  ||----w |
                   ||     ||
```