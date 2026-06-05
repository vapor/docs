# Comandos

La API de comandos de Vapor te permite crear funciones de línea de comandos personalizadas e interactuar con la consola (terminal). Es en lo que se basan los comandos predeterminados de Vapor como `serve`, `routes` y `migrate`.

## Comandos Predeterminados

Puedes obtener más información sobre los comandos predeterminados de Vapor usando la opción `--help`.

```sh
swift run App --help
```

Puedes usar `--help` en un comando específico para ver qué argumentos y opciones acepta.

```sh
swift run App serve --help
```

### Xcode

Puedes ejecutar comandos en Xcode agregando argumentos al esquema `App`. Para hacerlo, sigue estos pasos:

- Elige el esquema `App` (a la derecha de los botones play/stop)
- Haz clic en "Edit Scheme"
- Elige el producto "App"
- Selecciona la pestaña "Arguments"
- Agrega el nombre del comando a "Arguments Passed On Launch" (por ejemplo, `serve`)

## Comandos Personalizados

Puedes crear tus propios comandos creando tipos que conformen a `AsyncCommand`.

```swift
import Vapor

struct HelloCommand: AsyncCommand {
	...
}
```

Agregar el comando personalizado a `app.asyncCommands` lo hará disponible mediante `swift run`.

```swift
app.asyncCommands.use(HelloCommand(), as: "hello")
```

Para conformar con `AsyncCommand`, debes implementar el método `run`. Esto requiere declarar una `Signature`. También debes proporcionar el texto de ayuda predeterminado.

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

Este ejemplo de comando simple no tiene argumentos ni opciones, así que deja la firma vacía.

Puedes obtener acceso a la consola actual a través del contexto proporcionado. La consola tiene muchos métodos útiles para solicitar la entrada del usuario, el formato de salida y más.

```swift
let name = context.console.ask("What is your \("name", color: .blue)?")
context.console.print("Hello, \(name) 👋")
```

Prueba tu comando ejecutando:

```sh
swift run App hello
```

### Cowsay

Aquí tienes una recreación del famoso comando [`cowsay`](https://en.wikipedia.org/wiki/Cowsay) para ver un ejemplo de cómo usar `@Argument` y `@Option`.

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

Intenta agregar esto a tu aplicación y ejecútalo.

```swift
app.asyncCommands.use(Cowsay(), as: "cowsay")
```

```sh
swift run App cowsay sup --eyes ^^ --tongue "U "
```
