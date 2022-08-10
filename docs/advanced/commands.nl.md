# Commando's

Vapor's Command API staat u toe om aangepaste command-line functies te bouwen en te communiceren met de terminal. Het is waar Vapor's standaard commando's zoals `serve`, `routes`, en `migrate` op gebouwd zijn. 

## Standaard Commando's

U kunt meer te weten komen over de standaard commando's van Vapor door de `--help` optie te gebruiken. 

```sh
vapor run --help
```

Je kunt `--help` gebruiken voor een specifiek commando om te zien welke argumenten en opties het accepteert.

```sh
vapor run serve --help
```

### Xcode

U kunt in Xcode commando's uitvoeren door argumenten toe te voegen aan het `Run` schema. Om dit te doen volgt u deze stappen: 

- Kies `Run` schema (rechts van de play/stop knoppen)
- Klik op "Edit Scheme"
- Kies "Run" product
- Selecteer het tabblad "Arguments"
- Voeg de naam van het commando toe aan "Arguments Passed On Launch" (d.w.z. `serve`)

## Aangepaste Commando's

Je kunt je eigen commando's maken door types te maken die voldoen aan `Command`. 

```swift
import Vapor

struct HelloCommand: Command { 
	...
}
```

Het toevoegen van het aangepaste commando aan `app.commands` maakt het beschikbaar via `vapor run`. 

```swift
app.commands.use(HelloCommand(), as: "hello")
```

Om te voldoen aan `Command`, moet je de `run` methode implementeren. Dit vereist het declareren van een `Signature`. Je moet ook een standaard helptekst opgeven.

```swift
import Vapor

struct HelloCommand: Command {
    struct Signature: CommandSignature { }

    var help: String {
        "Says hello"
    }

    func run(using context: CommandContext, signature: Signature) throws {
        context.console.print("Hello, world!")
    }
}
```

Dit eenvoudige commando voorbeeld heeft geen argumenten of opties, dus laat de handtekening leeg.

Je kunt toegang krijgen tot de huidige console via de meegeleverde context. Console heeft veel handige methodes voor het vragen van gebruikersinvoer, uitvoeropmaak, en meer. 

```swift
let name = context.console.ask("What is your \("name", color: .blue)?")
context.console.print("Hello, \(name) 👋")
```

Test je commando door het volgende uit te voeren:

```sh
vapor run hello
```

### Cowsay

Kijk eens naar deze re-creatie van het beroemde [`cowsay`](https://en.wikipedia.org/wiki/Cowsay) commando voor een voorbeeld van het gebruik van `@Argument` en `@Option`.

```swift
import Vapor

struct Cowsay: Command {
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

    func run(using context: CommandContext, signature: Signature) throws {
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

Probeer dit toe te voegen aan je applicatie en het uit te voeren.

```swift
app.commands.use(Cowsay(), as: "cowsay")
```

```sh
vapor run cowsay sup --eyes ^^ --tongue "U "
```
