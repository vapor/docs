# Décoder/encoder du contenu

L'API de contenu de Vapor vous permet aisément d'encoder et décoder des structs se conformant au protocole Codable depuis ou vers des messages HTTP. L'encodage [JSON](https://tools.ietf.org/html/rfc7159) est utilisé par défaut, proposant un support prêt à l'emploi des [formulaires URL-Encodés](https://en.wikipedia.org/wiki/Percent-encoding#The_application/x-www-form-urlencoded_type) ainsi que de [Multipart](https://tools.ietf.org/html/rfc2388). Cette API est également configurable, vous permettant d'ajouter, modifier, ou remplacer les stratégies d'encodage pour des types de contenu HTML spécifiques.

## Vue d'ensemble

Pour comprendre le fonctionnement de l'API contenu de Vapor, il faut d'abord comprendre quelques bases concernant les messages HTTP. Observez la requête d'exemple suivante.

```http
POST /greeting HTTP/1.1
content-type: application/json
content-length: 18

{"hello": "world"}
```

Cette requête indique qu'elle contient des données encodées au format JSON grâce à l'entête `content-type` indiquant le type de média `application/json`. Comme spécifié, les entêtes sont suivies de données au format JSON dans le corps de la requête.

### Struct de contenu

La première étape pour décoder ce message HTTP est de créer un type conforme à Codable qui correspond à la structure de données attendue. 

```swift
struct Greeting: Content {
    var hello: String
}
```

Conformer un type à `Content` le rendra automatiquement conforme à `Codable`, ajoutant par ailleurs des mécanismes additionnels pour travailler avec l'API de contenu.

Une fois votre structure de contenu définie, vous pouvez y décoder les valeurs provenant de la requête via `req.content`.

```swift
app.post("greeting") { req in 
    let greeting = try req.content.decode(Greeting.self)
    print(greeting.hello) // "world"
    return HTTPStatus.ok
}
```

La méthode decode se base sur le type de contenu indiqué dans les entêtes de la requête pour trouver un décodeur approprié au format reçu. Si aucun décodeur ne correspond, ou que la requête n'indique pas d'entête content-type, une erreur `415` sera levée.

Cela signifie que notre route acceptera automatiquement tous les autres types de contenus supportés, comme par exemple un formulaire url-encodé :

```http
POST /greeting HTTP/1.1
content-type: application/x-www-form-urlencoded
content-length: 11

hello=world
```

Concernant l'upload de fichiers, la propriété correspondante dans votre structure de contenu doit être de type `Data` :

```swift
struct Profile: Content {
    var name: String
    var email: String
    var image: Data
}
```

### Types de média supportés

Vous trouverez ci-dessous les types de média que l'API contenu supporte par défaut.

|nom|valeur d'entête|type de média|
|-|-|-|
|JSON|application/json|`.json`|
|Multipart|multipart/form-data|`.formData`|
|URL-Encoded Form|application/x-www-form-urlencoded|`.urlEncodedForm`|
|Plaintext|text/plain|`.plainText`|
|HTML|text/html|`.html`|

Tous les types de média ne supportent pas systématiquement toutes les fonctionnalités de `Codable`. Par exemple, JSON n'offre pas de support pour les fragments à la racine (le JSON doit être un objet ou un tableau, pas une chaîne par exemple) et Plaintext ne propose pas de support pour les données imbriquées.

## QueryString

L'API contenu de Vapor gère les données URL-encodées de la QueryString. 

### Décodage

Pour comprendre comment fonctionne le décodage d'une QueryString URL-encodée, observez la requête d'exemple suivante.

```http
GET /hello?name=Vapor HTTP/1.1
content-length: 0
```

De la même façon que l'on a géré le décodage de contenu du corps de la requête, la première étape d'analyse d'une QueryString consiste à créer une `struct` reflétant la structure attendue des données.

```swift
struct Hello: Content {
    var name: String?
}
```

Notez ici que `name` est un `String` optionnel puisque de par leur nature, les QueryString elles-mêmes sont facultatives. Si vous souhaitez rendre un paramètre obligatoire, utilisez plutôt un paramètre de route.

Maintenant que nous avons notre struct conforme à `Content` pour la QueryString attendue pour cette route, vous pouvez la décoder.

```swift
app.get("hello") { req -> String in 
    let hello = try req.query.decode(Hello.self)
    return "Hello, \(hello.name ?? "Anonymous")"
}
```

Cette route émettra la réponse suivante pour la requête d'exemple définie plus haut :

```http
HTTP/1.1 200 OK
content-length: 12

Hello, Vapor
```

Si la QueryString était omise, comme dans la requête suivante, le nom "Anonymous" serait utilisé à la place.

```http
GET /hello HTTP/1.1
content-length: 0
```

### Valeur unique

En plus de pouvoir décoder une struct conforme à `Content`, Vapor permet également de récupérer des valeurs isolées de la QueryString en utilisant la syntaxe subscript :

```swift
let name: String? = req.query["name"]
```

## Hooks

Vapor invoquera automatiquement les méthodes `beforeEncode` et `afterDecode` sur les types qui se conforment à `Content`. Les implémentations par défaut ne font rien, mais vous pouvez utiliser ces méthodes pour exécuter de la logique personnalisée.

```swift
// Sera exécuté après que le contenu ait été décodé. Le mot clé `mutating` n'est requis que pour les structs, pas pour les classes.
mutating func afterDecode() throws {
    // Le paramètre name ne sera pas forcément présent dans la requête, mais si c'est le cas, sa valeur associée ne doit pas être vide.
    self.name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let name = self.name, name.isEmpty {
        throw Abort(.badRequest, reason: "Name must not be empty.")
    }
}

// Sera exécuté avant que le contenu ne soit encodé. Le mot clé `mutating` n'est requis que pour les structs, pas pour les classes.
mutating func beforeEncode() throws {
    // Il faut *toujours* retourner un nom, dont la valeur ne doit pas être vide.
    guard 
        let name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines), 
        !name.isEmpty 
    else {
        throw Abort(.badRequest, reason: "Name must not be empty.")
    }
    self.name = name
}
```

## Surcharger les encodeurs/décodeurs par défaut

Les encodeurs et decodeurs utilisés par l'API contenu de Vapor peuvent être configurés. 

### Configuration globale

`ContentConfiguration.global` vous permet de remplacer les encodeurs/décodeurs que Vapor utilise par défaut. Cela vous servira pour modifier la façon dont toute votre application analyse et sérialise les données.

```swift
// Crée un nouvel encodeur qui utilise des dates au format unix-timestamp.
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .secondsSince1970

// Remplace l'encodeur global utilisé pour le type de média `.json`.
ContentConfiguration.global.use(encoder: encoder, for: .json)
```

Les modifications de `ContentConfiguration` se font généralement dans le fichier `configure.swift`. 

### Configuration ponctuelle

Les appels aux méthode d'encodage/décodage comme `req.content.decode` peuvent recevoir en paramètre un codeur, pour traiter des cas particuliers.

```swift
// Crée une nouveau décodeur JSON utilisant le format de date unix-timestamp.
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .secondsSince1970

// Décode la structure de données Hello avec notre décodeur personnalisé.
let hello = try req.content.decode(Hello.self, using: decoder)
```

## Codeurs personnalisés

Vos applications et packages tiers peuvent ajouter du support pour des types de média que Vapor n'intègre pas, en développant vos codeurs personnalisés.

### Contenu

Vapor définit deux protocoles pour les codeurs qui doivent gérer du contenu provenant de corps de messages HTTP : `ContentDecoder` et `ContentEncoder`.

```swift
public protocol ContentEncoder {
    func encode<E>(_ encodable: E, to body: inout ByteBuffer, headers: inout HTTPHeaders) throws
        where E: Encodable
}

public protocol ContentDecoder {
    func decode<D>(_ decodable: D.Type, from body: ByteBuffer, headers: HTTPHeaders) throws -> D
        where D: Decodable
}
```

Se conformer à ces protocoles permettra à vos codeurs personnalisés de s'enregistrer dans l'objet `ContentConfiguration` comme nous l'avons vu plus haut.

### QueryString

Vapor définit deux protocoles pour les codeurs qui doivent traiter du contenu provenant de QueryString : `URLQueryDecoder` et `URLQueryEncoder`.

```swift
public protocol URLQueryDecoder {
    func decode<D>(_ decodable: D.Type, from url: URI) throws -> D
        where D: Decodable
}

public protocol URLQueryEncoder {
    func encode<E>(_ encodable: E, to url: inout URI) throws
        where E: Encodable
}
```

Se conformer à ces protocoles permettra à vos codeurs personnalisés de s'enregistrer dans l'objet `ContentConfiguration` via les méthodes `use(urlEncoder:)` et `use(urlDecoder:)`.

### `(Async)ResponseEncodable` personnalisée

Une autre approche serait d'implémenter le protocole `(Async)ResponseEncodable` sur vos types de données. Examinez cet exemple trivial de type `HTML` qui ne fait qu'encapsuler une chaîne de caractères :

```swift
struct HTML {
  let value: String
}
```

Son implémentation de `ResponseEncodable` ressemblerait à ceci :

```swift
extension HTML: ResponseEncodable {
  public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/html")
    return request.eventLoop.makeSucceededFuture(.init(
      status: .ok, headers: headers, body: .init(string: value)
    ))
  }
}
```

Ou si vous utilisez `async`/`await`, vous utiliserez plutôt le protocole `AsyncResponseEncodable` :

```swift
extension HTML: AsyncResponseEncodable {
  public func encodeResponse(for request: Request) async throws -> Response {
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/html")
    return .init(status: .ok, headers: headers, body: .init(string: value))
  }
}
```

Remarquez que cela vous permet de modifier l'entête `Content-Type`. Consultez le [chapitre `HTTPHeaders`](https://api.vapor.codes/vapor/documentation/vapor/response/headers) pour plus de détails.

Vous pouvez ensuite utiliser le type `HTML` en tant que réponse dans vos routes :

```swift
app.get { _ in
  HTML(value: """
  <html>
    <body>
      <h1>Hello, World!</h1>
    </body>
  </html>
  """)
}
```
