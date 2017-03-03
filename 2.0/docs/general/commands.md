---
currentMenu: guide-commands
---

# Commands
Custom console commands on Vapor are a breeze.

## Example
To make a custom console command we must first create a new `.swift` file, import `Vapor` and `Console`, and implement the `Command` protocol.

```swift
import Vapor
import Console

final class MyCustomCommand: Command {
    public let id = "command"
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

After we work our magic in the Custom Command file, we switch over to our `main.swift` file and add the custom command to the droplet like so.
```swift
drop.commands.append(MyCustomCommand(console: drop.console))
```
This allows Vapor access to our custom command and lets it know to display it in the `--help` section of the program.

After compiling the application we can run our custom command like so.

```
.build/debug/App command
```
