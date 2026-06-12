# Schema

A API de schema do Fluent permite que você crie e atualize o schema do seu banco de dados programaticamente. Ela é frequentemente usada em conjunto com [migrations](migration.md) para preparar o banco de dados para uso com [models](model.md).

```swift
// Um exemplo da API de schema do Fluent
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .field("star_id", .uuid, .required, .references("stars", "id"))
    .create()
```

Para criar um `SchemaBuilder`, use o método `schema` no database. Passe o nome da tabela ou coleção que deseja afetar. Se estiver editando o schema para um model, certifique-se de que este nome corresponda ao [`schema`](model.md#schema) do model.

## Ações

A API de schema suporta criação, atualização e exclusão de schemas. Cada ação suporta um subconjunto dos métodos disponíveis da API.

### Criar

Chamar `create()` cria uma nova tabela ou coleção no banco de dados. Todos os métodos para definir novos campos e constraints são suportados. Métodos para atualizações ou exclusões são ignorados.

```swift
// Um exemplo de criação de schema.
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .create()
```

Se uma tabela ou coleção com o nome escolhido já existir, um erro será lançado. Para ignorar isso, use `.ignoreExisting()`.

### Atualizar

Chamar `update()` atualiza uma tabela ou coleção existente no banco de dados. Todos os métodos para criar, atualizar e deletar campos e constraints são suportados.

```swift
// Um exemplo de atualização de schema.
try await database.schema("planets")
    .unique(on: "name")
    .deleteField("star_id")
    .update()
```

### Deletar

Chamar `delete()` deleta uma tabela ou coleção existente do banco de dados. Nenhum método adicional é suportado.

```swift
// Um exemplo de exclusão de schema.
database.schema("planets").delete()
```

## Field

Campos podem ser adicionados ao criar ou atualizar um schema.

```swift
// Adiciona um novo campo
.field("name", .string, .required)
```

O primeiro parâmetro é o nome do campo. Isso deve corresponder à chave usada na propriedade do model associado. O segundo parâmetro é o [tipo de dado](#data-type) do campo. Por fim, zero ou mais [constraints](#field-constraint) podem ser adicionadas.

### Data Type

Tipos de dados de campo suportados estão listados abaixo.

|DataType|Tipo Swift|
|-|-|
|`.string`|`String`|
|`.int{8,16,32,64}`|`Int{8,16,32,64}`|
|`.uint{8,16,32,64}`|`UInt{8,16,32,64}`|
|`.bool`|`Bool`|
|`.datetime`|`Date` (recomendado)|
|`.date`|`Date` (omitindo hora do dia)|
|`.float`|`Float`|
|`.double`|`Double`|
|`.data`|`Data`|
|`.uuid`|`UUID`|
|`.dictionary`|Veja [dictionary](#dictionary)|
|`.array`|Veja [array](#array)|
|`.enum`|Veja [enum](#enum)|

### Field Constraint

Constraints de campo suportadas estão listadas abaixo.

|FieldConstraint|Descrição|
|-|-|
|`.required`|Não permite valores `nil`.|
|`.references`|Exige que o valor deste campo corresponda a um valor no schema referenciado. Veja [foreign key](#foreign-key).|
|`.identifier`|Denota a chave primária. Veja [identifier](#identifier).|
|`.sql(SQLColumnConstraintAlgorithm)`|Define qualquer constraint não suportada (ex: `default`). Veja [SQL](#sql) e [SQLColumnConstraintAlgorithm](https://api.vapor.codes/sqlkit/documentation/sqlkit/sqlcolumnconstraintalgorithm/).|

### Identifier

Se seu model usa uma propriedade `@ID` padrão, você pode usar o helper `id()` para criar seu campo. Isso usa a chave de campo especial `.id` e o tipo de valor `UUID`.

```swift
// Adiciona campo para o identificador padrão.
.id()
```

Para tipos de identificador personalizados, você precisará especificar o campo manualmente.

```swift
// Adiciona campo para identificador personalizado.
.field("id", .int, .identifier(auto: true))
```

A constraint `identifier` pode ser usada em um único campo e denota a chave primária. A flag `auto` determina se o banco de dados deve gerar este valor automaticamente.

### Update Field

Você pode atualizar o tipo de dado de um campo usando `updateField`.

```swift
// Atualiza o campo para o tipo de dado `double`.
.updateField("age", .double)
```

Veja [advanced](advanced.md#sql) para mais informações sobre atualizações avançadas de schema.

### Delete Field

Você pode remover um campo de um schema usando `deleteField`.

```swift
// Deleta o campo "age".
.deleteField("age")
```

## Constraint

Constraints podem ser adicionadas ao criar ou atualizar um schema. Diferentemente das [constraints de campo](#field-constraint), constraints de nível superior podem afetar múltiplos campos.

### Unique

Uma constraint unique exige que não existam valores duplicados em um ou mais campos.

```swift
// Não permite endereços de email duplicados.
.unique(on: "email")
```

Se múltiplos campos forem restringidos, a combinação específica do valor de cada campo deve ser única.

```swift
// Não permite usuários com o mesmo nome completo.
.unique(on: "first_name", "last_name")
```

Para deletar uma constraint unique, use `deleteUnique`.

```swift
// Remove a constraint de email duplicado.
.deleteUnique(on: "email")
```

### Constraint Name

O Fluent gerará nomes de constraints únicos por padrão. No entanto, você pode querer passar um nome de constraint personalizado. Você pode fazer isso usando o parâmetro `name`.

```swift
// Não permite endereços de email duplicados.
.unique(on: "email", name: "no_duplicate_emails")
```

Para deletar uma constraint nomeada, você deve usar `deleteConstraint(name:)`.

```swift
// Remove a constraint de email duplicado.
.deleteConstraint(name: "no_duplicate_emails")
```

## Foreign Key

Constraints de foreign key exigem que o valor de um campo corresponda a um dos valores no campo referenciado. Isso é útil para prevenir que dados inválidos sejam salvos. Constraints de foreign key podem ser adicionadas como constraint de campo ou de nível superior.

Para adicionar uma constraint de foreign key a um campo, use `.references`.

```swift
// Exemplo de adição de uma constraint de foreign key em campo.
.field("star_id", .uuid, .required, .references("stars", "id"))
```

A constraint acima exige que todos os valores no campo "star_id" correspondam a um dos valores no campo "id" de Star.

Esta mesma constraint pode ser adicionada como constraint de nível superior usando `foreignKey`.

```swift
// Exemplo de adição de uma constraint de foreign key de nível superior.
.foreignKey("star_id", references: "stars", "id")
```

Diferentemente das constraints de campo, constraints de nível superior podem ser adicionadas em uma atualização de schema. Elas também podem ser [nomeadas](#constraint-name).

Constraints de foreign key suportam ações opcionais `onDelete` e `onUpdate`.

|ForeignKeyAction|Descrição|
|-|-|
|`.noAction`|Previne violações de foreign key (padrão).|
|`.restrict`|Mesmo que `.noAction`.|
|`.cascade`|Propaga exclusões através de foreign keys.|
|`.setNull`|Define o campo como null se a referência for quebrada.|
|`.setDefault`|Define o campo como padrão se a referência for quebrada.|

Abaixo está um exemplo usando ações de foreign key.

```swift
// Exemplo de adição de uma constraint de foreign key de nível superior.
.foreignKey("star_id", references: "stars", "id", onDelete: .cascade)
```

!!! warning
    Ações de foreign key acontecem exclusivamente no banco de dados, ignorando o Fluent.
    Isso significa que coisas como model middleware e soft-delete podem não funcionar corretamente.

## SQL

O parâmetro `.sql` permite que você adicione SQL arbitrário ao seu schema. Isso é útil para adicionar constraints ou tipos de dados específicos.
Um caso de uso comum é definir um valor padrão para um campo:

```swift
.field("active", .bool, .required, .sql(.default(true)))
```

ou até um valor padrão para um timestamp:

```swift
.field("created_at", .datetime, .required, .sql(.default(SQLFunction("now"))))
```

## Dictionary

O tipo de dado dictionary é capaz de armazenar valores de dicionário aninhados. Isso inclui structs que conformam a `Codable` e dicionários Swift com um valor `Codable`.

!!! note
    Os drivers de banco de dados SQL do Fluent armazenam dicionários aninhados em colunas JSON.

Considere a seguinte struct `Codable`.

```swift
struct Pet: Codable {
    var name: String
    var age: Int
}
```

Como esta struct `Pet` é `Codable`, ela pode ser armazenada em um `@Field`.

```swift
@Field(key: "pet")
var pet: Pet
```

Este campo pode ser armazenado usando o tipo de dado `.dictionary(of:)`.

```swift
.field("pet", .dictionary, .required)
```

Como tipos `Codable` são dicionários heterogêneos, não especificamos o parâmetro `of`.

Se os valores do dicionário fossem homogêneos, por exemplo `[String: Int]`, o parâmetro `of` especificaria o tipo de valor.

```swift
.field("numbers", .dictionary(of: .int), .required)
```

Chaves de dicionário devem sempre ser strings.

## Array

O tipo de dado array é capaz de armazenar arrays aninhados. Isso inclui arrays Swift que contêm valores `Codable` e tipos `Codable` que usam um container sem chave.

Considere o seguinte `@Field` que armazena um array de strings.

```swift
@Field(key: "tags")
var tags: [String]
```

Este campo pode ser armazenado usando o tipo de dado `.array(of:)`.

```swift
.field("tags", .array(of: .string), .required)
```

Como o array é homogêneo, especificamos o parâmetro `of`.

`Array`s Codable do Swift sempre terão um tipo de valor homogêneo. Tipos `Codable` personalizados que serializam valores heterogêneos para containers sem chave são a exceção e devem usar o tipo de dado `.array`.

## Enum

O tipo de dado enum é capaz de armazenar enums Swift baseados em string nativamente. Enums nativos do banco de dados fornecem uma camada adicional de segurança de tipos ao seu banco de dados e podem ser mais performáticos que enums brutos.

Para definir um enum nativo do banco de dados, use o método `enum` no `Database`. Use `case` para definir cada caso do enum.

```swift
// Um exemplo de criação de enum.
database.enum("planet_type")
    .case("smallRocky")
    .case("gasGiant")
    .case("dwarf")
    .create()
```

Uma vez que um enum foi criado, você pode usar o método `read()` para gerar um tipo de dado para o campo do seu schema.

```swift
// Um exemplo de leitura de um enum e uso para definir um novo campo.
database.enum("planet_type").read().flatMap { planetType in
    database.schema("planets")
        .field("type", planetType, .required)
        .update()
}

// Ou

let planetType = try await database.enum("planet_type").read()
try await database.schema("planets")
    .field("type", planetType, .required)
    .update()
```

Para atualizar um enum, chame `update()`. Cases podem ser deletados de enums existentes.

```swift
// Um exemplo de atualização de enum.
database.enum("planet_type")
    .deleteCase("gasGiant")
    .update()
```

Para deletar um enum, chame `delete()`.

```swift
// Um exemplo de exclusão de enum.
database.enum("planet_type").delete()
```

## Acoplamento de Model

A construção de schema é propositalmente desacoplada dos models. Diferentemente da construção de queries, a construção de schema não faz uso de key paths e é completamente baseada em strings. Isso é importante pois definições de schema, especialmente aquelas escritas para migrations, podem precisar referenciar propriedades de models que já não existem mais.

Para entender melhor isso, veja o seguinte exemplo de migration.

```swift
struct UserMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
```

Vamos assumir que esta migration já foi enviada para produção. Agora vamos assumir que precisamos fazer a seguinte alteração no model User.

```diff
- @Field(key: "name")
- var name: String
+ @Field(key: "first_name")
+ var firstName: String
+
+ @Field(key: "last_name")
+ var lastName: String
```

Podemos fazer os ajustes necessários no schema do banco de dados com a seguinte migration.

```swift
struct UserNameMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .update()

        // Atualmente não é possível expressar esta atualização sem usar SQL personalizado.
        // Isso também não tenta lidar com a divisão do nome em primeiro e último,
        // pois isso requer sintaxe específica do banco de dados.
        try await User.query(on: database)
            .set(["first_name": .sql(embed: "name")])
            .run()

        try await database.schema("users")
            .deleteField("name")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .field("name", .string, .required)
            .update()
        try await User.query(on: database)
            .set(["name": .sql(embed: "concat(first_name, ' ', last_name)")])
            .run()
        try await database.schema("users")
            .deleteField("first_name")
            .deleteField("last_name")
            .update()
    }
}
```

Note que para esta migration funcionar, precisamos ser capazes de referenciar tanto o campo removido `name` quanto os novos campos `firstName` e `lastName` ao mesmo tempo. Além disso, a `UserMigration` original deve continuar sendo válida. Isso não seria possível de fazer com key paths.

## Definindo o Espaço do Model

Para definir o [espaço para um model](model.md#database-space), passe o espaço para `schema(_:space:)` ao criar a tabela. Ex:

```swift
try await db.schema("planets", space: "mirror_universe")
    .id()
    // ...
    .create()
```
