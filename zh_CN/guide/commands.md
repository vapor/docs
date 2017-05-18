---
currentMenu: guide-commands
---

# Commands

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

在 vapor 上自定义控制台命令是轻而易举的。

## Example
为了创建自定义的控制台命令，我们必须先创建一个新的 `.swift 文件`，`import Vapor` 和 `Console`，并且实现 `Command` 协议。

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

 - **id** 属性是一个字符串，它是你在控制台访问该命令时候输入的内容。`.build/debug/App command` 将会运行这个自定义的命令。
 - **help** 属性是一个帮助信息，将会为你的自定义命令用户提供一些如何使用它的说明及帮助。
 - **console**  属性是一个传入到你的自定义命令中的实现了 console 协议的对象，它允许你操作控制台。
 - **run** 是你放置与你的命令相关逻辑的地方。

在我们在自定义命令文件中写完了我们的逻辑后，我们切换到我们的 `main.swift`,像如下方法添加自定义命令到 `droplet` 中。

```swift
drop.commands.append(MyCustomCommand(console: drop.console))
```

这个允许 vapor 访问我们的自定义命令，并且让它知道在程序的 --help 中显示它。

在编译完成以后，我们可以像下面一样运行我们的自定义命令。

```
.build/debug/App command
```
