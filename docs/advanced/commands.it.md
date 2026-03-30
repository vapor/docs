# Comandi

L'API Command di Vapor ti permette di creare funzioni a riga di comando personalizzate e interagire con il terminale. È su questa API che sono costruiti i comandi predefiniti di Vapor come `serve`, `routes` e `migrate`.

## Comandi Predefiniti

Puoi saperne di più sui comandi predefiniti di Vapor usando l'opzione `--help`.

```sh
swift run App --help
```

Puoi usare `--help` su un comando specifico per vedere quali argomenti e opzioni accetta.

```sh
swift run App serve --help
```

### Xcode

Puoi eseguire comandi in Xcode aggiungendo argomenti allo schema `App`. Per farlo, segui questi passaggi:

- Scegli lo schema `App` (a destra dei pulsanti play/stop)
- Clicca su "Edit Scheme"
- Scegli il prodotto "App"
- Seleziona la scheda "Arguments"
- Aggiungi il nome del comando in "Arguments Passed On Launch" (es. `serve`)

## Comandi Personalizzati

Puoi creare i tuoi comandi creando tipi che si conformano a `AsyncCommand`.

```swift
import Vapor

struct HelloCommand: AsyncCommand {
	...
}
```

Aggiungere il comando personalizzato a `app.asyncCommands` lo renderà disponibile tramite `swift run`.

```swift
app.asyncCommands.use(HelloCommand(), as: "hello")
```

Per essere conforme ad `AsyncCommand`, devi implementare il metodo `run`. Questo richiede la dichiarazione di una `Signature`. Devi anche fornire un testo di aiuto predefinito.

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

Questo semplice comando di esempio non ha argomenti né opzioni, quindi lascia la firma vuota.

Puoi accedere alla console corrente tramite il context fornito. `Console` ha molti metodi utili per richiedere input all'utente, formattare l'output e altro ancora.

```swift
let name = context.console.ask("What is your \("name", color: .blue)?")
context.console.print("Hello, \(name) 👋")
```

Testa il tuo comando eseguendo:

```sh
swift run App hello
```

### Cowsay

Dai un'occhiata a questa ricreazione del famoso comando [`cowsay`](https://en.wikipedia.org/wiki/Cowsay) per un esempio di utilizzo di `@Argument` e `@Option`.

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

Prova ad aggiungerlo alla tua applicazione ed eseguirlo.

```swift
app.asyncCommands.use(Cowsay(), as: "cowsay")
```

```sh
swift run App cowsay sup --eyes ^^ --tongue "U "
```
