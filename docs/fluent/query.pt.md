# Consultas

A API de query do Fluent permite que você crie, leia, atualize e delete models do banco de dados. Ela suporta filtragem de resultados, joins, chunking, agregações e mais.

```swift
// Um exemplo da API de query do Fluent.
let planets = try await Planet.query(on: database)
    .filter(\.$type == .gasGiant)
    .sort(\.$name)
    .with(\.$star)
    .all()
```

Query builders estão vinculados a um único tipo de model e podem ser criados usando o método estático [`query`](model.md#query). Eles também podem ser criados passando o tipo do model para o método `query` em um objeto database.

```swift
// Também cria um query builder.
database.query(Planet.self)
```

!!! note
    Você deve importar `import Fluent` no arquivo com suas queries para que o compilador possa ver as funções auxiliares do Fluent.

## All

O método `all()` retorna um array de models.

```swift
// Busca todos os planetas.
let planets = try await Planet.query(on: database).all()
```

O método `all` também suporta buscar apenas um único campo do conjunto de resultados.

```swift
// Busca todos os nomes dos planetas.
let names = try await Planet.query(on: database).all(\.$name)
```

### First

O método `first()` retorna um único model opcional. Se a query resultar em mais de um model, apenas o primeiro é retornado. Se a query não tiver resultados, `nil` é retornado.

```swift
// Busca o primeiro planeta chamado Earth.
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
// Um exemplo de filtragem por valor de campo.
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
// Todos os usuários com o mesmo primeiro nome e sobrenome.
User.query(on: database)
    .filter(\.$firstName == \.$lastName)
```

Filtros de campo suportam os mesmos operadores que [filtros de valor](#value-filter).

### Subset Filter

O método `filter` suporta verificar se o valor de um campo existe em um conjunto de valores fornecido.

```swift
// Todos os planetas do tipo gas giant ou small rocky.
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
// Todos os planetas cujo nome começa com a letra M
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
// Todos os planetas cujo nome é Earth ou Mars
Planet.query(on: database).group(.or) { group in
    group.filter(\.$name == "Earth").filter(\.$name == "Mars")
}.all()
```

O método `group` suporta combinar filtros por lógica `and` ou `or`. Esses grupos podem ser aninhados indefinidamente. Filtros de nível superior podem ser considerados como estando em um grupo `and`.

## Aggregate

O query builder suporta vários métodos para realizar cálculos em um conjunto de valores como contagem ou média.

```swift
// Número de planetas no banco de dados.
Planet.query(on: database).count()
```

Todos os métodos de agregação além de `count` requerem que um key path para um campo seja passado.

```swift
// Menor nome ordenado alfabeticamente.
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
// Busca todos os planetas em chunks de no máximo 64 por vez.
Planet.query(on: self.database).chunk(max: 64) { planets in
    // Processa o chunk de planetas.
}
```

A closure fornecida será chamada zero ou mais vezes dependendo do número total de resultados. Cada item retornado é um `Result` contendo o model ou um erro retornado ao tentar decodificar a entrada do banco de dados.

## Field

Por padrão, todos os campos de um model serão lidos do banco de dados por uma query. Você pode escolher selecionar apenas um subconjunto dos campos de um model usando o método `field`.

```swift
// Seleciona apenas os campos id e name do planeta
Planet.query(on: database)
    .field(\.$id).field(\.$name)
    .all()
```

Quaisquer campos do model não selecionados durante uma query estarão em estado não inicializado. Tentar acessar campos não inicializados diretamente resultará em um erro fatal. Para verificar se o valor de um campo do model está definido, use a propriedade `value`.

```swift
if let name = planet.$name.value {
    // O nome foi buscado.
} else {
    // O nome não foi buscado.
    // Acessar `planet.name` falhará.
}
```

## Unique

O método `unique` do query builder faz com que apenas resultados distintos (sem duplicatas) sejam retornados.

```swift
// Retorna todos os primeiros nomes únicos dos usuários.
User.query(on: database).unique().all(\.$firstName)
```

`unique` é especialmente útil ao buscar um único campo com `all`. No entanto, você também pode selecionar múltiplos campos usando o método [`field`](#field). Como identificadores de model são sempre únicos, você deve evitar selecioná-los ao usar `unique`.

## Range

Os métodos `range` do query builder permitem que você escolha um subconjunto dos resultados usando ranges do Swift.

```swift
// Busca os primeiros 5 planetas.
Planet.query(on: self.database)
    .range(..<5)
```

Valores de range são inteiros sem sinal começando em zero. Saiba mais sobre [ranges do Swift](https://developer.apple.com/documentation/swift/range).

```swift
// Pula os primeiros 2 resultados.
.range(2...)
```

## Join

O método `join` do query builder permite que você inclua os campos de outro model no seu conjunto de resultados. Mais de um model pode ser adicionado via join à sua query.

```swift
// Busca todos os planetas com uma estrela chamada Sun.
Planet.query(on: database)
    .join(Star.self, on: \Planet.$star.$id == \Star.$id)
    .filter(Star.self, \.$name == "Sun")
    .all()
```

O parâmetro `on` aceita uma expressão de igualdade entre dois campos. Um dos campos já deve existir no conjunto de resultados atual. O outro campo deve existir no model sendo adicionado via join. Esses campos devem ter o mesmo tipo de valor.

A maioria dos métodos do query builder, como `filter` e `sort`, suportam models adicionados via join. Se um método suporta models via join, ele aceitará o tipo do model como primeiro parâmetro.

```swift
// Ordena pelo campo "name" do model Star via join.
.sort(Star.self, \.$name)
```

Queries que usam joins ainda retornarão um array do model base. Para acessar o model adicionado via join, use o método `joined`.

```swift
// Acessando o model via join a partir do resultado da query.
let planet: Planet = ...
let star = try planet.joined(Star.self)
```

### Model Alias

Model aliases permitem que você adicione o mesmo model a uma query múltiplas vezes via join. Para declarar um model alias, crie um ou mais tipos em conformidade com `ModelAlias`.

```swift
// Exemplo de model aliases.
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
// Busca todas as partidas onde o nome do time da casa é Vapor
// e ordena pelo nome do time visitante.
let matches = try await Match.query(on: self.database)
    .join(HomeTeam.self, on: \Match.$homeTeam.$id == \HomeTeam.$id)
    .join(AwayTeam.self, on: \Match.$awayTeam.$id == \AwayTeam.$id)
    .filter(HomeTeam.self, \.$name == "Vapor")
    .sort(AwayTeam.self, \.$name)
    .all()
```

Todos os campos do model são acessíveis através do tipo de model alias via `@dynamicMemberLookup`.

```swift
// Acessa o model via join a partir do resultado.
let home = try match.joined(HomeTeam.self)
print(home.name)
```

## Update

O query builder suporta atualizar mais de um model por vez usando o método `update`.

```swift
// Atualiza todos os planetas chamados "Pluto"
Planet.query(on: database)
    .set(\.$type, to: .dwarf)
    .filter(\.$name == "Pluto")
    .update()
```

`update` suporta os métodos `set`, `filter` e `range`.

## Delete

O query builder suporta deletar mais de um model por vez usando o método `delete`.

```swift
// Deleta todos os planetas chamados "Vulcan"
Planet.query(on: database)
    .filter(\.$name == "Vulcan")
    .delete()
```

`delete` suporta o método `filter`.

## Paginate

A API de query do Fluent suporta paginação automática de resultados usando o método `paginate`.

```swift
// Exemplo de paginação baseada em requisição.
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
// Exemplo de paginação manual.
.paginate(PageRequest(page: 1, per: 2))
```

## Sort

Resultados de query podem ser ordenados por valores de campo usando o método `sort`.

```swift
// Busca planetas ordenados por nome.
Planet.query(on: database).sort(\.$name)
```

Ordenações adicionais podem ser adicionadas como fallbacks em caso de empate. Fallbacks serão usados na ordem em que foram adicionados ao query builder.

```swift
// Busca usuários ordenados por nome. Se dois usuários têm o mesmo nome, ordena por idade.
User.query(on: database).sort(\.$name).sort(\.$age)
```
