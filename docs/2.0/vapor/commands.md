In addition to the commands provided by Vapor (like `serve`, and `routes`) you can build your own custom commands.

!!! note
    Commands are a great way to script your application with CRON jobs.

## Example
To make a custom console command we must first create a new `.swift` file, import `Vapor` and `Console`, and implement the `Command` protocol.

```swift
import Vapor
import Console

final class MyCustomCommand: Command {
    public let id = "my-command"
    public let help = ["This command does things, like foo, and bar."]
    public let console: ConsoleProtocol
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public func run(arguments: [String]) throws {
        console.print("running custom command...")
    }
}
```

- The **id** property is the string you will type in the console to access the command. `.build/debug/App command` will run the Custom Command.
- The **help** property is the help message that will give your custom command's users some idea of how to access it.
- The **console** property is the object passed to your custom command that adheres to the console protocol, allowing manipulation of the console.
- The **run** method is where you put the logic relating to your command.

## Config Initializable

To make our command configurable, conform it to `ConfigInitializable`

```swift
extension MyCustomCommand: ConfigInitializable {
    public convenience init(config: Config) throws {
        let console = try config.resolveConsole()
        self.init(console: console)
    }
}
```

## Add to Droplet

After we work our magic in the Custom Command file, we switch over to our `main.swift` file and add the custom command to the Droplet like so.

```swift
import Vapor

let config = try Config()
try config.addConfigurable(command: MyCustomCommand.init, name: "my-command")

let drop = try Droplet(config)
```

This allows Vapor access to our custom command and lets it know to display it in the `--help` section of the program.

### Configure

Now that you've made the command configurable, just add it to the `commands` array in your `Config/droplet.json` file.

`Config/droplet.json`
```json
{
    ...,
    "commands": ["my-command"],
    ...,
}
```

After compiling the application we can run our custom command like so.

```
vapor run my-command
```
