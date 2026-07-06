# Commandes

L'API Commandes de Vapor vous permet de construire des outils de ligne de commande personnalisés avec lesquels vous pourrez interagir via un terminal. C'est avec cette API que les commandes par défaut de Vapor comme `serve`, `routes`, et `migrate` sont construites.

## Commandes par défaut

Vous pouvez découvrir les commandes par défaut de Vapor avec l'option `--help`.

```sh
swift run App --help
```

Vous pouvez utiliser `--help` sur une commande spécifique pour voir les arguments et options qu'elle accepte.

```sh
swift run App serve --help
```

### Xcode

Vous pouvez exécuter des commandes via Xcode en ajoutant des arguments au scheme `App`. Pour cela, suivez ces étapes :

- Choisissez le scheme `App` (à droite des boutons lecture/stop)
- Cliquez sur "Edit Scheme"
- Choisissez le produit "App"
- Sélectionnez l'onglet "Arguments"
- Ajoutez le nom de la commande à "Arguments Passed On Launch" (i.e., `serve`)

## Commandes personnalisées

Vous pouvez créer vos propres commandes en créant des types conformes au protocole `AsyncCommand`.

```swift
import Vapor

struct HelloCommand: AsyncCommand {
    ...
}
```

Ajouter la commande à `app.asyncCommands` la rendra disponible via `swift run`.

```swift
app.asyncCommands.use(HelloCommand(), as: "hello")
```

Pour conformer un type à `AsyncCommand`, vous devrez implémenter la méthode `run`. Cela implique la déclaration d'une `Signature`. Vous devrez également indiquer un texte d'aide par défaut.

```swift
import Vapor

struct HelloCommand: AsyncCommand {
    struct Signature: CommandSignature { }

    var help: String {
        "Cette commande affiche hello world"
    }

    func run(using context: CommandContext, signature: Signature) async throws {
        context.console.print("Hello, world!")
    }
}
```

Cet exemple de commande basique ne possède ni arguments ni options, la signature peut donc rester vide.

Vous pouvez accéder à la console via le contexte fourni. L'objet Console possède plusieurs méthodes utiles pour demander des entrées utilisateur, formatter des sorties, et plus.

```swift
let name = context.console.ask("Quel est votre \("prénom", color: .blue) ?")
context.console.print("Bonjour \(nom) 👋")
```

Testez votre commande en lançant :

```sh
swift run App hello
```

### Cowsay

Observez cette re-création de la célèbre commande [`cowsay`](https://en.wikipedia.org/wiki/Cowsay) comme exemple d'utilisation avec `@Argument` et `@Option`.

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
        "Génère une image ASCII d'une vache avec une bulle de texte."
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

Essayez de l'ajouter à votre application et de la lancer.

```swift
app.asyncCommands.use(Cowsay(), as: "cowsay")
```

```sh
swift run App cowsay sup --eyes ^^ --tongue "U "
```
