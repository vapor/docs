# Middleware

Middleware é uma cadeia lógica entre o cliente e um route handler do Vapor. Permite que você execute operações em requisições de entrada antes que cheguem ao route handler e em respostas de saída antes que cheguem ao cliente.

## Configuração

Middleware pode ser registrado globalmente (em toda rota) em `configure(_:)` usando `app.middleware`.

```swift
app.middleware.use(MyMiddleware())
```

Você também pode adicionar middleware a rotas individuais usando grupos de rotas.

```swift
let group = app.grouped(MyMiddleware())
group.get("foo") { req in
	// Esta requisição passou pelo MyMiddleware.
}
```

### Ordem

A ordem em que os middleware são adicionados é importante. Requisições chegando à sua aplicação passarão pelos middleware na ordem em que foram adicionados. Respostas saindo da sua aplicação passarão pelos middleware na ordem inversa. Middleware específicos de rota sempre rodam após middleware da aplicação. Veja o seguinte exemplo:

```swift
app.middleware.use(MiddlewareA())
app.middleware.use(MiddlewareB())

app.group(MiddlewareC()) {
	$0.get("hello") { req in
		"Hello, middleware."
	}
}
```

Uma requisição para `GET /hello` visitará os middleware na seguinte ordem:

```
Request → A → B → C → Handler → C → B → A → Response
```

Middleware também podem ser _prepended_, o que é útil quando você quer adicionar um middleware _antes_ do middleware padrão que o Vapor adiciona automaticamente:

```swift
app.middleware.use(someMiddleware, at: .beginning)
```

## Criando um Middleware

O Vapor vem com alguns middleware úteis, mas você pode precisar criar o seu próprio por causa dos requisitos da sua aplicação. Por exemplo, você poderia criar um middleware que impede qualquer usuário não-admin de acessar um grupo de rotas.

> Recomendamos criar uma pasta `Middleware` dentro do seu diretório `Sources/App` para manter seu código organizado

Middleware são tipos que conformam com o protocolo `Middleware` ou `AsyncMiddleware` do Vapor. Eles são inseridos na cadeia de responder e podem acessar e manipular uma requisição antes que chegue a um route handler e acessar e manipular uma resposta antes que ela seja retornada.

Usando o exemplo mencionado acima, crie um middleware para bloquear o acesso ao usuário se ele não for um admin:

```swift
import Vapor

struct EnsureAdminUserMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let user = request.auth.get(User.self), user.role == .admin else {
            return request.eventLoop.future(error: Abort(.unauthorized))
        }
        return next.respond(to: request)
    }
}
```

Ou se estiver usando `async`/`await` você pode escrever:

```swift
import Vapor

struct EnsureAdminUserMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(User.self), user.role == .admin else {
            throw Abort(.unauthorized)
        }
        return try await next.respond(to: request)
    }
}
```

Se você quiser modificar a resposta, por exemplo para adicionar um header personalizado, você também pode usar um middleware para isso. Middleware podem aguardar até que a resposta seja recebida da cadeia de responder e manipular a resposta:

```swift
import Vapor

struct AddVersionHeaderMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        next.respond(to: request).map { response in
            response.headers.add(name: "My-App-Version", value: "v2.5.9")
            return response
        }
    }
}
```

Ou se estiver usando `async`/`await` você pode escrever:

```swift
import Vapor

struct AddVersionHeaderMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let response = try await next.respond(to: request)
        response.headers.add(name: "My-App-Version", value: "v2.5.9")
        return response
    }
}
```

## File Middleware

`FileMiddleware` habilita o fornecimento de assets da pasta Public do seu projeto para o cliente. Você pode incluir arquivos estáticos como folhas de estilo ou imagens bitmap aqui.

```swift
let file = FileMiddleware(publicDirectory: app.directory.publicDirectory)
app.middleware.use(file)
```

Uma vez que o `FileMiddleware` está registrado, um arquivo como `Public/images/logo.png` pode ser referenciado de um template Leaf como `<img src="/images/logo.png"/>`.

Se seu servidor está contido em um Xcode Project, como um app iOS, use isso em vez disso:

```swift
let file = try FileMiddleware(bundle: .main, publicDirectory: "Public")
```

Também certifique-se de usar Folder References em vez de Groups no Xcode para manter a estrutura de pastas nos recursos após compilar a aplicação.

## CORS Middleware

Cross-origin resource sharing (CORS) é um mecanismo que permite que recursos restritos em uma página web sejam solicitados de outro domínio fora do domínio de onde o primeiro recurso foi servido. APIs REST construídas no Vapor precisarão de uma política CORS para retornar requisições com segurança para navegadores web modernos.

Um exemplo de configuração poderia ser algo assim:

```swift
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
)
let cors = CORSMiddleware(configuration: corsConfiguration)
// O middleware CORS deve vir antes do middleware de erro padrão usando `at: .beginning`
app.middleware.use(cors, at: .beginning)
```

Dado que erros lançados são retornados imediatamente ao cliente, o `CORSMiddleware` deve ser listado _antes_ do `ErrorMiddleware`. Caso contrário, a resposta de erro HTTP será retornada sem headers CORS e não poderá ser lida pelo navegador.
