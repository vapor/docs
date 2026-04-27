# Schema

L'API dello schema di Fluent ti consente di creare e aggiornare lo schema del tuo database in modo programmatico. Viene spesso usata in combinazione con le [migrazioni](migration.it.md) per preparare il database all'uso con i [modelli](model.it.md).

```swift
// Esempio di creazione dello schema.
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .field("star_id", .uuid, .required, .references("stars", "id"))
    .create()
```

Per creare un `SchemaBuilder`, usa il metodo `schema` sul database. Passa il nome della tabella o collezione che vuoi modificare. Se stai modificando lo schema per un modello, assicurati che questo nome corrisponda allo [`schema`](model.it.md#schema) del modello.

## Azioni

L'API dello schema supporta la creazione, l'aggiornamento e l'eliminazione degli schemi. Ogni azione supporta un sottoinsieme dei metodi disponibili dell'API.

### Create

Chiamare `create()` crea una nuova tabella o collezione nel database. Tutti i metodi per definire nuovi campi e vincoli sono supportati. I metodi per aggiornamenti o eliminazioni vengono ignorati.

```swift
// Esempio di creazione dello schema.
try await database.schema("planets")
    .id()
    .field("name", .string, .required)
    .create()
```

Se esiste già una tabella o collezione con il nome scelto, verrà lanciato un errore. Per ignorarlo, usa `.ignoreExisting()`.

### Update

Chiamare `update()` aggiorna una tabella o collezione esistente nel database. Tutti i metodi per creare, aggiornare ed eliminare campi e vincoli sono supportati.

```swift
// Esempio di aggiornamento dello schema.
try await database.schema("planets")
    .unique(on: "name")
    .deleteField("star_id")
    .update()
```

### Delete

Chiamare `delete()` elimina una tabella o collezione esistente dal database. Non sono supportati metodi aggiuntivi.

```swift
// Esempio di eliminazione dello schema.
database.schema("planets").delete()
```

## Campo

I campi possono essere aggiunti durante la creazione o l'aggiornamento di uno schema.

```swift
// Aggiunge un nuovo campo
.field("name", .string, .required)
```

Il primo parametro è il nome del campo. Deve corrispondere alla chiave usata sulla proprietà del modello associato. Il secondo parametro è il [tipo di dato](#tipo-di-dato) del campo. Infine, è possibile aggiungere zero o più [vincoli](#vincolo-di-campo).

### Tipo di Dato

I tipi di dato dei campi supportati sono elencati di seguito.

|DataType|Tipo Swift|
|-|-|
|`.string`|`String`|
|`.int{8,16,32,64}`|`Int{8,16,32,64}`|
|`.uint{8,16,32,64}`|`UInt{8,16,32,64}`|
|`.bool`|`Bool`|
|`.datetime`|`Date` (raccomandato)|
|`.date`|`Date` (senza l'ora del giorno)|
|`.float`|`Float`|
|`.double`|`Double`|
|`.data`|`Data`|
|`.uuid`|`UUID`|
|`.dictionary`|Vedi [dictionary](#dictionary)|
|`.array`|Vedi [array](#array)|
|`.enum`|Vedi [enum](#enum)|

### Vincolo di Campo

I vincoli di campo supportati sono elencati di seguito.

|FieldConstraint|Descrizione|
|-|-|
|`.required`|Non consente valori `nil`.|
|`.references`|Richiede che il valore di questo campo corrisponda a un valore nello schema referenziato. Vedi [chiave esterna](#chiave-esterna).|
|`.identifier`|Denota la chiave primaria. Vedi [identifier](#identifier).|
|`.sql(SQLColumnConstraintAlgorithm)`|Definisce qualsiasi vincolo non supportato (ad es. `default`). Vedi [SQL](#sql) e [SQLColumnConstraintAlgorithm](https://api.vapor.codes/sqlkit/documentation/sqlkit/sqlcolumnconstraintalgorithm/).|

### Identifier

Se il tuo modello usa una proprietà `@ID` standard, puoi usare il metodo helper `id()` per creare il suo campo. Questo usa la chiave di campo speciale `.id` e il tipo di valore `UUID`.

```swift
// Aggiunge il campo per l'identificatore predefinito.
.id()
```

Per i tipi di identificatore personalizzati, dovrai specificare il campo manualmente.

```swift
// Aggiunge il campo per l'identificatore personalizzato.
.field("id", .int, .identifier(auto: true))
```

Il vincolo `identifier` può essere usato su un singolo campo e denota la chiave primaria. Il flag `auto` determina se il database deve generare questo valore automaticamente.

### Aggiornare Campo

Puoi aggiornare il tipo di dato di un campo usando `updateField`.

```swift
// Aggiorna il tipo di dato del campo a `double`.
.updateField("age", .double)
```

Vedi [avanzato](advanced.it.md#sql) per ulteriori informazioni sugli aggiornamenti avanzati dello schema.

### Eliminare Campo

Puoi rimuovere un campo da uno schema usando `deleteField`.

```swift
// Elimina il campo "age".
.deleteField("age")
```

## Vincolo

I vincoli possono essere aggiunti durante la creazione o l'aggiornamento di uno schema. A differenza dei [vincoli di campo](#vincolo-di-campo), i vincoli di livello superiore possono influenzare più campi.

### Unique

Un vincolo unique richiede che non ci siano valori duplicati in uno o più campi.

```swift
// Impedisce indirizzi email duplicati.
.unique(on: "email")
```

Se più campi sono vincolati, la combinazione specifica dei valori di ogni campo deve essere unica.

```swift
// Impedisce utenti con lo stesso nome completo.
.unique(on: "first_name", "last_name")
```

Per eliminare un vincolo unique, usa `deleteUnique`.

```swift
// Rimuove il vincolo di email duplicata.
.deleteUnique(on: "email")
```

### Nome del Vincolo

Fluent genererà nomi di vincolo univoci per impostazione predefinita. Tuttavia, potresti voler passare un nome di vincolo personalizzato. Puoi farlo usando il parametro `name`.

```swift
// Impedisce indirizzi email duplicati.
.unique(on: "email", name: "no_duplicate_emails")
```

Per eliminare un vincolo con nome, devi usare `deleteConstraint(name:)`.

```swift
// Rimuove il vincolo di email duplicata.
.deleteConstraint(name: "no_duplicate_emails")
```

## Chiave Esterna

I vincoli di chiave esterna richiedono che il valore di un campo corrisponda a uno dei valori nel campo referenziato. Questo è utile per prevenire il salvataggio di dati non validi. I vincoli di chiave esterna possono essere aggiunti come vincolo di campo o di livello superiore.

Per aggiungere un vincolo di chiave esterna a un campo, usa `.references`.

```swift
// Esempio di aggiunta di un vincolo di chiave esterna a un campo.
.field("star_id", .uuid, .required, .references("stars", "id"))
```

Il vincolo sopra richiede che tutti i valori nel campo "star_id" corrispondano a uno dei valori nel campo "id" di Star.

Questo stesso vincolo potrebbe essere aggiunto come vincolo di livello superiore usando `foreignKey`.

```swift
// Esempio di aggiunta di un vincolo di chiave esterna di livello superiore.
.foreignKey("star_id", references: "stars", "id")
```

A differenza dei vincoli di campo, i vincoli di livello superiore possono essere aggiunti in un aggiornamento dello schema. Possono anche avere un [nome](#nome-del-vincolo).

I vincoli di chiave esterna supportano le azioni opzionali `onDelete` e `onUpdate`.

|ForeignKeyAction|Descrizione|
|-|-|
|`.noAction`|Impedisce le violazioni della chiave esterna (predefinito).|
|`.restrict`|Uguale a `.noAction`.|
|`.cascade`|Propaga le eliminazioni attraverso le chiavi esterne.|
|`.setNull`|Imposta il campo a null se il riferimento viene interrotto.|
|`.setDefault`|Imposta il campo al valore predefinito se il riferimento viene interrotto.|

Di seguito è riportato un esempio che usa le azioni di chiave esterna.

```swift
// Esempio di aggiunta di un vincolo di chiave esterna di livello superiore.
.foreignKey("star_id", references: "stars", "id", onDelete: .cascade)
```

!!! warning "Attenzione"
    Le azioni delle chiavi esterne avvengono esclusivamente nel database, bypassando Fluent.
    Questo significa che elementi come il middleware del modello e l'eliminazione temporanea potrebbero non funzionare correttamente.

## SQL

Il parametro `.sql` ti consente di aggiungere SQL arbitrario al tuo schema. Questo è utile per aggiungere vincoli o tipi di dato specifici.
Un caso d'uso comune è definire un valore predefinito per un campo:

```swift
.field("active", .bool, .required, .sql(.default(true)))
```

o anche un valore predefinito per un timestamp:

```swift
.field("created_at", .datetime, .required, .sql(.default(SQLFunction("now"))))
```

## Dictionary

Il tipo di dato dictionary è in grado di memorizzare valori di dizionario annidati. Questo include le struct che si conformano a `Codable` e i dizionari Swift con un valore `Codable`.

!!! note "Nota"
    I driver di database SQL di Fluent memorizzano i dizionari annidati nelle colonne JSON.

Considera la seguente struct `Codable`.

```swift
struct Pet: Codable {
    var name: String
    var age: Int
}
```

Poiché questa struct `Pet` è `Codable`, può essere memorizzata in un `@Field`.

```swift
@Field(key: "pet")
var pet: Pet
```

Questo campo può essere memorizzato usando il tipo di dato `.dictionary(of:)`.

```swift
.field("pet", .dictionary, .required)
```

Poiché i tipi `Codable` sono dizionari eterogenei, non specifichiamo il parametro `of`.

Se i valori del dizionario fossero omogenei, ad esempio `[String: Int]`, il parametro `of` specificherebbe il tipo di valore.

```swift
.field("numbers", .dictionary(of: .int), .required)
```

Le chiavi del dizionario devono essere sempre stringhe.

## Array

Il tipo di dato array è in grado di memorizzare array annidati. Questo include gli array Swift che contengono valori `Codable` e i tipi `Codable` che usano un container senza chiave.

Considera il seguente `@Field` che memorizza un array di stringhe.

```swift
@Field(key: "tags")
var tags: [String]
```

Questo campo può essere memorizzato usando il tipo di dato `.array(of:)`.

```swift
.field("tags", .array(of: .string), .required)
```

Poiché l'array è omogeneo, specifichiamo il parametro `of`.

Gli `Array` Swift Codable avranno sempre un tipo di valore omogeneo. I tipi `Codable` personalizzati che serializzano valori eterogenei nei container senza chiave sono l'eccezione e dovrebbero usare il tipo di dato `.array`.

## Enum

Il tipo di dato enum è in grado di memorizzare nativamente enum Swift basati su stringhe. Gli enum nativi del database forniscono un ulteriore livello di sicurezza dei tipi al tuo database e possono essere più performanti degli enum grezzi.

Per definire un enum nativo del database, usa il metodo `enum` su `Database`. Usa `case` per definire ogni caso dell'enum.

```swift
// Esempio di creazione di un enum.
database.enum("planet_type")
    .case("smallRocky")
    .case("gasGiant")
    .case("dwarf")
    .create()
```

Una volta creato un enum, puoi usare il metodo `read()` per generare un tipo di dato per il campo dello schema.

```swift
// Esempio di lettura di un enum e utilizzo per definire un nuovo campo.
database.enum("planet_type").read().flatMap { planetType in
    database.schema("planets")
        .field("type", planetType, .required)
        .update()
}

// Oppure

let planetType = try await database.enum("planet_type").read()
try await database.schema("planets")
    .field("type", planetType, .required)
    .update()
```

Per aggiornare un enum, chiama `update()`. I casi possono essere eliminati dagli enum esistenti.

```swift
// Esempio di aggiornamento di un enum.
database.enum("planet_type")
    .deleteCase("gasGiant")
    .update()
```

Per eliminare un enum, chiama `delete()`.

```swift
// Esempio di eliminazione di un enum.
database.enum("planet_type").delete()
```

## Accoppiamento con il Modello

La costruzione dello schema è volutamente disaccoppiata dai modelli. A differenza della costruzione delle query, la costruzione dello schema non fa uso di key path ed è completamente basata su stringhe. Questo è importante poiché le definizioni dello schema, specialmente quelle scritte per le migrazioni, potrebbero dover fare riferimento alle proprietà del modello che non esistono più.

Per capire meglio questo, dai un'occhiata alla seguente migrazione di esempio.

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

Supponiamo che questa migrazione sia già stata deployata in produzione. Supponiamo ora di dover apportare la seguente modifica al modello User.

```diff
- @Field(key: "name")
- var name: String
+ @Field(key: "first_name")
+ var firstName: String
+
+ @Field(key: "last_name")
+ var lastName: String
```

Possiamo apportare le necessarie modifiche allo schema del database con la seguente migrazione.

```swift
struct UserNameMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .update()

        // Al momento non è possibile esprimere questo aggiornamento senza usare SQL personalizzato.
        // Inoltre, non cerchiamo di dividere il nome in nome e cognome, 
        // poiché ciò richiede una sintassi specifica del database.
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

Nota che affinché questa migrazione funzioni, dobbiamo essere in grado di fare riferimento sia al campo `name` rimosso che ai nuovi campi `firstName` e `lastName` allo stesso tempo. Inoltre, la `UserMigration` originale dovrebbe continuare a essere valida. Questo non sarebbe possibile da fare con i key path.

## Impostare lo Spazio del Modello

Per definire lo [spazio di un modello](model.it.md#spazio-del-database), passa lo spazio a `schema(_:space:)` durante la creazione della tabella. Ad esempio:

```swift
try await db.schema("planets", space: "mirror_universe")
    .id()
    // ...
    .create()
```
