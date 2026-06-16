# Sessões

Sessões permitem que você persista dados de um usuário entre múltiplas requisições. Sessões funcionam criando e retornando um cookie único junto com a resposta HTTP quando uma nova sessão é inicializada. Navegadores detectarão automaticamente este cookie e o incluirão em requisições futuras. Isso permite que o Vapor restaure automaticamente a sessão de um usuário específico no seu request handler.

Sessões são ótimas para aplicações web front-end construídas no Vapor que servem HTML diretamente para navegadores web. Para APIs, recomendamos usar [autenticação stateless baseada em token](../security/authentication.md) para persistir dados do usuário entre requisições.

## Configuração

Para usar sessões em uma rota, a requisição deve passar pelo `SessionsMiddleware`. A forma mais fácil de conseguir isso é adicionando este middleware globalmente. É recomendado que você faça isso após declarar a factory de cookie. Isso porque Sessions é uma struct, portanto é um tipo por valor, e não um tipo por referência. Como é um tipo por valor, você deve definir o valor antes de usar o `SessionsMiddleware`.

```swift
app.middleware.use(app.sessions.middleware)
```

Se apenas um subconjunto das suas rotas utiliza sessões, você pode adicionar o `SessionsMiddleware` a um grupo de rotas.

```swift
let sessions = app.grouped(app.sessions.middleware)
```

O cookie HTTP gerado pelas sessões pode ser configurado usando `app.sessions.configuration`. Você pode alterar o nome do cookie e declarar uma função personalizada para gerar valores de cookie.

```swift
// Alterar o nome do cookie para "foo".
app.sessions.configuration.cookieName = "foo"

// Configura a criação de valores de cookie.
app.sessions.configuration.cookieFactory = { sessionID in
    .init(string: sessionID.string, isSecure: true)
}

app.middleware.use(app.sessions.middleware)
```

Por padrão, o Vapor usará `vapor_session` como nome do cookie.

## Drivers

Drivers de sessão são responsáveis por armazenar e recuperar dados de sessão por identificador. Você pode criar drivers personalizados conformando com o protocolo `SessionDriver`.

!!! warning "Aviso"
	O driver de sessão deve ser configurado _antes_ de adicionar `app.sessions.middleware` à sua aplicação.

### In-Memory

O Vapor utiliza sessões em memória por padrão. Sessões em memória não requerem configuração e não persistem entre reinicializações da aplicação, o que as torna ótimas para testes. Para habilitar sessões em memória manualmente, use `.memory`:

```swift
app.sessions.use(.memory)
```

Para casos de uso em produção, veja os outros drivers de sessão que utilizam bancos de dados para persistir e compartilhar sessões entre múltiplas instâncias da sua aplicação.

### Fluent

O Fluent inclui suporte para armazenar dados de sessão no banco de dados da sua aplicação. Esta seção assume que você [configurou o Fluent](../fluent/overview.md) e pode se conectar a um banco de dados. O primeiro passo é habilitar o driver de sessões do Fluent.

```swift
import Fluent

app.sessions.use(.fluent)
```

Isso configurará as sessões para usar o banco de dados padrão da aplicação. Para especificar um banco de dados específico, passe o identificador do banco de dados.

```swift
app.sessions.use(.fluent(.sqlite))
```

Finalmente, adicione a migration do `SessionRecord` às migrations do seu banco de dados. Isso preparará seu banco de dados para armazenar dados de sessão no schema `_fluent_sessions`.

```swift
app.migrations.add(SessionRecord.migration)
```

Certifique-se de executar as migrations da sua aplicação após adicionar a nova migration. As sessões agora serão armazenadas no banco de dados da sua aplicação, permitindo que persistam entre reinicializações e sejam compartilhadas entre múltiplas instâncias da sua aplicação.

### Redis

O Redis fornece suporte para armazenar dados de sessão na sua instância Redis configurada. Esta seção assume que você [configurou o Redis](../redis/overview.md) e pode enviar comandos para a instância Redis.

Para usar o Redis para Sessões, selecione-o ao configurar sua aplicação:

```swift
import Redis

app.sessions.use(.redis)
```

Isso configurará as sessões para usar o driver de sessões Redis com o comportamento padrão.

!!! seealso "Veja Também"
    Consulte [Redis &rarr; Sessions](../redis/sessions.md) para informações mais detalhadas sobre Redis e Sessões.

## Dados de Sessão

Agora que as sessões estão configuradas, você está pronto para persistir dados entre requisições. Novas sessões são inicializadas automaticamente quando dados são adicionados a `req.session`. O route handler de exemplo abaixo aceita um parâmetro de rota dinâmico e adiciona o valor a `req.session.data`.

```swift
app.get("set", ":value") { req -> HTTPStatus in
    req.session.data["name"] = req.parameters.get("value")
    return .ok
}
```

Use a seguinte requisição para inicializar uma sessão com o nome Vapor.

```http
GET /set/vapor HTTP/1.1
content-length: 0
```

Você deverá receber uma resposta similar à seguinte:

```http
HTTP/1.1 200 OK
content-length: 0
set-cookie: vapor-session=123; Expires=Fri, 10 Apr 2020 21:08:09 GMT; Path=/
```

Note que o header `set-cookie` foi adicionado automaticamente à resposta após adicionar dados a `req.session`. Incluir este cookie em requisições subsequentes permitirá acesso aos dados da sessão.

Adicione o seguinte route handler para acessar o valor do nome a partir da sessão.

```swift
app.get("get") { req -> String in
    req.session.data["name"] ?? "n/a"
}
```

Use a seguinte requisição para acessar esta rota, certificando-se de passar o valor do cookie da resposta anterior.

```http
GET /get HTTP/1.1
cookie: vapor-session=123
```

Você deverá ver o nome Vapor retornado na resposta. Você pode adicionar ou remover dados da sessão como desejar. Os dados da sessão serão sincronizados com o driver de sessão automaticamente antes de retornar a resposta HTTP.

Para encerrar uma sessão, use `req.session.destroy`. Isso deletará os dados do driver de sessão e invalidará o cookie de sessão.

```swift
app.get("del") { req -> HTTPStatus in
    req.session.destroy()
    return .ok
}
```
