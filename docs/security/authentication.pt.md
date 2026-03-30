# Autenticação

Autenticação é o ato de verificar a identidade de um usuário. Isso é feito através da verificação de credenciais como nome de usuário e senha ou token único. Autenticação (às vezes chamada de auth/c) é distinta de autorização (auth/z), que é o ato de verificar as permissões de um usuário previamente autenticado para realizar determinadas tarefas.

## Introdução

A API de Autenticação do Vapor fornece suporte para autenticar um usuário através do header `Authorization`, usando [Basic](https://tools.ietf.org/html/rfc7617) e [Bearer](https://tools.ietf.org/html/rfc6750). Também suporta autenticação de um usuário através dos dados decodificados da API de [Conteúdo](../basics/content.md).

A autenticação é implementada criando um `Authenticator` que contém a lógica de verificação. Um authenticator pode ser usado para proteger grupos de rotas individuais ou uma aplicação inteira. Os seguintes helpers de authenticator vêm com o Vapor:

|Protocolo|Descrição|
|-|-|
|`RequestAuthenticator`/`AsyncRequestAuthenticator`|Authenticator base capaz de criar middleware.|
|[`BasicAuthenticator`/`AsyncBasicAuthenticator`](#basic)|Autentica o header de autorização Basic.|
|[`BearerAuthenticator`/`AsyncBearerAuthenticator`](#bearer)|Autentica o header de autorização Bearer.|
|`CredentialsAuthenticator`/`AsyncCredentialsAuthenticator`|Autentica um payload de credenciais do corpo da requisição.|

Se a autenticação for bem-sucedida, o authenticator adiciona o usuário verificado a `req.auth`. Este usuário pode então ser acessado usando `req.auth.get(_:)` em rotas protegidas pelo authenticator. Se a autenticação falhar, o usuário não é adicionado a `req.auth` e qualquer tentativa de acessá-lo falhará.

## Authenticatable

Para usar a API de Autenticação, você primeiro precisa de um tipo de usuário que conforme com `Authenticatable`. Isso pode ser uma `struct`, `class` ou até mesmo um `Model` do Fluent. Os exemplos a seguir assumem esta simples struct `User` que tem uma propriedade: `name`.

```swift
import Vapor

struct User: Authenticatable {
    var name: String
}
```

Cada exemplo abaixo usará uma instância de um authenticator que criamos. Nestes exemplos, chamamos de `UserAuthenticator`.

### Rota

Authenticators são middleware e podem ser usados para proteger rotas.

```swift
let protected = app.grouped(UserAuthenticator())
protected.get("me") { req -> String in
    try req.auth.require(User.self).name
}
```

`req.auth.require` é usado para buscar o `User` autenticado. Se a autenticação falhou, este método lançará um erro, protegendo a rota.

### Guard Middleware

Você também pode usar `GuardMiddleware` no seu grupo de rotas para garantir que um usuário foi autenticado antes de chegar ao seu route handler.

```swift
let protected = app.grouped(UserAuthenticator())
    .grouped(User.guardMiddleware())
```

Exigir autenticação não é feito pelo middleware do authenticator para permitir composição de authenticators. Leia mais sobre [composição](#composicao) abaixo.

## Basic

A autenticação Basic envia um nome de usuário e senha no header `Authorization`. O nome de usuário e a senha são concatenados com dois-pontos (ex: `test:secret`), codificados em base-64, e prefixados com `"Basic "`. O exemplo de requisição a seguir codifica o nome de usuário `test` com a senha `secret`.

```http
GET /me HTTP/1.1
Authorization: Basic dGVzdDpzZWNyZXQ=
```

A autenticação Basic é tipicamente usada uma vez para fazer login de um usuário e gerar um token. Isso minimiza a frequência com que a senha sensível do usuário precisa ser enviada. Você nunca deve enviar autorização Basic por uma conexão de texto puro ou TLS não verificada.

Para implementar a autenticação Basic na sua aplicação, crie um novo authenticator conformando com `BasicAuthenticator`. Abaixo está um exemplo de authenticator com valores fixos para verificar a requisição acima.

```swift
import Vapor

struct UserAuthenticator: BasicAuthenticator {
    typealias User = App.User

    func authenticate(
        basic: BasicAuthorization,
        for request: Request
    ) -> EventLoopFuture<Void> {
        if basic.username == "test" && basic.password == "secret" {
            request.auth.login(User(name: "Vapor"))
        }
        return request.eventLoop.makeSucceededFuture(())
   }
}
```

Se você estiver usando `async`/`await`, pode usar `AsyncBasicAuthenticator`:

```swift
import Vapor

struct UserAuthenticator: AsyncBasicAuthenticator {
    typealias User = App.User

    func authenticate(
        basic: BasicAuthorization,
        for request: Request
    ) async throws {
        if basic.username == "test" && basic.password == "secret" {
            request.auth.login(User(name: "Vapor"))
        }
   }
}
```

Este protocolo requer que você implemente `authenticate(basic:for:)`, que será chamado quando uma requisição recebida contiver o header `Authorization: Basic ...`. Uma struct `BasicAuthorization` contendo o nome de usuário e a senha é passada para o método.

Neste authenticator de teste, o nome de usuário e a senha são testados contra valores fixos. Em um authenticator real, você pode verificar contra um banco de dados ou API externa. É por isso que o método `authenticate` permite retornar um future.

!!! tip "Dica"
    Senhas nunca devem ser armazenadas em um banco de dados como texto puro. Sempre use hashes de senha para comparação.

Se os parâmetros de autenticação estiverem corretos, neste caso correspondendo aos valores fixos, um `User` chamado Vapor é logado. Se os parâmetros de autenticação não corresponderem, nenhum usuário é logado, o que significa que a autenticação falhou.

Se você adicionar este authenticator à sua aplicação e testar a rota definida acima, você deverá ver o nome `"Vapor"` retornado para um login bem-sucedido. Se as credenciais não estiverem corretas, você deverá ver um erro `401 Unauthorized`.

## Bearer

A autenticação Bearer envia um token no header `Authorization`. O token é prefixado com `"Bearer "`. O exemplo de requisição a seguir envia o token `foo`.

```http
GET /me HTTP/1.1
Authorization: Bearer foo
```

A autenticação Bearer é comumente usada para autenticação de endpoints de API. O usuário tipicamente solicita um Bearer token enviando credenciais como nome de usuário e senha para um endpoint de login. Este token pode durar minutos ou dias dependendo das necessidades da aplicação.

Enquanto o token for válido, o usuário pode usá-lo no lugar de suas credenciais para se autenticar na API. Se o token se tornar inválido, um novo pode ser gerado usando o endpoint de login.

Para implementar a autenticação Bearer na sua aplicação, crie um novo authenticator conformando com `BearerAuthenticator`. Abaixo está um exemplo de authenticator com valores fixos para verificar a requisição acima.

```swift
import Vapor

struct UserAuthenticator: BearerAuthenticator {
    typealias User = App.User

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) -> EventLoopFuture<Void> {
       if bearer.token == "foo" {
           request.auth.login(User(name: "Vapor"))
       }
       return request.eventLoop.makeSucceededFuture(())
   }
}
```

Se você estiver usando `async`/`await`, pode usar `AsyncBearerAuthenticator`:

```swift
import Vapor

struct UserAuthenticator: AsyncBearerAuthenticator {
    typealias User = App.User

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) async throws {
       if bearer.token == "foo" {
           request.auth.login(User(name: "Vapor"))
       }
   }
}
```

Este protocolo requer que você implemente `authenticate(bearer:for:)`, que será chamado quando uma requisição recebida contiver o header `Authorization: Bearer ...`. Uma struct `BearerAuthorization` contendo o token é passada para o método.

Neste authenticator de teste, o token é testado contra um valor fixo. Em um authenticator real, você pode verificar o token consultando um banco de dados ou usando medidas criptográficas, como é feito com JWT. É por isso que o método `authenticate` permite retornar um future.

!!! tip "Dica"
	Ao implementar verificação de token, é importante considerar a escalabilidade horizontal. Se sua aplicação precisa lidar com muitos usuários simultaneamente, a autenticação pode ser um potencial gargalo. Considere como seu design irá escalar em múltiplas instâncias da sua aplicação rodando ao mesmo tempo.

Se os parâmetros de autenticação estiverem corretos, neste caso correspondendo ao valor fixo, um `User` chamado Vapor é logado. Se os parâmetros de autenticação não corresponderem, nenhum usuário é logado, o que significa que a autenticação falhou.

Se você adicionar este authenticator à sua aplicação e testar a rota definida acima, você deverá ver o nome `"Vapor"` retornado para um login bem-sucedido. Se as credenciais não estiverem corretas, você deverá ver um erro `401 Unauthorized`.

## Composição

Múltiplos authenticators podem ser compostos (combinados) para criar autenticação de endpoint mais complexa. Como um middleware de authenticator não rejeita a requisição se a autenticação falhar, mais de um desses middleware pode ser encadeado. Authenticators podem ser compostos de duas formas principais.

### Compondo Métodos

O primeiro método de composição de autenticação é encadear mais de um authenticator para o mesmo tipo de usuário. Veja o seguinte exemplo:

```swift
app.grouped(UserPasswordAuthenticator())
    .grouped(UserTokenAuthenticator())
    .grouped(User.guardMiddleware())
    .post("login")
{ req in
    let user = try req.auth.require(User.self)
    // Fazer algo com o user.
}
```

Este exemplo assume dois authenticators `UserPasswordAuthenticator` e `UserTokenAuthenticator` que ambos autenticam `User`. Ambos são adicionados ao grupo de rotas. Finalmente, `GuardMiddleware` é adicionado após os authenticators para exigir que `User` foi autenticado com sucesso.

Esta composição de authenticators resulta em uma rota que pode ser acessada por senha ou token. Tal rota poderia permitir que um usuário faça login e gere um token, e então continue usando esse token para gerar novos tokens.

### Compondo Usuários

O segundo método de composição de autenticação é encadear authenticators para diferentes tipos de usuário. Veja o seguinte exemplo:

```swift
app.grouped(AdminAuthenticator())
    .grouped(UserAuthenticator())
    .get("secure")
{ req in
    guard req.auth.has(Admin.self) || req.auth.has(User.self) else {
        throw Abort(.unauthorized)
    }
    // Fazer algo.
}
```

Este exemplo assume dois authenticators `AdminAuthenticator` e `UserAuthenticator` que autenticam `Admin` e `User`, respectivamente. Ambos são adicionados ao grupo de rotas. Em vez de usar `GuardMiddleware`, uma verificação no route handler é adicionada para ver se `Admin` ou `User` foram autenticados. Se não, um erro é lançado.

Esta composição de authenticators resulta em uma rota que pode ser acessada por dois tipos diferentes de usuários com métodos de autenticação potencialmente diferentes. Tal rota poderia permitir autenticação de usuário normal enquanto ainda dá acesso a um super-usuário.

## Manual

Você também pode lidar com autenticação manualmente usando `req.auth`. Isso é especialmente útil para testes.

Para logar manualmente um usuário, use `req.auth.login(_:)`. Qualquer usuário `Authenticatable` pode ser passado para este método.

```swift
req.auth.login(User(name: "Vapor"))
```

Para obter o usuário autenticado, use `req.auth.require(_:)`

```swift
let user: User = try req.auth.require(User.self)
print(user.name) // String
```

Você também pode usar `req.auth.get(_:)` se não quiser lançar um erro automaticamente quando a autenticação falhar.

```swift
let user = req.auth.get(User.self)
print(user?.name) // String?
```

Para desautenticar um usuário, passe o tipo de usuário para `req.auth.logout(_:)`.

```swift
req.auth.logout(User.self)
```

## Fluent

O [Fluent](../fluent/overview.md) define dois protocolos `ModelAuthenticatable` e `ModelTokenAuthenticatable` que podem ser adicionados aos seus modelos existentes. Conformar seus modelos a esses protocolos permite a criação de authenticators para proteger endpoints.

`ModelTokenAuthenticatable` autentica com um Bearer token. É o que você usa para proteger a maioria dos seus endpoints. `ModelAuthenticatable` autentica com nome de usuário e senha e é usado por um único endpoint para gerar tokens.

Este guia assume que você está familiarizado com o Fluent e configurou sua aplicação com sucesso para usar um banco de dados. Se você é novo no Fluent, comece com a [visão geral](../fluent/overview.md).

### User

Para começar, você precisará de um modelo representando o usuário que será autenticado. Para este guia, usaremos o seguinte modelo, mas você é livre para usar um modelo existente.

```swift
import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    init() { }

    init(id: UUID? = nil, name: String, email: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
    }
}
```

O modelo deve ser capaz de armazenar um nome de usuário, neste caso um e-mail, e um hash de senha. Também definimos `email` como um campo único para evitar usuários duplicados. A migration correspondente para este modelo de exemplo está aqui:

```swift
import Fluent
import Vapor

extension User {
    struct Migration: AsyncMigration {
        var name: String { "CreateUser" }

        func prepare(on database: Database) async throws {
            try await database.schema("users")
                .id()
                .field("name", .string, .required)
                .field("email", .string, .required)
                .field("password_hash", .string, .required)
                .unique(on: "email")
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema("users").delete()
        }
    }
}
```

Não esqueça de adicionar a migration a `app.migrations`.

```swift
app.migrations.add(User.Migration())
```

!!! tip "Dica"
     Como endereços de e-mail não são sensíveis a maiúsculas/minúsculas, você pode querer adicionar um [`Middleware`](../fluent/model.md#lifecycle) que converte o endereço de e-mail para minúsculas antes de salvá-lo no banco de dados. Esteja ciente, porém, que `ModelAuthenticatable` usa uma comparação sensível a maiúsculas/minúsculas, então se fizer isso você vai querer garantir que a entrada do usuário esteja toda em minúsculas, seja com conversão no cliente ou com um authenticator personalizado.

A primeira coisa que você precisará é de um endpoint para criar novos usuários. Vamos usar `POST /users`. Crie uma struct [Content](../basics/content.md) representando os dados que este endpoint espera.

```swift
import Vapor

extension User {
    struct Create: Content {
        var name: String
        var email: String
        var password: String
        var confirmPassword: String
    }
}
```

Se quiser, você pode conformar esta struct com [Validatable](../basics/validation.md) para adicionar requisitos de validação.

```swift
import Vapor

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}
```

Agora você pode criar o endpoint `POST /users`.

```swift
app.post("users") { req async throws -> User in
    try User.Create.validate(content: req)
    let create = try req.content.decode(User.Create.self)
    guard create.password == create.confirmPassword else {
        throw Abort(.badRequest, reason: "Passwords did not match")
    }
    let user = try User(
        name: create.name,
        email: create.email,
        passwordHash: Bcrypt.hash(create.password)
    )
    try await user.save(on: req.db)
    return user
}
```

Este endpoint valida a requisição recebida, decodifica a struct `User.Create` e verifica se as senhas correspondem. Então usa os dados decodificados para criar um novo `User` e salva no banco de dados. A senha em texto puro é hasheada usando `Bcrypt` antes de salvar no banco de dados.

Compile e execute o projeto, certificando-se de migrar o banco de dados primeiro, e então use a seguinte requisição para criar um novo usuário.

```http
POST /users HTTP/1.1
Content-Length: 97
Content-Type: application/json

{
    "name": "Vapor",
    "email": "test@vapor.codes",
    "password": "secret42",
    "confirmPassword": "secret42"
}
```

#### Model Authenticatable

Agora que você tem um modelo de usuário e um endpoint para criar novos usuários, vamos conformar o modelo com `ModelAuthenticatable`. Isso permitirá que o modelo seja autenticado usando nome de usuário e senha.

```swift
import Fluent
import Vapor

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}
```

Esta extensão adiciona conformidade com `ModelAuthenticatable` ao `User`. As duas primeiras propriedades especificam quais campos devem ser usados para armazenar o nome de usuário e o hash de senha, respectivamente. A notação `\` cria um key path para os campos que o Fluent pode usar para acessá-los.

O último requisito é um método para verificar senhas em texto puro enviadas no header de autenticação Basic. Como estamos usando Bcrypt para hashear a senha durante o cadastro, usaremos Bcrypt para verificar se a senha fornecida corresponde ao hash de senha armazenado.

Agora que o `User` conforma com `ModelAuthenticatable`, podemos criar um authenticator para proteger a rota de login.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req -> User in
    try req.auth.require(User.self)
}
```

`ModelAuthenticatable` adiciona um método estático `authenticator` para criar um authenticator.

Teste se esta rota funciona enviando a seguinte requisição.

```http
POST /login HTTP/1.1
Authorization: Basic dGVzdEB2YXBvci5jb2RlczpzZWNyZXQ0Mg==
```

Esta requisição passa o nome de usuário `test@vapor.codes` e a senha `secret42` via header de autenticação Basic. Você deverá ver o usuário criado anteriormente sendo retornado.

Embora você pudesse teoricamente usar autenticação Basic para proteger todos os seus endpoints, é recomendado usar um token separado. Isso minimiza a frequência com que você precisa enviar a senha sensível do usuário pela Internet. Também torna a autenticação muito mais rápida, já que você só precisa realizar o hashing de senha durante o login.

### User Token

Crie um novo modelo para representar tokens de usuário.

```swift
import Fluent
import Vapor

final class UserToken: Model, Content {
    static let schema = "user_tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "value")
    var value: String

    @Parent(key: "user_id")
    var user: User

    init() { }

    init(id: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
}
```

Este modelo deve ter um campo `value` para armazenar a string única do token. Também deve ter uma [relação parent](../fluent/overview.md#parent) com o modelo de usuário. Você pode adicionar propriedades adicionais a este token como desejar, como uma data de expiração.

Em seguida, crie uma migration para este modelo.

```swift
import Fluent

extension UserToken {
    struct Migration: AsyncMigration {
        var name: String { "CreateUserToken" }

        func prepare(on database: Database) async throws {
            try await database.schema("user_tokens")
                .id()
                .field("value", .string, .required)
                .field("user_id", .uuid, .required, .references("users", "id"))
                .unique(on: "value")
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema("user_tokens").delete()
        }
    }
}
```

Note que esta migration torna o campo `value` único. Também cria uma referência de chave estrangeira entre o campo `user_id` e a tabela users.

Não esqueça de adicionar a migration a `app.migrations`.

```swift
app.migrations.add(UserToken.Migration())
```

Finalmente, adicione um método no `User` para gerar um novo token. Este método será usado durante o login.

```swift
extension User {
    func generateToken() throws -> UserToken {
        try .init(
            value: [UInt8].random(count: 16).base64,
            userID: self.requireID()
        )
    }
}
```

Aqui estamos usando `[UInt8].random(count:)` para gerar um valor de token aleatório. Para este exemplo, 16 bytes, ou 128 bits, de dados aleatórios estão sendo usados. Você pode ajustar este número como desejar. Os dados aleatórios são então codificados em base-64 para facilitar a transmissão em headers HTTP.

Agora que você pode gerar tokens de usuário, atualize a rota `POST /login` para criar e retornar um token.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req async throws -> UserToken in
    let user = try req.auth.require(User.self)
    let token = try user.generateToken()
    try await token.save(on: req.db)
    return token
}
```

Teste se esta rota funciona usando a mesma requisição de login acima. Agora você deverá receber um token ao fazer login que se parece com algo assim:

```
8gtg300Jwdhc/Ffw784EXA==
```

Guarde o token que você recebeu, pois o usaremos em breve.

#### Model Token Authenticatable

Conforme `UserToken` com `ModelTokenAuthenticatable`. Isso permitirá que tokens autentiquem seu modelo `User`.

```swift
import Vapor
import Fluent

extension UserToken: ModelTokenAuthenticatable {
    static var valueKey: KeyPath<UserToken, Field<String>> { \.$value }
    static var userKey: KeyPath<UserToken, Parent<User>> { \.$user }

    var isValid: Bool {
        true
    }
}
```

O primeiro requisito do protocolo especifica qual campo armazena o valor único do token. Este é o valor que será enviado no header de autenticação Bearer. O segundo requisito especifica a relação parent com o modelo `User`. É assim que o Fluent buscará o usuário autenticado.

O requisito final é um booleano `isValid`. Se for `false`, o token será deletado do banco de dados e o usuário não será autenticado. Para simplicidade, tornaremos os tokens eternos fixando isso como `true`.

Agora que o token conforma com `ModelTokenAuthenticatable`, você pode criar um authenticator para proteger rotas.

Crie um novo endpoint `GET /me` para obter o usuário autenticado atual.

```swift
let tokenProtected = app.grouped(UserToken.authenticator())
tokenProtected.get("me") { req -> User in
    try req.auth.require(User.self)
}
```

Similar ao `User`, `UserToken` agora tem um método estático `authenticator()` que pode gerar um authenticator. O authenticator tentará encontrar um `UserToken` correspondente usando o valor fornecido no header de autenticação Bearer. Se encontrar uma correspondência, buscará o `User` relacionado e o autenticará.

Teste se esta rota funciona enviando a seguinte requisição HTTP onde o token é o valor que você salvou da requisição `POST /login`.

```http
GET /me HTTP/1.1
Authorization: Bearer <token>
```

Você deverá ver o `User` autenticado sendo retornado.

## Sessão

A [API de Sessão](../advanced/sessions.md) do Vapor pode ser usada para persistir automaticamente a autenticação do usuário entre requisições. Isso funciona armazenando um identificador único para o usuário nos dados de sessão da requisição após um login bem-sucedido. Em requisições subsequentes, o identificador do usuário é buscado da sessão e usado para autenticar o usuário antes de chamar seu route handler.

Sessões são ótimas para aplicações web front-end construídas no Vapor que servem HTML diretamente para navegadores web. Para APIs, recomendamos usar autenticação stateless baseada em token para persistir dados do usuário entre requisições.

### Session Authenticatable

Para usar autenticação baseada em sessão, você precisará de um tipo que conforme com `SessionAuthenticatable`. Para este exemplo, usaremos uma struct simples.

```swift
import Vapor

struct User {
    var email: String
}
```

Para conformar com `SessionAuthenticatable`, você precisará especificar um `sessionID`. Este é o valor que será armazenado nos dados da sessão e deve identificar o usuário de forma única.

```swift
extension User: SessionAuthenticatable {
    var sessionID: String {
        self.email
    }
}
```

Para nosso tipo simples `User`, usaremos o endereço de e-mail como identificador único de sessão.

### Session Authenticator

Em seguida, precisaremos de um `SessionAuthenticator` para lidar com a resolução de instâncias do nosso User a partir do identificador de sessão persistido.

```swift
struct UserSessionAuthenticator: SessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: String, for request: Request) -> EventLoopFuture<Void> {
        let user = User(email: sessionID)
        request.auth.login(user)
        return request.eventLoop.makeSucceededFuture(())
    }
}
```

Se você estiver usando `async`/`await`, pode usar o `AsyncSessionAuthenticator`:

```swift
struct UserSessionAuthenticator: AsyncSessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: String, for request: Request) async throws {
        let user = User(email: sessionID)
        request.auth.login(user)
    }
}
```

Como todas as informações que precisamos para inicializar nosso exemplo `User` estão contidas no identificador de sessão, podemos criar e logar o usuário de forma síncrona. Em uma aplicação real, você provavelmente usaria o identificador de sessão para realizar uma consulta ao banco de dados ou requisição de API para buscar o restante dos dados do usuário antes de autenticar.

Em seguida, vamos criar um bearer authenticator simples para realizar a autenticação inicial.

```swift
struct UserBearerAuthenticator: AsyncBearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        if bearer.token == "test" {
            let user = User(email: "hello@vapor.codes")
            request.auth.login(user)
        }
    }
}
```

Este authenticator autenticará um usuário com o e-mail `hello@vapor.codes` quando o bearer token `test` for enviado.

Finalmente, vamos combinar todas essas peças na sua aplicação.

```swift
// Criar grupo de rotas protegidas que requer autenticação de usuário.
let protected = app.routes.grouped([
    app.sessions.middleware,
    UserSessionAuthenticator(),
    UserBearerAuthenticator(),
    User.guardMiddleware(),
])

// Adicionar rota GET /me para ler o e-mail do usuário.
protected.get("me") { req -> String in
    try req.auth.require(User.self).email
}
```

`SessionsMiddleware` é adicionado primeiro para habilitar o suporte a sessões na aplicação. Mais informações sobre configuração de sessões podem ser encontradas na seção [API de Sessão](../advanced/sessions.md).

Em seguida, o `SessionAuthenticator` é adicionado. Ele lida com a autenticação do usuário se uma sessão estiver ativa.

Se a autenticação ainda não foi persistida na sessão, a requisição será encaminhada para o próximo authenticator. `UserBearerAuthenticator` verificará o bearer token e autenticará o usuário se for igual a `"test"`.

Finalmente, `User.guardMiddleware()` garantirá que `User` foi autenticado por um dos middleware anteriores. Se o usuário não foi autenticado, um erro será lançado.

Para testar esta rota, primeiro envie a seguinte requisição:

```http
GET /me HTTP/1.1
authorization: Bearer test
```

Isso fará com que `UserBearerAuthenticator` autentique o usuário. Uma vez autenticado, `UserSessionAuthenticator` persistirá o identificador do usuário no armazenamento de sessão e gerará um cookie. Use o cookie da resposta em uma segunda requisição à rota.

```http
GET /me HTTP/1.1
cookie: vapor_session=123
```

Desta vez, `UserSessionAuthenticator` autenticará o usuário e você deverá ver novamente o e-mail do usuário sendo retornado.

### Model Session Authenticatable

Modelos Fluent podem gerar `SessionAuthenticator`s conformando com `ModelSessionAuthenticatable`. Isso usará o identificador único do modelo como o identificador de sessão e realizará automaticamente uma consulta ao banco de dados para restaurar o modelo a partir da sessão.

```swift
import Fluent

final class User: Model { ... }

// Permitir que este modelo seja persistido em sessões.
extension User: ModelSessionAuthenticatable { }
```

Você pode adicionar `ModelSessionAuthenticatable` a qualquer modelo existente como uma conformidade vazia. Uma vez adicionado, um novo método estático estará disponível para criar um `SessionAuthenticator` para aquele modelo.

```swift
User.sessionAuthenticator()
```

Isso usará o banco de dados padrão da aplicação para resolver o usuário. Para especificar um banco de dados, passe o identificador.

```swift
User.sessionAuthenticator(.sqlite)
```

## Autenticação de Website

Websites são um caso especial para autenticação porque o uso de um navegador restringe como você pode anexar credenciais a uma requisição. Isso leva a dois cenários diferentes de autenticação:

* o login inicial via formulário
* chamadas subsequentes autenticadas com um cookie de sessão

O Vapor e o Fluent fornecem vários helpers para tornar isso transparente.

### Autenticação de Sessão

A autenticação de sessão funciona como descrito acima. Você precisa aplicar o middleware de sessão e o session authenticator a todas as rotas que seu usuário acessará. Isso inclui quaisquer rotas protegidas, quaisquer rotas públicas onde você ainda possa querer acessar o usuário caso esteja logado (para exibir um botão de conta, por exemplo) **e** rotas de login.

Você pode habilitar isso globalmente na sua aplicação em **configure.swift** assim:

```swift
app.middleware.use(app.sessions.middleware)
app.middleware.use(User.sessionAuthenticator())
```

Esses middleware fazem o seguinte:

* o middleware de sessões pega o cookie de sessão fornecido na requisição e o converte em uma sessão
* o session authenticator pega a sessão e verifica se há um usuário autenticado para aquela sessão. Se sim, o middleware autentica a requisição. Na resposta, o session authenticator verifica se a requisição tem um usuário autenticado e o salva na sessão para que esteja autenticado na próxima requisição.

!!! note "Nota"
    O cookie de sessão não é definido como `secure` e `httpOnly` por padrão. Consulte a [API de Sessão](../advanced/sessions.md#configuration) do Vapor para mais informações sobre como configurar cookies.

### Protegendo Rotas

Ao proteger rotas para uma API, você tradicionalmente retorna uma resposta HTTP com um código de status como **401 Unauthorized** se a requisição não estiver autenticada. No entanto, isso não é uma boa experiência para alguém usando um navegador. O Vapor fornece um `RedirectMiddleware` para qualquer tipo `Authenticatable` para usar neste cenário:

```swift
let protectedRoutes = app.grouped(User.redirectMiddleware(path: "/login?loginRequired=true"))
```

O objeto `RedirectMiddleware` também suporta passar uma closure que retorna o caminho de redirecionamento como uma `String` durante a criação para tratamento avançado de URL. Por exemplo, incluindo o caminho redirecionado como parâmetro de query no alvo de redirecionamento para gerenciamento de estado.

```swift
let redirectMiddleware = User.redirectMiddleware { req -> String in
  return "/login?authRequired=true&next=\(req.url.path)"
}
```

Isso funciona de forma similar ao `GuardMiddleware`. Quaisquer requisições para rotas registradas em `protectedRoutes` que não estejam autenticadas serão redirecionadas para o caminho fornecido. Isso permite que você diga aos seus usuários para fazer login, em vez de apenas fornecer um **401 Unauthorized**.

Certifique-se de incluir um Session Authenticator antes do `RedirectMiddleware` para garantir que o usuário autenticado seja carregado antes de passar pelo `RedirectMiddleware`.

```swift
let protectedRoutes = app.grouped([User.sessionAuthenticator(), redirectMiddleware])
```

### Login via Formulário

Para autenticar um usuário e requisições futuras com uma sessão, você precisa logar um usuário. O Vapor fornece um protocolo `ModelCredentialsAuthenticatable` para conformar. Isso lida com login via formulário. Primeiro conforme seu `User` com este protocolo:

```swift
extension User: ModelCredentialsAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
```

Isso é idêntico a `ModelAuthenticatable` e se você já conforma com ele, não precisa fazer mais nada. Em seguida, aplique este middleware `ModelCredentialsAuthenticator` à sua requisição POST do formulário de login:

```swift
let credentialsProtectedRoute = sessionRoutes.grouped(User.credentialsAuthenticator())
credentialsProtectedRoute.post("login", use: loginPostHandler)
```

Isso usa o credentials authenticator padrão para proteger a rota de login. Você deve enviar `username` e `password` na requisição POST. Você pode configurar seu formulário assim:

```html
 <form method="POST" action="/login">
    <label for="username">Username</label>
    <input type="text" id="username" placeholder="Username" name="username" autocomplete="username" required autofocus>
    <label for="password">Password</label>
    <input type="password" id="password" placeholder="Password" name="password" autocomplete="current-password" required>
    <input type="submit" value="Sign In">
</form>
```

O `CredentialsAuthenticator` extrai o `username` e `password` do corpo da requisição, encontra o usuário pelo nome de usuário e verifica a senha. Se a senha for válida, o middleware autentica a requisição. O `SessionAuthenticator` então autentica a sessão para requisições subsequentes.

## JWT

O [JWT](jwt.md) fornece um `JWTAuthenticator` que pode ser usado para autenticar JSON Web Tokens em requisições recebidas. Se você é novo em JWT, confira a [visão geral](jwt.md).

Primeiro, crie um tipo representando um payload JWT.

```swift
// Exemplo de payload JWT.
struct SessionToken: Content, Authenticatable, JWTPayload {

    // Constantes
    let expirationTime: TimeInterval = 60 * 15

    // Dados do Token
    var expiration: ExpirationClaim
    var userId: UUID

    init(userId: UUID) {
        self.userId = userId
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
    }

    init(with user: User) throws {
        self.userId = try user.requireID()
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
    }

    func verify(using algorithm: some JWTAlgorithm) throws {
        try expiration.verifyNotExpired()
    }
}
```

Em seguida, podemos definir uma representação dos dados contidos em uma resposta de login bem-sucedida. Por enquanto, a resposta terá apenas uma propriedade que é uma string representando um JWT assinado.

```swift
struct ClientTokenResponse: Content {
    var token: String
}
```

Usando nosso modelo para o token JWT e resposta, podemos usar uma rota de login protegida por senha que retorna um `ClientTokenResponse` e inclui um `SessionToken` assinado.

```swift
let passwordProtected = app.grouped(User.authenticator(), User.guardMiddleware())
passwordProtected.post("login") { req async throws -> ClientTokenResponse in
    let user = try req.auth.require(User.self)
    let payload = try SessionToken(with: user)
    return ClientTokenResponse(token: try await req.jwt.sign(payload))
}
```

Alternativamente, se você não quiser usar um authenticator, pode ter algo parecido com o seguinte.
```swift
app.post("login") { req async throws -> ClientTokenResponse in
    // Validar credenciais fornecidas para o usuário
    // Obter userId para o usuário fornecido
    let payload = try SessionToken(userId: userId)
    return ClientTokenResponse(token: try await req.jwt.sign(payload))
}
```

Ao conformar o payload com `Authenticatable` e `JWTPayload`, você pode gerar um route authenticator usando o método `authenticator()`. Adicione isso a um grupo de rotas para buscar e verificar automaticamente o JWT antes que sua rota seja chamada.

```swift
// Criar um grupo de rotas que requer o JWT SessionToken.
let secure = app.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())
```

Adicionar o [guard middleware](#guard-middleware) opcional exigirá que a autorização tenha sido bem-sucedida.

Dentro das rotas protegidas, você pode acessar o payload JWT autenticado usando `req.auth`.

```swift
// Retornar resposta ok se o token fornecido pelo usuário for válido.
secure.post("validateLoggedInUser") { req -> HTTPStatus in
    let sessionToken = try req.auth.require(SessionToken.self)
    print(sessionToken.userId)
    return .ok
}
```
