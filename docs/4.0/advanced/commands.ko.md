# 커맨드(Commands)

Vapor의 Command API를 사용하면 커스텀 커맨드 라인 함수를 만들고 터미널과 상호작용할 수 있습니다. `serve`, `routes`, `migrate`와 같은 Vapor의 기본 커맨드들도 이 API를 기반으로 만들어졌습니다.

## 기본 커맨드

`--help` 옵션을 사용하면 Vapor의 기본 커맨드에 대해 더 자세히 알아볼 수 있습니다.

```sh
swift run App --help
```

특정 커맨드에 `--help`를 사용하면 해당 커맨드가 받는 인자(argument)와 옵션(option)을 확인할 수 있습니다.

```sh
swift run App serve --help
```

### Xcode

`App` scheme에 인자를 추가해서 Xcode에서 커맨드를 실행할 수 있습니다. 이렇게 하려면 다음 단계를 따르세요.

- (재생/중지 버튼 오른쪽의) `App` scheme을 선택합니다
- "Edit Scheme"을 클릭합니다
- "App" product를 선택합니다
- "Arguments" 탭을 선택합니다
- "Arguments Passed On Launch"에 커맨드 이름을 추가합니다 (예: `serve`)

## 커스텀 커맨드

`AsyncCommand`를 준수하는 타입을 만들어서 직접 커맨드를 만들 수 있습니다.

```swift
import Vapor

struct HelloCommand: AsyncCommand {
    ...
}
```

커스텀 커맨드를 `app.asyncCommands`에 추가하면 `swift run`을 통해 사용할 수 있게 됩니다.

```swift
app.asyncCommands.use(HelloCommand(), as: "hello")
```

`AsyncCommand`를 준수하려면 `run` 메서드를 구현해야 합니다. 이를 위해서는 `Signature`를 선언해야 합니다. 또한 기본 도움말 텍스트도 제공해야 합니다.

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

이 간단한 커맨드 예제는 인자나 옵션이 없으므로 signature를 비워 둡니다.

제공된 context를 통해 현재 console에 접근할 수 있습니다. Console에는 사용자 입력을 요청하거나 출력 형식을 지정하는 등 유용한 메서드들이 많이 있습니다.

```swift
let name = context.console.ask("What is your \("name", color: .blue)?")
context.console.print("Hello, \(name) 👋")
```

다음을 실행해서 커맨드를 테스트해 보세요.

```sh
swift run App hello
```

### Cowsay

`@Argument`와 `@Option`을 사용하는 예제로, 유명한 [`cowsay`](https://en.wikipedia.org/wiki/Cowsay) 커맨드를 재현한 것을 살펴보겠습니다.

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

이것을 여러분의 애플리케이션에 추가하고 실행해 보세요.

```swift
app.asyncCommands.use(Cowsay(), as: "cowsay")
```

```sh
swift run App cowsay sup --eyes ^^ --tongue "U "
```
