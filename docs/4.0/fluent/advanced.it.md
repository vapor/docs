# Avanzate

Fluent si propone di creare un'API generica e indipendente dal database per lavorare con i tuoi dati. Questo rende più facile imparare Fluent indipendentemente dal driver di database che stai utilizzando. La creazione di API generalizzate può anche rendere il lavoro con il tuo database più naturale in Swift.

Tuttavia, potresti dover utilizzare una funzionalità del tuo driver di database sottostante che non è ancora supportata tramite Fluent. Questa guida tratta i pattern avanzati e le API di Fluent che funzionano solo con determinati database.

## SQL

Tutti i driver di database SQL di Fluent sono costruiti su [SQLKit](https://github.com/vapor/sql-kit). Questa implementazione SQL generica è inclusa con Fluent nel modulo `FluentSQL`.

### Database SQL

Qualsiasi `Database` di Fluent può essere convertito in un `SQLDatabase`. Questo include `req.db`, `app.db`, il `database` passato a `Migration`, ecc.

```swift
import FluentSQL

if let sql = req.db as? SQLDatabase {
    // The underlying database driver is SQL.
    let planets = try await sql.raw("SELECT * FROM planets").all(decoding: Planet.self)
} else {
    // The underlying database driver is _not_ SQL.
}
```

Questa conversione funzionerà solo se il driver di database sottostante è un database SQL. Per saperne di più sui metodi di `SQLDatabase`, consulta il [README di SQLKit](https://github.com/vapor/sql-kit).

### Database SQL Specifico

Puoi anche convertire verso database SQL specifici importando il driver.

```swift
import FluentPostgresDriver

if let postgres = req.db as? PostgresDatabase {
    // The underlying database driver is PostgreSQL.
    postgres.simpleQuery("SELECT * FROM planets").all()
} else {
    // The underlying database is _not_ PostgreSQL.
}
```

Al momento della stesura, i seguenti driver SQL sono supportati.

|Database|Driver|Libreria|
|-|-|-|
|`PostgresDatabase`|[vapor/fluent-postgres-driver](https://github.com/vapor/fluent-postgres-driver)|[vapor/postgres-nio](https://github.com/vapor/postgres-nio)|
|`MySQLDatabase`|[vapor/fluent-mysql-driver](https://github.com/vapor/fluent-mysql-driver)|[vapor/mysql-nio](https://github.com/vapor/mysql-nio)|
|`SQLiteDatabase`|[vapor/fluent-sqlite-driver](https://github.com/vapor/fluent-sqlite-driver)|[vapor/sqlite-nio](https://github.com/vapor/sqlite-nio)|

Visita il README della libreria per ulteriori informazioni sulle API specifiche del database.

### SQL Personalizzato

Quasi tutti i tipi di query e schema di Fluent supportano un caso `.custom`. Questo ti permette di utilizzare funzionalità del database che Fluent non supporta ancora.

```swift
import FluentPostgresDriver

let query = Planet.query(on: req.db)
if req.db is PostgresDatabase {
    // ILIKE è supportato da PostgreSQL, quindi possiamo usarlo
    query.filter(\.$name, .custom("ILIKE"), "earth")
} else {
    // ILIKE non è supportato
    query.group(.or) { or in
        or.filter(\.$name == "earth").filter(\.$name == "Earth")
    }
}
query.all()
```

I database SQL supportano sia `String` che `SQLExpression` in tutti i casi `.custom`. Il modulo `FluentSQL` fornisce metodi di convenienza per i casi d'uso più comuni.

```swift
import FluentSQL

let query = Planet.query(on: req.db)
if req.db is SQLDatabase {
    // Il database è SQL, quindi possiamo usare le espressioni SQL personalizzate
    query.filter(.sql(raw: "LOWER(name) = 'earth'"))
} else {
    // Il database non è SQL
}
```

Di seguito è riportato un esempio di `.custom` tramite la convenienza `.sql(raw:)` utilizzata con il costruttore di schema.

```swift
import FluentSQL

let builder = database.schema("planets").id()
if database is MySQLDatabase {
    // Il database è MySQL
    builder.field("name", .sql(raw: "VARCHAR(64)"), .required)
} else {
    // Il database non è MySQL
    builder.field("name", .string, .required)
}
builder.create()
```

## MongoDB

Fluent MongoDB è un'integrazione tra [Fluent](../fluent/overview.it.md) e il driver [MongoKitten](https://github.com/OpenKitten/MongoKitten/). Sfrutta il forte sistema di tipi di Swift e l'interfaccia indipendente dal database di Fluent utilizzando MongoDB.

L'identificatore più comune in MongoDB è ObjectId. Puoi usarlo per il tuo progetto usando `@ID(custom: .id)`.
Se hai bisogno di usare gli stessi modelli con SQL, non usare `ObjectId`. Usa `UUID` invece.

```swift
final class User: Model {
    // Nome della tabella o collezione.
    static let schema = "users"

    // Identificatore univoco per questo User.
    // In questo caso, viene utilizzato ObjectId
    // Fluent consiglia di utilizzare UUID per impostazione predefinita, tuttavia ObjectId è supportato
    @ID(custom: .id)
    var id: ObjectId?

    // L'indirizzo email dell'utente
    @Field(key: "email")
    var email: String

    // Il profilo dell'utente, memorizzato come un hash Bcrypt
    @Field(key: "password")
    var passwordHash: String

    // Crea un nuovo profilo per questo utente
    init() { }

    // Crea un nuovo profilo per questo utente con tutte le proprietà impostate
    init(id: ObjectId? = nil, email: String, passwordHash: String, profile: Profile) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.profile = profile
    }
}
```

### Modellazione dei Dati

In MongoDB, i modelli sono definiti allo stesso modo di qualsiasi altro ambiente Fluent. La principale differenza tra i database SQL e MongoDB risiede nelle relazioni e nell'architettura.

Negli ambienti SQL, è molto comune creare tabelle di join per le relazioni tra due entità. In MongoDB, invece, si può usare un array per memorizzare gli identificatori correlati. A causa del design di MongoDB, è più efficiente e pratico progettare i tuoi modelli con strutture dati annidate.

### Dati Flessibili

Puoi aggiungere dati flessibili in MongoDB, ma questo codice non funzionerà in ambienti SQL.
Per creare uno spazio di archiviazione dati arbitrario raggruppato puoi usare `Document`.

```swift
@Field(key: "document")
var document: Document
```

Fluent non supporta query con tipi rigorosi su questi valori. Puoi usare un percorso chiave con notazione a punti nella tua query.
Questo è accettato in MongoDB per accedere ai valori annidati.

```swift
Something.query(on: db).filter("document.key", .equal, 5).first()
```

### Uso delle Espressioni Regolari

Puoi interrogare MongoDB usando il caso `.custom()`, passando un'espressione regolare. [MongoDB](https://www.mongodb.com/docs/manual/reference/operator/query/regex/) accetta espressioni regolari compatibili con Perl.

Per esempio, puoi cercare caratteri senza distinzione tra maiuscole e minuscole nel campo `name`:

```swift
import FluentMongoDriver

var queryDocument = Document()
queryDocument["name"]["$regex"] = "e"
queryDocument["name"]["$options"] = "i"

let planets = try Planet.query(on: req.db).filter(.custom(queryDocument)).all()
```

Questo restituirà i pianeti contenenti 'e' ed 'E'. Puoi anche creare qualsiasi altra espressione RegEx complessa accettata da MongoDB.

### Accesso Diretto

Per accedere all'istanza grezza di `MongoDatabase`, converti l'istanza del database in `MongoDatabaseRepresentable` come segue:

```swift
guard let db = req.db as? MongoDatabaseRepresentable else {
  throw Abort(.internalServerError)
}

let mongodb = db.raw
```

Da qui puoi utilizzare tutte le API di MongoKitten.
