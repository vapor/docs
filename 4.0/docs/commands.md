# Commands

Vapor's Command API allows you to build custom command-line functions and interact with the terminal. It is what Vapor's default commands like `serve`, `routes`, and `migrate` are built on. 

## Default Commands

You can learn more about Vapor's default commands using the `--help` option. 

```sh
vapor run --help
```

You can use `--help` on a specific command to see what arguments and options it accepts.

```sh
vapor run serve --help
```

### Xcode

You can run commands in Xcode by adding arguments to the `Run` scheme. To do this, follow these steps: 

- Choose `Run` scheme (to the right of play/stop buttons)
- Click "Edit Scheme"
- Choose "Run" product
- Select "Arguments" tab
- Add the name of the command to "Arguments Passed On Launch" (i.e., `serve`)

## Custom Commands

You can create your own commands by creating types conforming to `Command`. 

```swift
import Vapor

struct HelloCommand: Command { 
	...
}
```

Adding the custom command to `app.commands` will make it available via `vapor run`. 

```swift
app.commands.use(HelloCommand(), as: "hello")
```

To conform to `Command`, you must implement the `run` method. This requires declaring a `Signature`. You must also provide default help text.

```swift
import Vapor

struct HelloCommand: Command {
    struct Signature: CommandSignature { }

    var help: String {
        "Says hello"
    }

    func run(using context: CommandContext, signature: Signature) throws {
        context.console.print("Hello, world!")
    }
}
```

This simple command example has no arguments or options, so leave the signature empty.

You can get access to the current console via the supplied context. Console has many helpful methods for prompting user input, output formatting, and more. 

```swift
let name = context.console.ask("What is your \("name", color: .blue)?")
context.console.print("Hello, \(name) 👋")
```

Test your command by running:

```sh
vapor run hello
```

### Cowsay

Take a look at this re-creation of the famous [`cowsay`](https://en.wikipedia.org/wiki/Cowsay) command for an example of using `@Argument` and `@Option`.

```swift
import Vapor

struct Cowsay: Command {
    struct Signature: CommandSignature {
        @Argument(name: "message")
        var message: String

        @Option(name: "eyes", short: "e")
        var eyes: String?

        @Option(name: "tongue", short: "t")
        var tongue: String?
    }

    var help: String {
        "Generates ASCII picture of a cow with a message."
    }

    func run(using context: CommandContext, signature: Signature) throws {
        let eyes = signature.eyes ?? "oo"
        let tongue = signature.tongue ?? "  "
        let cow = #"""
          < $M >
                  \   ^__^
                   \  ($E)\_______
                      (__)\       )\/\
                       $T ||----w |
                          ||     ||
        """#.replacingOccurrences(of: "$M", with: signature.message)
            .replacingOccurrences(of: "$E", with: eyes)
            .replacingOccurrences(of: "$T", with: tongue)
        context.console.print(cow)
    }
}
```

Try adding this to your application and running it.

```swift
app.commands.use(Cowsay(), as: "cowsay")
```

```sh
vapor run cowsay sup --eyes ^^ --tongue "U "
```
