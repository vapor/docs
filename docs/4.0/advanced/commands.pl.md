# Komendy

Command API Vapora pozwala na budowanie własnych funkcji wiersza poleceń oraz interakcję z terminalem. To właśnie na nim zbudowane są domyślne komendy Vapora, takie jak `serve`, `routes` i `migrate`.

## Domyślne komendy

Więcej informacji o domyślnych komendach Vapora możesz uzyskać za pomocą opcji `--help`.

```sh
swift run App --help
```

Możesz użyć `--help` na konkretnej komendzie, aby zobaczyć jakie argumenty i opcje przyjmuje.

```sh
swift run App serve --help
```

### Xcode

Możesz uruchamiać komendy w Xcode, dodając argumenty do schematu `App`. Aby to zrobić, wykonaj poniższe kroki:

- Wybierz schemat `App` (po prawej stronie przycisków play/stop)
- Kliknij "Edit Scheme"
- Wybierz produkt "App"
- Wybierz zakładkę "Arguments"
- Dodaj nazwę komendy do "Arguments Passed On Launch" (np. `serve`)

## Własne komendy

Możesz tworzyć własne komendy, tworząc typy zgodne z `AsyncCommand`.

```swift
import Vapor

struct HelloCommand: AsyncCommand {
    ...
}
```

Dodanie własnej komendy do `app.asyncCommands` sprawi, że będzie ona dostępna poprzez `swift run`.

```swift
app.asyncCommands.use(HelloCommand(), as: "hello")
```

Aby być zgodnym z `AsyncCommand`, musisz zaimplementować metodę `run`. Wymaga to zadeklarowania `Signature`. Musisz również dostarczyć domyślny tekst pomocy.

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

Ten prosty przykład komendy nie posiada argumentów ani opcji, więc pozostaw sygnaturę pustą.

Możesz uzyskać dostęp do bieżącej konsoli poprzez dostarczony kontekst. Console posiada wiele przydatnych metod do pytania użytkownika o dane wejściowe, formatowania wyjścia i innych.

```swift
let name = context.console.ask("What is your \("name", color: .blue)?")
context.console.print("Hello, \(name) 👋")
```

Przetestuj swoją komendę, uruchamiając:

```sh
swift run App hello
```

### Cowsay

Spójrz na tę odtworzoną wersję znanej komendy [`cowsay`](https://en.wikipedia.org/wiki/Cowsay) jako przykład użycia `@Argument` i `@Option`.

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

Spróbuj dodać to do swojej aplikacji i uruchomić.

```swift
app.asyncCommands.use(Cowsay(), as: "cowsay")
```

```sh
swift run App cowsay sup --eyes ^^ --tongue "U "
```
