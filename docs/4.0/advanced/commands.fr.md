# Commandes

L'API Command de Vapor vous permet de créer des fonctions en ligne de commande personnalisées et d'interagir avec le terminal. C'est sur cette base que sont construites les commandes par défaut de Vapor comme `serve`, `routes` et `migrate`.

## Commandes par défaut

Vous pouvez en apprendre davantage sur les commandes par défaut de Vapor grâce à l'option `--help`.

```sh
swift run App --help
```

Vous pouvez utiliser `--help` sur une commande spécifique pour voir quels arguments et options elle accepte.

```sh
swift run App serve --help
```

### Xcode

Vous pouvez exécuter des commandes dans Xcode en ajoutant des arguments au scheme `App`. Pour ce faire, suivez ces étapes :

- Choisissez le scheme `App` (à droite des boutons play/stop)
- Cliquez sur "Edit Scheme"
- Choisissez le produit "App"
- Sélectionnez l'onglet "Arguments"
- Ajoutez le nom de la commande dans "Arguments Passed On Launch" (par exemple, `serve`)

## Commandes personnalisées

Vous pouvez créer vos propres commandes en créant des types conformes à `AsyncCommand`.

```swift
import Vapor

struct HelloCommand: AsyncCommand {
    ...
}
```

Ajouter la commande personnalisée à `app.asyncCommands` la rendra disponible via `swift run`.

```swift
app.asyncCommands.use(HelloCommand(), as: "hello")
```

Pour être conforme à `AsyncCommand`, vous devez implémenter la méthode `run`. Cela nécessite de déclarer une `Signature`. Vous devez également fournir un texte d'aide par défaut.

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

Cet exemple de commande simple n'a ni arguments ni options, laissez donc la signature vide.

Vous pouvez accéder à la console actuelle via le contexte fourni. Console dispose de nombreuses méthodes utiles pour demander une saisie à l'utilisateur, formater la sortie, et plus encore.

```swift
let name = context.console.ask("What is your \("name", color: .blue)?")
context.console.print("Hello, \(name) 👋")
```

Testez votre commande en exécutant :

```sh
swift run App hello
```

### Cowsay

Jetez un œil à cette recréation de la célèbre commande [`cowsay`](https://en.wikipedia.org/wiki/Cowsay) comme exemple d'utilisation de `@Argument` et `@Option`.

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

Essayez d'ajouter ceci à votre application et de l'exécuter.

```swift
app.asyncCommands.use(Cowsay(), as: "cowsay")
```

```sh
swift run App cowsay sup --eyes ^^ --tongue "U "
```
