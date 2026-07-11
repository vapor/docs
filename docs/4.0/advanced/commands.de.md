# Commands

Vapors Command API ermöglicht es dir, eigene Kommandozeilenfunktionen zu erstellen und mit dem Terminal zu interagieren. Darauf basieren Vapors Standardbefehle wie `serve`, `routes` und `migrate`.

## Standardbefehle

Mit der Option `--help` erfährst du mehr über Vapors Standardbefehle.

```sh
swift run App --help
```

Du kannst `--help` auch für einen bestimmten Befehl verwenden, um zu sehen, welche Argumente und Optionen er akzeptiert.

```sh
swift run App serve --help
```

### Xcode

Du kannst Befehle in Xcode ausführen, indem du dem `App`-Scheme Argumente hinzufügst. Gehe dazu wie folgt vor:

- Wähle das `App`-Scheme aus (rechts neben den Play-/Stop-Schaltflächen)
- Klicke auf "Edit Scheme"
- Wähle das Produkt "App" aus
- Wähle den Tab "Arguments" aus
- Füge den Namen des Befehls unter "Arguments Passed On Launch" hinzu (z. B. `serve`)

## Eigene Befehle

Du kannst eigene Befehle erstellen, indem du Typen erstellst, die `AsyncCommand` entsprechen.

```swift
import Vapor

struct HelloCommand: AsyncCommand {
    ...
}
```

Wenn du den eigenen Befehl zu `app.asyncCommands` hinzufügst, wird er über `swift run` verfügbar.

```swift
app.asyncCommands.use(HelloCommand(), as: "hello")
```

Um `AsyncCommand` zu entsprechen, musst du die Methode `run` implementieren. Dafür ist es erforderlich, eine `Signature` zu deklarieren. Außerdem musst du einen Standard-Hilfetext bereitstellen.

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

Dieses einfache Befehlsbeispiel hat keine Argumente oder Optionen, daher bleibt die Signature leer.

Über den bereitgestellten Context erhältst du Zugriff auf die aktuelle Console. Console bietet viele nützliche Methoden, um Benutzereingaben abzufragen, die Ausgabe zu formatieren und mehr.

```swift
let name = context.console.ask("What is your \("name", color: .blue)?")
context.console.print("Hello, \(name) 👋")
```

Teste deinen Befehl, indem du Folgendes ausführst:

```sh
swift run App hello
```

### Cowsay

Wirf einen Blick auf diese Nachbildung des bekannten [`cowsay`](https://en.wikipedia.org/wiki/Cowsay)-Befehls als Beispiel für die Verwendung von `@Argument` und `@Option`.

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

Versuche, dies zu deiner Anwendung hinzuzufügen und auszuführen.

```swift
app.asyncCommands.use(Cowsay(), as: "cowsay")
```

```sh
swift run App cowsay sup --eyes ^^ --tongue "U "
```
