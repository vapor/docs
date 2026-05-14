# Comandos

A API de Comandos do Vapor permite que você construa funções personalizadas de linha de comando e interaja com o terminal. É sobre ela que os comandos padrão do Vapor como `serve`, `routes` e `migrate` são construídos.

## Comandos Padrão

Você pode aprender mais sobre os comandos padrão do Vapor usando a opção `--help`.

```sh
swift run App --help
```

Você pode usar `--help` em um comando específico para ver quais argumentos e opções ele aceita.

```sh
swift run App serve --help
```

### Xcode

Você pode executar comandos no Xcode adicionando argumentos ao scheme `App`. Para fazer isso, siga estes passos:

- Escolha o scheme `App` (à direita dos botões play/stop)
- Clique em "Edit Scheme"
- Escolha o produto "App"
- Selecione a aba "Arguments"
- Adicione o nome do comando em "Arguments Passed On Launch" (ex: `serve`)

## Comandos Personalizados

Você pode criar seus próprios comandos criando tipos que conformam com `AsyncCommand`.

```swift
import Vapor

struct HelloCommand: AsyncCommand {
	...
}
```

Adicionar o comando personalizado a `app.asyncCommands` o tornará disponível via `swift run`.

```swift
app.asyncCommands.use(HelloCommand(), as: "hello")
```

Para conformar com `AsyncCommand`, você deve implementar o método `run`. Isso requer declarar uma `Signature`. Você também deve fornecer um texto de ajuda padrão.

```swift
import Vapor

struct HelloCommand: AsyncCommand {
    struct Signature: CommandSignature { }

    var help: String {
        "Diz olá"
    }

    func run(using context: CommandContext, signature: Signature) async throws {
        context.console.print("Olá, mundo!")
    }
}
```

Este exemplo simples de comando não tem argumentos ou opções, então deixe a signature vazia.

Você pode acessar o console atual através do contexto fornecido. O Console possui muitos métodos úteis para solicitar entrada do usuário, formatação de saída e mais.

```swift
let name = context.console.ask("Qual é o seu \("nome", color: .blue)?")
context.console.print("Olá, \(name) 👋")
```

Teste seu comando executando:

```sh
swift run App hello
```

### Cowsay

Veja esta recriação do famoso comando [`cowsay`](https://en.wikipedia.org/wiki/Cowsay) para um exemplo de uso de `@Argument` e `@Option`.

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
        "Gera uma imagem ASCII de uma vaca com uma mensagem."
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

Tente adicionar isso à sua aplicação e executar.

```swift
app.asyncCommands.use(Cowsay(), as: "cowsay")
```

```sh
swift run App cowsay sup --eyes ^^ --tongue "U "
```
