# Query

A API de query do Fluent permite que você crie, leia, atualize e delete models do banco de dados. Ela suporta filtragem de resultados, joins, chunking, agregações e mais.

```swift
// An example of Fluent's query API.
let planets = try await Planet.query(on: database)
    .filter(\.$type == .gasGiant)
    .sort(\.$name)
    .with(\.$star)
    .all()
```

Query builders estão vinculados a um único tipo de model e podem ser criados usando o método estático [`query`](model.md#query). Eles também podem ser criados passando o tipo do model para o método `query` em um objeto database.

```swift
// Also creates a query builder.
database.query(Planet.self)
```

!!! note
    Você deve importar `import Fluent` no arquivo com suas queries para que o compilador possa ver as funções auxiliares do Fluent.

## All

O método `all()` retorna um array de models.

```swift
// Fetches all planets.
let planets = try await Planet.query(on: database).all()
```

O método `all` também suporta buscar apenas um único campo do conjunto de resultados.

```swift
// Fetches all planet names.
let names = try await Planet.query(on: database).all(\.$name)
```

### First

O método `first()` retorna um único model opcional. Se a query resultar em mais de um model, apenas o primeiro é retornado. Se a query não tiver resultados, `nil` é retornado.

```swift
// Fetches the first planet named Earth.
let earth = try await Planet.query(on: database)
    .filter(\.$name == "Earth")
    .first()
```

!!! tip
    Se estiver usando `EventLoopFuture`s, este método pode ser combinado com [`unwrap(or:)`](../basics/errors.md#abort) para retornar um model não-opcional ou lançar um erro.

## Filter

O método `filter` permite que você restrinja os models incluídos no conjunto de resultados. Existem várias sobrecargas para este método.

### Value Filter

O `filter` mais comumente usado aceita uma expressão de operador com um valor.

```swift
// An example of field value filtering.
Planet.query(on: database).filter(\.$type == .gasGiant)
```

Essas expressões de operador aceitam um key path de campo no lado esquerdo e um valor no lado direito. O valor fornecido deve corresponder ao tipo de valor esperado do campo e é vinculado à query resultante. Expressões de filtro são fortemente tipadas, permitindo o uso da sintaxe de ponto inicial.

Abaixo está uma lista de todos os operadores de valor suportados.

|Operador|Descrição|
|-|-|
|`==`|Igual a.|
|`!=`|Diferente de.|
|`>=`|Maior ou igual a.|
|`>`|Maior que.|
|`<`|Menor que.|
|`<=`|Menor ou igual a.|

### Field Filter

O método `filter` suporta comparar dois campos.

```swift
// All users with same first and last name.
User.query(on: database)
    .filter(\.$firstName == \.$lastName)
```

Filtros de campo suportam os mesmos operadores que [filtros de valor](#value-filter).

### Subset Filter

O método `filter` suporta verificar se o valor de um campo existe em um conjunto de valores fornecido.

```swift
// All planets with either gas giant or small rocky type.
Planet.query(on: database)
    .filter(\.$type ~~ [.gasGiant, .smallRocky])
```

O conjunto de valores fornecido pode ser qualquer `Collection` do Swift cujo tipo `Element` corresponda ao tipo de valor do campo.

Abaixo está uma lista de todos os operadores de subset suportados.

|Operador|Descrição|
|-|-|
|`~~`|Valor no conjunto.|
|`!~`|Valor não está no conjunto.|

### Contains Filter

O método `filter` suporta verificar se o valor de um campo string contém uma determinada substring.

```swift
// All planets whose name starts with the letter M
Planet.query(on: database)
    .filter(\.$name =~ "M")
```

Esses operadores estão disponíveis apenas em campos com valores string.

Abaixo está uma lista de todos os operadores de contains suportados.

|Operador|Descrição|
|-|-|
|`~~`|Contém substring.|
|`!~`|Não contém substring.|
|`=~`|Corresponde ao prefixo.|
|`!=~`|Não corresponde ao prefixo.|
|`~=`|Corresponde ao sufixo.|
|`!~=`|Não corresponde ao sufixo.|

### Group

Por padrão, todos os filtros adicionados a uma query devem corresponder. O query builder suporta a criação de um grupo de filtros onde apenas um filtro precisa corresponder.

```swift
// All planets whose name is either Earth or Mars
Planet.query(on: database).group(.or) { group in
    group.filter(\.$name == "Earth").filter(\.$name == "Mars")
}.all()
```

O método `group` suporta combinar filtros por lógica `and` ou `or`. Esses grupos podem ser aninhados indefinidamente. Filtros de nível superior podem ser considerados como estando em um grupo `and`.

## Aggregate

O query builder suporta vários métodos para realizar cálculos em um conjunto de valores como contagem ou média.

```swift
// Number of planets in database.
Planet.query(on: database).count()
```

Todos os métodos de agregação além de `count` requerem que um key path para um campo seja passado.

```swift
// Lowest name sorted alphabetically.
Planet.query(on: database).min(\.$name)
```

Abaixo está uma lista de todos os métodos de agregação disponíveis.

|Agregação|Descrição|
|-|-|
|`count`|Número de resultados.|
|`sum`|Soma dos valores dos resultados.|
|`average`|Média dos valores dos resultados.|
|`min`|Valor mínimo dos resultados.|
|`max`|Valor máximo dos resultados.|

Todos os métodos de agregação exceto `count` retornam o tipo de valor do campo como resultado. `count` sempre retorna um inteiro.

## Chunk

O query builder suporta retornar um conjunto de resultados como chunks separados. Isso ajuda você a controlar o uso de memória ao lidar com leituras grandes do banco de dados.

```swift
// Fetches all planets in chunks of at most 64 at a time.
Planet.query(on: self.database).chunk(max: 64) { planets in
    // Handle chunk of planets.
}
```

A closure fornecida será chamada zero ou mais vezes dependendo do número total de resultados. Cada item retornado é um `Result` contendo o model ou um erro retornado ao tentar decodificar a entrada do banco de dados.

## Field

Por padrão, todos os campos de um model serão lidos do banco de dados por uma query. Você pode escolher selecionar apenas um subconjunto dos campos de um model usando o método `field`.

```swift
// Select only the planet's id and name field
Planet.query(on: database)
    .field(\.$id).field(\.$name)
    .all()
```

Quaisquer campos do model não selecionados durante uma query estarão em estado não inicializado. Tentar acessar campos não inicializados diretamente resultará em um erro fatal. Para verificar se o valor de um campo do model está definido, use a propriedade `value`.

```swift
if let name = planet.$name.value {
    // Name was fetched.
} else {
    // Name was not fetched.
    // Accessing `planet.name` will fail.
}
```

## Unique

O método `unique` do query builder faz com que apenas resultados distintos (sem duplicatas) sejam retornados.

```swift
// Returns all unique user first names.
User.query(on: database).unique().all(\.$firstName)
```

`unique` é especialmente útil ao buscar um único campo com `all`. No entanto, você também pode selecionar múltiplos campos usando o método [`field`](#field). Como identificadores de model são sempre únicos, você deve evitar selecioná-los ao usar `unique`.

## Range

Os métodos `range` do query builder permitem que você escolha um subconjunto dos resultados usando ranges do Swift.

```swift
// Fetch the first 5 planets.
Planet.query(on: self.database)
    .range(..<5)
```

Valores de range são inteiros sem sinal começando em zero. Saiba mais sobre [ranges do Swift](https://developer.apple.com/documentation/swift/range).

```swift
// Skip the first 2 results.
.range(2...)
```

## Join

O método `join` do query builder permite que você inclua os campos de outro model no seu conjunto de resultados. Mais de um model pode ser adicionado via join à sua query.

```swift
// Fetches all planets with a star named Sun.
Planet.query(on: database)
    .join(Star.self, on: \Planet.$star.$id == \Star.$id)
    .filter(Star.self, \.$name == "Sun")
    .all()
```

O parâmetro `on` aceita uma expressão de igualdade entre dois campos. Um dos campos já deve existir no conjunto de resultados atual. O outro campo deve existir no model sendo adicionado via join. Esses campos devem ter o mesmo tipo de valor.

A maioria dos métodos do query builder, como `filter` e `sort`, suportam models adicionados via join. Se um método suporta models via join, ele aceitará o tipo do model como primeiro parâmetro.

```swift
// Sort by joined field "name" on Star model.
.sort(Star.self, \.$name)
```

Queries que usam joins ainda retornarão um array do model base. Para acessar o model adicionado via join, use o método `joined`.

```swift
// Accessing joined model from query result.
let planet: Planet = ...
let star = try planet.joined(Star.self)
```

### Model Alias

Model aliases permitem que você adicione o mesmo model a uma query múltiplas vezes via join. Para declarar um model alias, crie um ou mais tipos em conformidade com `ModelAlias`.

```swift
// Example of model aliases.
final class HomeTeam: ModelAlias {
    static let name = "home_teams"
    let model = Team()
}
final class AwayTeam: ModelAlias {
    static let name = "away_teams"
    let model = Team()
}
```

Esses tipos referenciam o model sendo usado como alias via a propriedade `model`. Uma vez criados, você pode usar model aliases como models normais em um query builder.

```swift
// Fetch all matches where the home team's name is Vapor
// and sort by the away team's name.
let matches = try await Match.query(on: self.database)
    .join(HomeTeam.self, on: \Match.$homeTeam.$id == \HomeTeam.$id)
    .join(AwayTeam.self, on: \Match.$awayTeam.$id == \AwayTeam.$id)
    .filter(HomeTeam.self, \.$name == "Vapor")
    .sort(AwayTeam.self, \.$name)
    .all()
```

Todos os campos do model são acessíveis através do tipo de model alias via `@dynamicMemberLookup`.

```swift
// Access joined model from result.
let home = try match.joined(HomeTeam.self)
print(home.name)
```

## Update

O query builder suporta atualizar mais de um model por vez usando o método `update`.

```swift
// Update all planets named "Pluto"
Planet.query(on: database)
    .set(\.$type, to: .dwarf)
    .filter(\.$name == "Pluto")
    .update()
```

`update` suporta os métodos `set`, `filter` e `range`.

## Delete

O query builder suporta deletar mais de um model por vez usando o método `delete`.

```swift
// Delete all planets named "Vulcan"
Planet.query(on: database)
    .filter(\.$name == "Vulcan")
    .delete()
```

`delete` suporta o método `filter`.

## Paginate

A API de query do Fluent suporta paginação automática de resultados usando o método `paginate`.

```swift
// Example of request-based pagination.
app.get("planets") { req in
    try await Planet.query(on: req.db).paginate(for: req)
}
```

O método `paginate(for:)` usará os parâmetros `page` e `per` disponíveis na URI da requisição para retornar o conjunto desejado de resultados. Metadados sobre a página atual e o número total de resultados são incluídos na chave `metadata`.

```http
GET /planets?page=2&per=5 HTTP/1.1
```

A requisição acima produziria uma resposta estruturada como a seguinte.

```json
{
    "items": [...],
    "metadata": {
        "page": 2,
        "per": 5,
        "total": 8
    }
}
```

Números de página começam em `1`. Você também pode fazer uma requisição de página manual.

```swift
// Example of manual pagination.
.paginate(PageRequest(page: 1, per: 2))
```

## Sort

Resultados de query podem ser ordenados por valores de campo usando o método `sort`.

```swift
// Fetch planets sorted by name.
Planet.query(on: database).sort(\.$name)
```

Ordenações adicionais podem ser adicionadas como fallbacks em caso de empate. Fallbacks serão usados na ordem em que foram adicionados ao query builder.

```swift
// Fetch users sorted by name. If two users have the same name, sort them by age.
User.query(on: database).sort(\.$name).sort(\.$age)
```
