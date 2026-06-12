# 指令

Vapor 的 Command API 允许你打造自定义命令行函数并且与终端进行交互。Vapor的默认指令，例如 `serve`, `routes` 和 `migrate`, 都是通过这个 Api 实现的。

## 默认指令

通过 `--help` 选项你可以了解更多 Vapor 的默认指令。

```sh
swift run App --help
```

你同样可以使用 `--help` 在特定的指令上以查看这个指令接受的参数和选项。

```sh
swift run App serve --help
```

### Xcode

你可以通过加入参数到 Xcode 的  `App` scheme 以运行指令。通过一下三步做到这点：

- 选择 `App` scheme (在 运行/停止 按钮的右边)
- 选择 "Edit Scheme"
- 选择 "App"
- 选择 "Arguments" 这一栏
- 将指令的名词添加到 "Arguments Passed On Launch" (例如， `serve`)

## 自定义指令

你可以通过一个符合 `AsyncCommand` 协议的类型创建你自己的命令

```swift
import Vapor

struct HelloCommand: AsyncCommand {
    ...
}
```

将自定义指令加入到 `app.asyncCommands` 将允许你使用这个指令通过 `swift run`。

```swift
app.asyncCommands.use(HelloCommand(), as: "hello")
```

为了符合 `AsyncCommand` ，你必须实现 `run` 方法。这个方法需要你定义一个 `Signature` 。你还需要提供一个默认的帮助文本。

```swift
import Vapor

struct HelloCommand: AsyncCommand {
    struct Signature: CommandSignature { }

    var help: String {
        "Says hello"
    }

    func run(using context: CommandContext, signature: Signature) async throws {
        context.console.print("Hello, world!")
    }
}
```

这个简单的指令例子没有参数或者选项，所以让 signature 为空。

你可以通过 context 访问当前的 console(控制台)。console 有许多有帮助的方法来提示用户输入，格式化输出，还有更多。

```swift
let name = context.console.ask("What is your \("name", color: .blue)?")
context.console.print("Hello, \(name) 👋")
```

通过运行你的命令来测试:

```sh
swift run App hello
```

### Cowsay

看一下这个著名的 [`cowsay`](https://en.wikipedia.org/wiki/Cowsay) 指令的重制版。它将作为 `@Argument` 和 `@Option` 使用的一个例子。

```swift
import Vapor

struct Cowsay: AsyncCommand {
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

    func run(using context: CommandContext, signature: Signature) async throws {
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

尝试将这个指令加入到程序然后运行它。

```swift
app.asyncCommands.use(Cowsay(), as: "cowsay")
```

```sh
swift run App cowsay sup --eyes ^^ --tongue "U "
```
