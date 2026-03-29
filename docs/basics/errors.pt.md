# Errors

O Vapor se baseia no protocolo `Error` do Swift para tratamento de erros. Handlers de rota podem tanto lançar (`throw`) um erro quanto retornar um `EventLoopFuture` que falhou. Lançar ou retornar um `Error` do Swift resultará em uma resposta com status `500` e o erro será registrado no log. `AbortError` e `DebuggableError` podem ser usados para alterar a resposta resultante e o logging, respectivamente. O tratamento de erros é feito pelo `ErrorMiddleware`. Este middleware é adicionado à aplicação por padrão e pode ser substituído por lógica personalizada, se desejado.

## Abort

O Vapor fornece uma struct de erro padrão chamada `Abort`. Esta struct está em conformidade com `AbortError` e `DebuggableError`. Você pode inicializá-la com um status HTTP e uma razão de falha opcional.

```swift
// 404 error, default "Not Found" reason used.
throw Abort(.notFound)

// 401 error, custom reason used.
throw Abort(.unauthorized, reason: "Invalid Credentials")
```

Em situações assíncronas antigas onde lançar erros não é suportado e você precisa retornar um `EventLoopFuture`, como em uma closure `flatMap`, você pode retornar um future que falhou.

```swift
guard let user = user else {
    req.eventLoop.makeFailedFuture(Abort(.notFound))
}
return user.save()
```

O Vapor inclui uma extensão auxiliar para desempacotar futures com valores opcionais: `unwrap(or:)`.

```swift
User.find(id, on: db)
    .unwrap(or: Abort(.notFound))
    .flatMap
{ user in
    // Non-optional User supplied to closure.
}
```

Se `User.find` retornar `nil`, o future falhará com o erro fornecido. Caso contrário, o `flatMap` receberá um valor não-opcional. Se estiver usando `async`/`await`, você pode lidar com opcionais normalmente:

```swift
guard let user = try await User.find(id, on: db) {
    throw Abort(.notFound)
}
```


## Abort Error

Por padrão, qualquer `Error` do Swift lançado ou retornado por uma closure de rota resultará em uma resposta `500 Internal Server Error`. Quando compilado em modo debug, o `ErrorMiddleware` incluirá uma descrição do erro. Isso é removido por razões de segurança quando o projeto é compilado em modo release.

Para configurar o status HTTP ou a razão da resposta resultante para um erro específico, faça-o estar em conformidade com `AbortError`.

```swift
import Vapor

enum MyError {
    case userNotLoggedIn
    case invalidEmail(String)
}

extension MyError: AbortError {
    var reason: String {
        switch self {
        case .userNotLoggedIn:
            return "User is not logged in."
        case .invalidEmail(let email):
            return "Email address is not valid: \(email)."
        }
    }

    var status: HTTPStatus {
        switch self {
        case .userNotLoggedIn:
            return .unauthorized
        case .invalidEmail:
            return .badRequest
        }
    }
}
```

## Debuggable Error

O `ErrorMiddleware` usa o método `Logger.report(error:)` para registrar erros lançados pelas suas rotas. Este método verificará a conformidade com protocolos como `CustomStringConvertible` e `LocalizedError` para registrar mensagens legíveis.

Para personalizar o logging de erros, você pode fazer seus erros estarem em conformidade com `DebuggableError`. Este protocolo inclui várias propriedades úteis como um identificador único, localização no código-fonte e stack trace. A maioria dessas propriedades é opcional, o que torna a adoção da conformidade fácil.

Para melhor conformidade com `DebuggableError`, seu erro deve ser uma struct para que possa armazenar informações de localização e stack trace, se necessário. Abaixo está um exemplo do enum `MyError` mencionado anteriormente, atualizado para usar uma `struct` e capturar informações de localização do erro.

```swift
import Vapor

struct MyError: DebuggableError {
    enum Value {
        case userNotLoggedIn
        case invalidEmail(String)
    }

    var identifier: String {
        switch self.value {
        case .userNotLoggedIn:
            return "userNotLoggedIn"
        case .invalidEmail:
            return "invalidEmail"
        }
    }

    var reason: String {
        switch self.value {
        case .userNotLoggedIn:
            return "User is not logged in."
        case .invalidEmail(let email):
            return "Email address is not valid: \(email)."
        }
    }

    var value: Value
    var source: ErrorSource?

    init(
        _ value: Value,
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.value = value
        self.source = .init(
            file: file,
            function: function,
            line: line,
            column: column
        )
    }
}
```

`DebuggableError` possui várias outras propriedades como `possibleCauses` e `suggestedFixes` que você pode usar para melhorar a depurabilidade dos seus erros. Consulte o próprio protocolo para mais informações.

## Error Middleware

`ErrorMiddleware` é um dos únicos dois middlewares adicionados à sua aplicação por padrão. Este middleware converte erros do Swift que foram lançados ou retornados pelos seus handlers de rota em respostas HTTP. Sem este middleware, erros lançados resultariam no fechamento da conexão sem uma resposta.

Para personalizar o tratamento de erros além do que `AbortError` e `DebuggableError` fornecem, você pode substituir o `ErrorMiddleware` pela sua própria lógica de tratamento de erros. Para fazer isso, primeiro remova o middleware de erro padrão inicializando manualmente `app.middleware`. Em seguida, adicione seu próprio middleware de tratamento de erros como o primeiro middleware da sua aplicação.

```swift
// Clear all default middleware (then, add back route logging)
app.middleware = .init()
app.middleware.use(RouteLoggingMiddleware(logLevel: .info))
// Add custom error handling middleware first.
app.middleware.use(MyErrorMiddleware())
```

Muito poucos middlewares devem ficar _antes_ do middleware de tratamento de erros. Uma exceção notável a esta regra é o `CORSMiddleware`.
