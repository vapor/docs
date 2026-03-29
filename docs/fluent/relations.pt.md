# Relations

A [API de model](model.md) do Fluent ajuda você a criar e manter referências entre seus models através de relações. Três tipos de relações são suportados:

- [Parent](#parent) / [Child](#optional-child) (Um-para-um)
- [Parent](#parent) / [Children](#children) (Um-para-muitos)
- [Siblings](#siblings) (Muitos-para-muitos)

## Parent

A relação `@Parent` armazena uma referência à propriedade `@ID` de outro model.

```swift
final class Planet: Model {
    // Example of a parent relation.
    @Parent(key: "star_id")
    var star: Star
}
```

`@Parent` contém um `@Field` chamado `id` que é usado para definir e atualizar a relação.

```swift
// Set parent relation id
earth.$star.id = sun.id
```

Por exemplo, o inicializador de `Planet` ficaria assim:

```swift
init(name: String, starID: Star.IDValue) {
    self.name = name
    // ...
    self.$star.id = starID
}
```

O parâmetro `key` define a chave do campo a ser usado para armazenar o identificador do pai. Assumindo que `Star` tem um identificador `UUID`, esta relação `@Parent` é compatível com a seguinte [definição de campo](schema.md#field).

```swift
.field("star_id", .uuid, .required, .references("star", "id"))
```

Note que a constraint [`.references`](schema.md#field-constraint) é opcional. Veja [schema](schema.md) para mais informações.

### Optional Parent

A relação `@OptionalParent` armazena uma referência opcional à propriedade `@ID` de outro model. Funciona de forma similar a `@Parent`, mas permite que a relação seja `nil`.

```swift
final class Planet: Model {
    // Example of an optional parent relation.
    @OptionalParent(key: "star_id")
    var star: Star?
}
```

A definição de campo é similar à do `@Parent`, exceto que a constraint `.required` deve ser omitida.

```swift
.field("star_id", .uuid, .references("star", "id"))
```

### Codificação e Decodificação de Parents

Uma coisa a observar ao trabalhar com relações `@Parent` é a maneira como você as envia e recebe. Por exemplo, em JSON, um `@Parent` para um model `Planet` pode ser assim:

```json
{
    "id": "A616B398-A963-4EC7-9D1D-B1AA8A6F1107",
    "star": {
        "id": "A1B2C3D4-1234-5678-90AB-CDEF12345678"
    }
}
```

Note como a propriedade `star` é um objeto em vez do ID que você poderia esperar. Ao enviar o model como body HTTP, ele precisa corresponder a isso para que a decodificação funcione. Por esta razão, recomendamos fortemente usar um DTO para representar o model ao enviá-lo pela rede. Por exemplo:

```swift
struct PlanetDTO: Content {
    var id: UUID?
    var name: String
    var star: Star.IDValue
}
```

Então você pode decodificar o DTO e convertê-lo em um model:

```swift
let planetData = try req.content.decode(PlanetDTO.self)
let planet = Planet(id: planetData.id, name: planetData.name, starID: planetData.star)
try await planet.create(on: req.db)
```

O mesmo se aplica ao retornar o model para clients. Seus clients precisam ser capazes de lidar com a estrutura aninhada, ou você precisa converter o model em um DTO antes de retorná-lo. Para mais informações sobre DTOs, veja a [documentação de Model](model.md#data-transfer-object)

## Optional Child

A propriedade `@OptionalChild` cria uma relação um-para-um entre os dois models. Ela não armazena nenhum valor no model raiz.

```swift
final class Planet: Model {
    // Example of an optional child relation.
    @OptionalChild(for: \.$planet)
    var governor: Governor?
}
```

O parâmetro `for` aceita um key path para uma relação `@Parent` ou `@OptionalParent` que referencia o model raiz.

Um novo model pode ser adicionado a esta relação usando o método `create`.

```swift
// Example of adding a new model to a relation.
let jane = Governor(name: "Jane Doe")
try await mars.$governor.create(jane, on: database)
```

Isso definirá o id do pai no model filho automaticamente.

Como esta relação não armazena nenhum valor, nenhuma entrada de schema do banco de dados é necessária para o model raiz.

A natureza um-para-um da relação deve ser garantida no schema do model filho usando uma constraint `.unique` na coluna que referencia o model pai.

```swift
try await database.schema(Governor.schema)
    .id()
    .field("name", .string, .required)
    .field("planet_id", .uuid, .required, .references("planets", "id"))
    // Example of unique constraint
    .unique(on: "planet_id")
    .create()
```
!!! warning
    Omitir a constraint unique no campo de ID do pai no schema do filho pode levar a resultados imprevisíveis.
    Se não houver constraint de unicidade, a tabela filha pode acabar contendo mais de uma linha filha para qualquer pai dado; neste caso, uma propriedade `@OptionalChild` ainda só será capaz de acessar um filho por vez, sem maneira de controlar qual filho é carregado. Se você pode precisar armazenar múltiplas linhas filhas para qualquer pai dado, use `@Children` em vez disso.

## Children

A propriedade `@Children` cria uma relação um-para-muitos entre dois models. Ela não armazena nenhum valor no model raiz.

```swift
final class Star: Model {
    // Example of a children relation.
    @Children(for: \.$star)
    var planets: [Planet]
}
```

O parâmetro `for` aceita um key path para uma relação `@Parent` ou `@OptionalParent` que referencia o model raiz. Neste caso, estamos referenciando a relação `@Parent` do [exemplo](#parent) anterior.

Novos models podem ser adicionados a esta relação usando o método `create`.

```swift
// Example of adding a new model to a relation.
let earth = Planet(name: "Earth")
try await sun.$planets.create(earth, on: database)
```

Isso definirá o id do pai no model filho automaticamente.

Como esta relação não armazena nenhum valor, nenhuma entrada de schema do banco de dados é necessária.

## Siblings

A propriedade `@Siblings` cria uma relação muitos-para-muitos entre dois models. Ela faz isso através de um model terciário chamado pivot.

Vamos dar uma olhada em um exemplo de uma relação muitos-para-muitos entre `Planet` e `Tag`.

```swift
enum PlanetTagStatus: String, Codable { case accepted, pending }

// Example of a pivot model.
final class PlanetTag: Model {
    static let schema = "planet+tag"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "planet_id")
    var planet: Planet

    @Parent(key: "tag_id")
    var tag: Tag

    @OptionalField(key: "comments")
    var comments: String?

    @OptionalEnum(key: "status")
    var status: PlanetTagStatus?

    init() { }

    init(id: UUID? = nil, planet: Planet, tag: Tag, comments: String?, status: PlanetTagStatus?) throws {
        self.id = id
        self.$planet.id = try planet.requireID()
        self.$tag.id = try tag.requireID()
        self.comments = comments
        self.status = status
    }
}
```

Qualquer model que inclua pelo menos duas relações `@Parent`, uma para cada model a ser relacionado, pode ser usado como pivot. O model pode conter propriedades adicionais, como seu ID, e pode até conter outras relações `@Parent`.

Adicionar uma constraint [unique](schema.md#unique) ao model pivot pode ajudar a prevenir entradas redundantes. Veja [schema](schema.md) para mais informações.

```swift
// Disallows duplicate relations.
.unique(on: "planet_id", "tag_id")
```

Uma vez que o pivot é criado, use a propriedade `@Siblings` para criar a relação.

```swift
final class Planet: Model {
    // Example of a siblings relation.
    @Siblings(through: PlanetTag.self, from: \.$planet, to: \.$tag)
    public var tags: [Tag]
}
```

A propriedade `@Siblings` requer três parâmetros:

- `through`: O tipo do model pivot.
- `from`: Key path do pivot para a relação pai que referencia o model raiz.
- `to`: Key path do pivot para a relação pai que referencia o model relacionado.

A propriedade `@Siblings` inversa no model relacionado completa a relação.

```swift
final class Tag: Model {
    // Example of a siblings relation.
    @Siblings(through: PlanetTag.self, from: \.$tag, to: \.$planet)
    public var planets: [Planet]
}
```

### Siblings Attach

A propriedade `@Siblings` possui métodos para adicionar e remover models da relação.

Use o método `attach()` para adicionar um único model ou um array de models à relação. Models pivot são criados e salvos automaticamente conforme necessário. Uma closure de callback pode ser especificada para popular propriedades adicionais de cada pivot criado:

```swift
let earth: Planet = ...
let inhabited: Tag = ...
// Adds the model to the relation.
try await earth.$tags.attach(inhabited, on: database)
// Populate pivot attributes when establishing the relation.
try await earth.$tags.attach(inhabited, on: database) { pivot in
    pivot.comments = "This is a life-bearing planet."
    pivot.status = .accepted
}
// Add multiple models with attributes to the relation.
let volcanic: Tag = ..., oceanic: Tag = ...
try await earth.$tags.attach([volcanic, oceanic], on: database) { pivot in
    pivot.comments = "This planet has a tag named \(pivot.$tag.name)."
    pivot.status = .pending
}
```

Ao anexar um único model, você pode usar o parâmetro `method` para escolher se a relação deve ser verificada antes de salvar.

```swift
// Only attaches if the relation doesn't already exist.
try await earth.$tags.attach(inhabited, method: .ifNotExists, on: database)
```

Use o método `detach` para remover um model da relação. Isso deleta o model pivot correspondente.

```swift
// Removes the model from the relation.
try await earth.$tags.detach(inhabited, on: database)
```

Você pode verificar se um model está relacionado ou não usando o método `isAttached`.

```swift
// Checks if the models are related.
earth.$tags.isAttached(to: inhabited)
```

## Get

Use o método `get(on:)` para buscar o valor de uma relação.

```swift
// Fetches all of the sun's planets.
sun.$planets.get(on: database).map { planets in
    print(planets)
}

// Or

let planets = try await sun.$planets.get(on: database)
print(planets)
```

Use o parâmetro `reload` para escolher se a relação deve ser buscada novamente do banco de dados caso já tenha sido carregada.

```swift
try await sun.$planets.get(reload: true, on: database)
```

## Query

Use o método `query(on:)` em uma relação para criar um query builder para os models relacionados.

```swift
// Fetch all of the sun's planets that have a naming starting with M.
try await sun.$planets.query(on: database).filter(\.$name =~ "M").all()
```

Veja [query](query.md) para mais informações.

## Eager Loading

O query builder do Fluent permite que você pré-carregue as relações de um model quando ele é buscado do banco de dados. Isso é chamado de eager loading e permite que você acesse relações sincronamente sem precisar chamar [`get`](#get) primeiro.

Para fazer eager load de uma relação, passe um key path para a relação ao método `with` no query builder.

```swift
// Example of eager loading.
Planet.query(on: database).with(\.$star).all().map { planets in
    for planet in planets {
        // `star` is accessible synchronously here
        // since it has been eager loaded.
        print(planet.star.name)
    }
}

// Or

let planets = try await Planet.query(on: database).with(\.$star).all()
for planet in planets {
    // `star` is accessible synchronously here
    // since it has been eager loaded.
    print(planet.star.name)
}
```

No exemplo acima, um key path para a relação [`@Parent`](#parent) chamada `star` é passado para `with`. Isso faz com que o query builder faça uma query adicional depois que todos os planetas são carregados para buscar todas as suas estrelas relacionadas. As estrelas então ficam acessíveis sincronamente via a propriedade `@Parent`.

Cada relação com eager load requer apenas uma query adicional, não importa quantos models são retornados. Eager loading só é possível com os métodos `all` e `first` do query builder.


### Nested Eager Load

O método `with` do query builder permite que você faça eager load de relações no model sendo consultado. No entanto, você também pode fazer eager load de relações em models relacionados.

```swift
let planets = try await Planet.query(on: database).with(\.$star) { star in
    star.with(\.$galaxy)
}.all()
for planet in planets {
    // `star.galaxy` is accessible synchronously here
    // since it has been eager loaded.
    print(planet.star.galaxy.name)
}
```

O método `with` aceita uma closure opcional como segundo parâmetro. Esta closure aceita um eager load builder para a relação escolhida. Não há limite para quão profundamente o eager loading pode ser aninhado.

## Lazy Eager Loading

Caso você já tenha recuperado o model pai e queira carregar uma de suas relações, você pode usar o método `get(reload:on:)` para esse propósito. Isso buscará o model relacionado do banco de dados (ou cache, se disponível) e permitirá que ele seja acessado como uma propriedade local.

```swift
planet.$star.get(on: database).map {
    print(planet.star.name)
}

// Or

try await planet.$star.get(on: database)
print(planet.star.name)
```

Caso queira garantir que os dados que você recebe não sejam puxados do cache, use o parâmetro `reload:`.

```swift
try await planet.$star.get(reload: true, on: database)
print(planet.star.name)
```

Para verificar se uma relação já foi carregada, use a propriedade `value`.

```swift
if planet.$star.value != nil {
    // Relation has been loaded.
    print(planet.star.name)
} else {
    // Relation has not been loaded.
    // Attempting to access planet.star will fail.
}
```

Se você já tem o model relacionado em uma variável, pode definir a relação manualmente usando a propriedade `value` mencionada acima.

```swift
planet.$star.value = star
```

Isso anexará o model relacionado ao pai como se tivesse sido carregado via eager loading ou lazy loading sem uma query adicional ao banco de dados.
