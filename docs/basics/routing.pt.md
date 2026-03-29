# Routing

Roteamento é o processo de encontrar o handler de requisição apropriado para uma requisição recebida. No centro do roteamento do Vapor está um router de alta performance baseado em trie-node do [RoutingKit](https://github.com/vapor/routing-kit).

## Visão Geral

Para entender como o roteamento funciona no Vapor, você deve primeiro entender alguns conceitos básicos sobre requisições HTTP. Veja o seguinte exemplo de requisição.

```http
GET /hello/vapor HTTP/1.1
host: vapor.codes
content-length: 0
```

Esta é uma requisição HTTP `GET` simples para a URL `/hello/vapor`. Este é o tipo de requisição HTTP que seu navegador faria se você apontasse para a seguinte URL.

```
http://vapor.codes/hello/vapor
```

### Método HTTP

A primeira parte da requisição é o método HTTP. `GET` é o método HTTP mais comum, mas existem vários que você usará com frequência. Esses métodos HTTP são frequentemente associados à semântica [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete).

|Método|CRUD|
|-|-|
|`GET`|Read|
|`POST`|Create|
|`PUT`|Replace|
|`PATCH`|Update|
|`DELETE`|Delete|

### Caminho da Requisição

Logo após o método HTTP está a URI da requisição. Ela consiste em um caminho começando com `/` e uma query string opcional após `?`. O método HTTP e o caminho são o que o Vapor usa para rotear requisições.

Após a URI está a versão HTTP seguida por zero ou mais headers e finalmente um body. Como esta é uma requisição `GET`, ela não possui um body.

### Métodos do Router

Vamos ver como esta requisição poderia ser tratada no Vapor.

```swift
app.get("hello", "vapor") { req in
    return "Hello, vapor!"
}
```

Todos os métodos HTTP comuns estão disponíveis como métodos em `Application`. Eles aceitam um ou mais argumentos de string que representam o caminho da requisição separado por `/`.

Note que você também poderia escrever isso usando `on` seguido do método.

```swift
app.on(.GET, "hello", "vapor") { ... }
```

Com esta rota registrada, o exemplo de requisição HTTP acima resultará na seguinte resposta HTTP.

```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, vapor!
```

### Parâmetros de Rota

Agora que roteamos uma requisição com sucesso baseada no método HTTP e caminho, vamos tentar tornar o caminho dinâmico. Observe que o nome "vapor" está codificado tanto no caminho quanto na resposta. Vamos tornar isso dinâmico para que você possa visitar `/hello/<qualquer nome>` e obter uma resposta.

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

Usando um componente de caminho prefixado com `:`, indicamos ao router que este é um componente dinâmico. Qualquer string fornecida aqui agora corresponderá a esta rota. Podemos então usar `req.parameters` para acessar o valor da string.

Se você executar o exemplo de requisição novamente, ainda receberá uma resposta que diz olá para vapor. No entanto, agora você pode incluir qualquer nome após `/hello/` e vê-lo incluído na resposta. Vamos tentar `/hello/swift`.

```http
GET /hello/swift HTTP/1.1
content-length: 0
```
```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, swift!
```

Agora que você entende os conceitos básicos, confira cada seção para aprender mais sobre parâmetros, grupos e mais.

## Rotas

Uma rota especifica um handler de requisição para um determinado método HTTP e caminho de URI. Ela também pode armazenar metadados adicionais.

### Métodos

Rotas podem ser registradas diretamente na sua `Application` usando vários helpers de métodos HTTP.

```swift
// responds to GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
	...
}
```

Handlers de rota suportam retornar qualquer coisa que seja `ResponseEncodable`. Isso inclui `Content`, uma closure `async` e quaisquer `EventLoopFuture`s onde o valor do future é `ResponseEncodable`.

Você pode especificar o tipo de retorno de uma rota usando `-> T` antes de `in`. Isso pode ser útil em situações onde o compilador não consegue determinar o tipo de retorno.

```swift
app.get("foo") { req -> String in
	return "bar"
}
```

Estes são os métodos helper de rota suportados:

- `get`
- `post`
- `patch`
- `put`
- `delete`

Além dos helpers de métodos HTTP, existe uma função `on` que aceita o método HTTP como parâmetro de entrada.

```swift
// responds to OPTIONS /foo/bar/baz
app.on(.OPTIONS, "foo", "bar", "baz") { req in
	...
}
```

### Componente de Caminho

Cada método de registro de rota aceita uma lista variádica de `PathComponent`. Este tipo é expressível por literal de string e tem quatro casos:

- Constant (`foo`)
- Parameter (`:foo`)
- Anything (`*`)
- Catchall (`**`)

#### Constant

Este é um componente de rota estático. Somente requisições com uma string exatamente correspondente nesta posição serão permitidas.

```swift
// responds to GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
	...
}
```

#### Parameter

Este é um componente de rota dinâmico. Qualquer string nesta posição será permitida. Um componente de caminho parameter é especificado com o prefixo `:`. A string após o `:` será usada como nome do parâmetro. Você pode usar o nome para buscar o valor do parâmetro na requisição posteriormente.

```swift
// responds to GET /foo/bar/baz
// responds to GET /foo/qux/baz
// ...
app.get("foo", ":bar", "baz") { req in
	...
}
```

#### Anything

Isso é muito similar ao parameter, exceto que o valor é descartado. Este componente de caminho é especificado apenas como `*`.

```swift
// responds to GET /foo/bar/baz
// responds to GET /foo/qux/baz
// ...
app.get("foo", "*", "baz") { req in
	...
}
```

#### Catchall

Este é um componente de rota dinâmico que corresponde a um ou mais componentes. É especificado usando apenas `**`. Qualquer string nesta posição ou posições posteriores será correspondida na requisição.

```swift
// responds to GET /foo/bar
// responds to GET /foo/bar/baz
// ...
app.get("foo", "**") { req in
    ...
}
```

### Parâmetros

Ao usar um componente de caminho parameter (prefixado com `:`), o valor da URI naquela posição será armazenado em `req.parameters`. Você pode usar o nome do componente de caminho para acessar o valor.

```swift
// responds to GET /hello/foo
// responds to GET /hello/bar
// ...
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

!!! tip
    Podemos ter certeza de que `req.parameters.get` nunca retornará `nil` aqui, pois nosso caminho de rota inclui `:name`. No entanto, se você estiver acessando parâmetros de rota em middleware ou em código acionado por múltiplas rotas, você vai querer lidar com a possibilidade de `nil`.

!!! tip
    Se você quiser recuperar parâmetros de query da URL, ex: `/hello/?name=foo`, você precisa usar as APIs de Conteúdo do Vapor para manipular dados codificados em URL na query string da URL. Veja a [referência de `Content`](content.md) para mais detalhes.

`req.parameters.get` também suporta a conversão automática do parâmetro para tipos `LosslessStringConvertible`.

```swift
// responds to GET /number/42
// responds to GET /number/1337
// ...
app.get("number", ":x") { req -> String in
	guard let int = req.parameters.get("x", as: Int.self) else {
		throw Abort(.badRequest)
	}
	return "\(int) is a great number"
}
```

Os valores da URI correspondidos pelo Catchall (`**`) serão armazenados em `req.parameters` como `[String]`. Você pode usar `req.parameters.getCatchall` para acessar esses componentes.

```swift
// responds to GET /hello/foo
// responds to GET /hello/foo/bar
// ...
app.get("hello", "**") { req -> String in
    let name = req.parameters.getCatchall().joined(separator: " ")
    return "Hello, \(name)!"
}
```

### Body Streaming

Ao registrar uma rota usando o método `on`, você pode especificar como o body da requisição deve ser tratado. Por padrão, bodies de requisição são coletados na memória antes de chamar seu handler. Isso é útil pois permite que a decodificação de conteúdo da requisição seja síncrona, mesmo que sua aplicação leia requisições recebidas de forma assíncrona.

Por padrão, o Vapor limitará a coleta de body streaming a 16KB de tamanho. Você pode configurar isso usando `app.routes`.

```swift
// Increases the streaming body collection limit to 500kb
app.routes.defaultMaxBodySize = "500kb"
```

Se um body streaming sendo coletado exceder o limite configurado, um erro `413 Payload Too Large` será lançado.

Para configurar a estratégia de coleta de body da requisição para uma rota individual, use o parâmetro `body`.

```swift
// Collects streaming bodies (up to 1mb in size) before calling this route.
app.on(.POST, "listings", body: .collect(maxSize: "1mb")) { req in
    // Handle request.
}
```

Se um `maxSize` for passado para `collect`, ele substituirá o padrão da aplicação para aquela rota. Para usar o padrão da aplicação, omita o argumento `maxSize`.

Para requisições grandes, como upload de arquivos, coletar o body da requisição em um buffer pode potencialmente sobrecarregar a memória do seu sistema. Para evitar que o body da requisição seja coletado, use a estratégia `stream`.

```swift
// Request body will not be collected into a buffer.
app.on(.POST, "upload", body: .stream) { req in
    ...
}
```

Quando o body da requisição é transmitido via streaming, `req.body.data` será `nil`. Você deve usar `req.body.drain` para manipular cada chunk conforme é enviado para sua rota.

### Roteamento Case Insensitive

O comportamento padrão para roteamento é sensível a maiúsculas e minúsculas e preserva o caso. Componentes de caminho `Constant` podem alternativamente ser tratados de forma insensível a maiúsculas e minúsculas e preservando o caso para fins de roteamento; para habilitar este comportamento, configure antes da inicialização da aplicação:
```swift
app.routes.caseInsensitive = true
```
Nenhuma alteração é feita na requisição de origem; os handlers de rota receberão os componentes do caminho da requisição sem modificação.


### Visualizando Rotas

Você pode acessar as rotas da sua aplicação tornando o serviço `Routes` ou usando `app.routes`.

```swift
print(app.routes.all) // [Route]
```

O Vapor também vem com um comando `routes` que imprime todas as rotas disponíveis em uma tabela formatada em ASCII.

```sh
$ swift run App routes
+--------+----------------+
| GET    | /              |
+--------+----------------+
| GET    | /hello         |
+--------+----------------+
| GET    | /todos         |
+--------+----------------+
| POST   | /todos         |
+--------+----------------+
| DELETE | /todos/:todoID |
+--------+----------------+
```

### Metadados

Todos os métodos de registro de rota retornam a `Route` criada. Isso permite que você adicione metadados ao dicionário `userInfo` da rota. Existem alguns métodos padrão disponíveis, como adicionar uma descrição.

```swift
app.get("hello", ":name") { req in
	...
}.description("says hello")
```

## Grupos de Rotas

O agrupamento de rotas permite que você crie um conjunto de rotas com um prefixo de caminho ou middleware específico. O agrupamento suporta tanto uma sintaxe de builder quanto de closure.

Todos os métodos de agrupamento retornam um `RouteBuilder`, o que significa que você pode infinitamente misturar, combinar e aninhar seus grupos com outros métodos de construção de rotas.

### Prefixo de Caminho

Grupos de rotas com prefixo de caminho permitem que você adicione um ou mais componentes de caminho a um grupo de rotas.

```swift
let users = app.grouped("users")
// GET /users
users.get { req in
    ...
}
// POST /users
users.post { req in
    ...
}
// GET /users/:id
users.get(":id") { req in
    let id = req.parameters.get("id")!
    ...
}
```

Qualquer componente de caminho que você pode passar para métodos como `get` ou `post` pode ser passado para `grouped`. Existe também uma sintaxe alternativa baseada em closure.

```swift
app.group("users") { users in
    // GET /users
    users.get { req in
        ...
    }
    // POST /users
    users.post { req in
        ...
    }
    // GET /users/:id
    users.get(":id") { req in
        let id = req.parameters.get("id")!
        ...
    }
}
```

Aninhar grupos de rotas com prefixo de caminho permite que você defina APIs CRUD de forma concisa.

```swift
app.group("users") { users in
    // GET /users
    users.get { ... }
    // POST /users
    users.post { ... }

    users.group(":id") { user in
        // GET /users/:id
        user.get { ... }
        // PATCH /users/:id
        user.patch { ... }
        // PUT /users/:id
        user.put { ... }
    }
}
```

### Middleware

Além de prefixar componentes de caminho, você também pode adicionar middleware a grupos de rotas.

```swift
app.get("fast-thing") { req in
    ...
}
app.group(RateLimitMiddleware(requestsPerMinute: 5)) { rateLimited in
    rateLimited.get("slow-thing") { req in
        ...
    }
}
```


Isso é especialmente útil para proteger subconjuntos das suas rotas com diferentes middlewares de autenticação.

```swift
app.post("login") { ... }
let auth = app.grouped(AuthMiddleware())
auth.get("dashboard") { ... }
auth.get("logout") { ... }
```

## Redirecionamentos

Redirecionamentos são úteis em vários cenários, como encaminhar localizações antigas para novas para SEO, redirecionar um usuário não autenticado para a página de login ou manter compatibilidade retroativa com a nova versão da sua API.

Para redirecionar uma requisição, use:

```swift
req.redirect(to: "/some/new/path")
```

Você também pode especificar o tipo de redirecionamento, por exemplo, para redirecionar uma página permanentemente (para que seu SEO seja atualizado corretamente) use:

```swift
req.redirect(to: "/some/new/path", redirectType: .permanent)
```

Os diferentes `Redirect`s são:

* `.permanent` - retorna um redirecionamento **301 Permanent**
* `.normal` - retorna um redirecionamento **303 see other**. Este é o padrão do Vapor e diz ao client para seguir o redirecionamento com uma requisição **GET**.
* `.temporary` - retorna um redirecionamento **307 Temporary**. Isso diz ao client para preservar o método HTTP usado na requisição.

> Para escolher o código de status de redirecionamento adequado, confira [a lista completa](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes#3xx_redirection)
