# Fluent

Fluent è un framework [ORM](https://en.wikipedia.org/wiki/Object-relational_mapping) per Swift. Sfrutta il forte sistema di tipi di Swift per fornire un'interfaccia facile da usare per il tuo database. L'uso di Fluent si concentra sulla creazione di tipi di modello che rappresentano le strutture dati nel tuo database. Questi modelli vengono poi usati per eseguire operazioni di creazione, lettura, aggiornamento ed eliminazione invece di scrivere query grezze.

## Configurazione

Quando crei un progetto usando `vapor new`, rispondi "sì" per includere Fluent e scegli quale driver di database vuoi usare. Questo aggiungerà automaticamente le dipendenze al tuo nuovo progetto così come il codice di configurazione di esempio.

### Progetto Esistente

Se hai un progetto esistente a cui vuoi aggiungere Fluent, dovrai aggiungere due dipendenze al tuo [package](../getting-started/spm.it.md):

- [vapor/fluent](https://github.com/vapor/fluent)@4.0.0
- Uno (o più) driver Fluent a tua scelta

```swift
.package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
.package(url: "https://github.com/vapor/fluent-<db>-driver.git", from: <version>),
```

```swift
.target(name: "App", dependencies: [
    .product(name: "Fluent", package: "fluent"),
    .product(name: "Fluent<db>Driver", package: "fluent-<db>-driver"),
    .product(name: "Vapor", package: "vapor"),
]),
```

Una volta aggiunti i pacchetti come dipendenze, puoi configurare i tuoi database usando `app.databases` in `configure.swift`.

```swift
import Fluent
import Fluent<db>Driver

app.databases.use(<db config>, as: <identifier>)
```

Ciascuno dei driver Fluent qui sotto ha istruzioni più specifiche per la configurazione.

### Driver

Fluent ha attualmente quattro driver ufficialmente supportati. Puoi cercare su GitHub il tag [`fluent-driver`](https://github.com/topics/fluent-driver) per un elenco completo dei driver di database Fluent ufficiali e di terze parti.

#### PostgreSQL

PostgreSQL è un database SQL open source e conforme agli standard. È facilmente configurabile sulla maggior parte dei provider di hosting cloud. Questo è il driver di database **raccomandato** da Fluent.

Per usare PostgreSQL, aggiungi le seguenti dipendenze al tuo package.

```swift
.package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0")
```

```swift
.product(name: "FluentPostgresDriver", package: "fluent-postgres-driver")
```

Una volta aggiunte le dipendenze, configura le credenziali del database con Fluent usando `app.databases.use` in `configure.swift`.

```swift
import Fluent
import FluentPostgresDriver

app.databases.use(
    .postgres(
        configuration: .init(
            hostname: "localhost",
            username: "vapor",
            password: "vapor",
            database: "vapor",
            tls: .disable
        )
    ),
    as: .psql
)
```

Puoi anche analizzare le credenziali da una stringa di connessione al database.

```swift
try app.databases.use(.postgres(url: "<connection string>"), as: .psql)
```

#### SQLite

SQLite è un database SQL open source e incorporato. La sua natura semplicistica lo rende un ottimo candidato per la prototipazione e il testing.

Per usare SQLite, aggiungi le seguenti dipendenze al tuo package.

```swift
.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
```

Una volta aggiunte le dipendenze, configura il database con Fluent usando `app.databases.use` in `configure.swift`.

```swift
import Fluent
import FluentSQLiteDriver

app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
```

Puoi anche configurare SQLite per memorizzare il database temporaneamente in memoria.

```swift
app.databases.use(.sqlite(.memory), as: .sqlite)
```

Se usi un database in memoria, assicurati di impostare Fluent per la migrazione automatica usando `--auto-migrate` o esegui `app.autoMigrate()` dopo aver aggiunto le migrazioni.

```swift
app.migrations.add(CreateTodo())
try app.autoMigrate().wait()
// oppure
try await app.autoMigrate()
```

!!! tip "Suggerimento"
    La configurazione SQLite abilita automaticamente i vincoli di chiave esterna su tutte le connessioni create, ma non modifica le configurazioni di chiave esterna nel database stesso. L'eliminazione di record direttamente nel database potrebbe violare i vincoli e i trigger delle chiavi esterne.

#### MySQL

MySQL è un popolare database SQL open source. È disponibile su molti provider di hosting cloud. Questo driver supporta anche MariaDB.

Per usare MySQL, aggiungi le seguenti dipendenze al tuo package.

```swift
.package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0")
```

```swift
.product(name: "FluentMySQLDriver", package: "fluent-mysql-driver")
```

Una volta aggiunte le dipendenze, configura le credenziali del database con Fluent usando `app.databases.use` in `configure.swift`.

```swift
import Fluent
import FluentMySQLDriver

app.databases.use(.mysql(hostname: "localhost", username: "vapor", password: "vapor", database: "vapor"), as: .mysql)
```

Puoi anche analizzare le credenziali da una stringa di connessione al database.

```swift
try app.databases.use(.mysql(url: "<connection string>"), as: .mysql)
```

Per configurare una connessione locale senza certificato SSL, dovresti disabilitare la verifica del certificato. Potrebbe essere necessario farlo, per esempio, se ci si connette a un database MySQL 8 in Docker.

```swift
var tls = TLSConfiguration.makeClientConfiguration()
tls.certificateVerification = .none

app.databases.use(.mysql(
    hostname: "localhost",
    username: "vapor",
    password: "vapor",
    database: "vapor",
    tlsConfiguration: tls
), as: .mysql)
```

!!! warning "Attenzione"
    Non disabilitare la verifica del certificato in produzione. Dovresti fornire un certificato a `TLSConfiguration` con cui verificare.

#### MongoDB

MongoDB è un popolare database NoSQL senza schema progettato per i programmatori. Il driver supporta tutti i provider di hosting cloud e le installazioni self-hosted dalla versione 3.4 in su.

!!! note "Nota"
    Questo driver è alimentato da un client MongoDB creato e mantenuto dalla community chiamato [MongoKitten](https://github.com/OpenKitten/MongoKitten). MongoDB mantiene un client ufficiale, [mongo-swift-driver](https://github.com/mongodb/mongo-swift-driver), insieme a un'integrazione Vapor, [mongodb-vapor](https://github.com/mongodb/mongodb-vapor).

Per usare MongoDB, aggiungi le seguenti dipendenze al tuo package.

```swift
.package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.0.0"),
```

```swift
.product(name: "FluentMongoDriver", package: "fluent-mongo-driver")
```

Una volta aggiunte le dipendenze, configura le credenziali del database con Fluent usando `app.databases.use` in `configure.swift`.

Per connetterti, passa una stringa di connessione nel formato [URI di connessione](https://docs.mongodb.com/docs/manual/reference/connection-string/) standard di MongoDB.

```swift
import Fluent
import FluentMongoDriver

try app.databases.use(.mongo(connectionString: "<connection string>"), as: .mongo)
```

## Modelli

I modelli rappresentano strutture dati fisse nel tuo database, come tabelle o collezioni. I modelli hanno uno o più campi che memorizzano valori codificabili. Tutti i modelli hanno anche un identificatore univoco. I property wrapper vengono usati per denotare identificatori e campi così come le mappature più complesse menzionate in seguito. Dai un'occhiata al seguente modello che rappresenta una galassia.

```swift
final class Galaxy: Model {
    // Nome della tabella o collezione.
    static let schema = "galaxies"

    // Identificatore univoco per questa Galassia.
    @ID(key: .id)
    var id: UUID?

    // Il nome della Galassia.
    @Field(key: "name")
    var name: String

    // Crea una nuova Galassia vuota.
    init() { }

    // Crea una nuova Galassia con tutte le proprietà impostate.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

Per creare un nuovo modello, crea una nuova classe che si conforma a `Model`.

!!! tip "Suggerimento"
    Si raccomanda di marcare le classi modello come `final` per migliorare le prestazioni e semplificare i requisiti di conformità.

Il primo requisito del protocollo `Model` è la stringa statica `schema`.

```swift
static let schema = "galaxies"
```

Questa proprietà dice a Fluent a quale tabella o collezione corrisponde il modello. Può essere una tabella che esiste già nel database o una che creerai con una [migrazione](#migrazioni). Lo schema è di solito in `snake_case` e al plurale.

### Identificatore

Il prossimo requisito è un campo identificatore denominato `id`.

```swift
@ID(key: .id)
var id: UUID?
```

Questo campo deve usare il property wrapper `@ID`. Fluent raccomanda di usare `UUID` e la chiave di campo speciale `.id` poiché questo è compatibile con tutti i driver di Fluent.

Se vuoi usare una chiave o un tipo di ID personalizzato, usa l'overload [`@ID(custom:)`](model.it.md#identificatore-personalizzato).

### Campi

Dopo aver aggiunto l'identificatore, puoi aggiungere quanti campi vuoi per memorizzare informazioni aggiuntive. In questo esempio, l'unico campo aggiuntivo è il nome della galassia.

```swift
@Field(key: "name")
var name: String
```

Per i campi semplici, viene usato il property wrapper `@Field`. Come `@ID`, il parametro `key` specifica il nome del campo nel database. Questo è particolarmente utile per i casi in cui la convenzione di denominazione dei campi del database potrebbe essere diversa da quella in Swift, ad es. usando `snake_case` invece di `camelCase`.

Successivamente, tutti i modelli richiedono un init vuoto. Questo permette a Fluent di creare nuove istanze del modello.

```swift
init() { }
```

Infine, puoi aggiungere un init di convenienza per il tuo modello che imposta tutte le sue proprietà.

```swift
init(id: UUID? = nil, name: String) {
    self.id = id
    self.name = name
}
```

L'uso degli init di convenienza è particolarmente utile se aggiungi nuove proprietà al tuo modello poiché puoi ottenere errori a tempo di compilazione se il metodo init cambia.

## Migrazioni

Se il tuo database usa schemi predefiniti, come i database SQL, avrai bisogno di una migrazione per preparare il database per il tuo modello. Le migrazioni sono anche utili per popolare i database con dati. Per creare una migrazione, definisci un nuovo tipo che si conforma al protocollo `Migration` o `AsyncMigration`. Dai un'occhiata alla seguente migrazione per il modello `Galaxy` precedentemente definito.

```swift
struct CreateGalaxy: AsyncMigration {
    // Prepara il database per memorizzare i modelli Galaxy.
    func prepare(on database: Database) async throws {
        try await database.schema("galaxies")
            .id()
            .field("name", .string)
            .create()
    }

    // Ripristina opzionalmente le modifiche apportate nel metodo prepare.
    func revert(on database: Database) async throws {
        try await database.schema("galaxies").delete()
    }
}
```

Il metodo `prepare` viene usato per preparare il database per memorizzare i modelli `Galaxy`.

### Schema

In questo metodo, `database.schema(_:)` viene usato per creare un nuovo `SchemaBuilder`. Uno o più `field` vengono poi aggiunti al builder prima di chiamare `create()` per creare lo schema.

Ogni campo aggiunto al builder ha un nome, un tipo e vincoli opzionali.

```swift
field(<name>, <type>, <optional constraints>)
```

C'è un metodo di convenienza `id()` per aggiungere proprietà `@ID` usando i valori predefiniti raccomandati di Fluent.

Il ripristino della migrazione annulla qualsiasi modifica apportata nel metodo prepare. In questo caso, ciò significa eliminare lo schema della Galaxy.

Una volta definita la migrazione, devi comunicarla a Fluent aggiungendola a `app.migrations` in `configure.swift`.

```swift
app.migrations.add(CreateGalaxy())
```

### Migrazioni

Per eseguire le migrazioni, chiama `swift run App migrate` dalla riga di comando o aggiungi `migrate` come argomento allo schema App di Xcode.

```
$ swift run App migrate
Migrate Command: Prepare
The following migration(s) will be prepared:
+ CreateGalaxy on default
Would you like to continue?
y/n> y
Migration successful
```

## Query

Ora che hai creato con successo un modello e migrato il tuo database, sei pronto per fare la tua prima query.

### All

Dai un'occhiata alla seguente route che restituirà un array di tutte le galassie nel database.

```swift
app.get("galaxies") { req async throws in
    try await Galaxy.query(on: req.db).all()
}
```

Per restituire una Galaxy direttamente in una closure di route, aggiungi la conformità a `Content`.

```swift
final class Galaxy: Model, Content {
    ...
}
```

`Galaxy.query` viene usato per creare un nuovo query builder per il modello. `req.db` è un riferimento al database predefinito per la tua applicazione. Infine, `all()` restituisce tutti i modelli memorizzati nel database.

Se compili ed esegui il progetto e richiedi `GET /galaxies`, dovresti vedere un array vuoto restituito. Aggiungiamo una route per creare una nuova galassia.

### Creazione

Seguendo la convenzione RESTful, usa l'endpoint `POST /galaxies` per creare una nuova galassia. Poiché i modelli sono codificabili, puoi decodificare una galassia direttamente dal corpo della richiesta.

```swift
app.post("galaxies") { req -> EventLoopFuture<Galaxy> in
    let galaxy = try req.content.decode(Galaxy.self)
    return galaxy.create(on: req.db)
        .map { galaxy }
}
```

!!! seealso "Vedi anche"
    Vedi [Content &rarr; Panoramica](../basics/content.it.md) per ulteriori informazioni sulla decodifica dei corpi delle richieste.

Una volta che hai un'istanza del modello, chiamare `create(on:)` salva il modello nel database. Questo restituisce un `EventLoopFuture<Void>` che segnala che il salvataggio è completato. Una volta completato il salvataggio, restituisci il modello appena creato usando `map`.

Se stai usando `async`/`await` puoi scrivere il tuo codice così:

```swift
app.post("galaxies") { req async throws -> Galaxy in
    let galaxy = try req.content.decode(Galaxy.self)
    try await galaxy.create(on: req.db)
    return galaxy
}
```

In questo caso, la versione async non restituisce nulla, ma restituirà una volta completato il salvataggio.

Compila ed esegui il progetto e invia la seguente richiesta.

```http
POST /galaxies HTTP/1.1
content-length: 21
content-type: application/json

{
    "name": "Milky Way"
}
```

Dovresti ricevere il modello creato con un identificatore come risposta.

```json
{
    "id": ...,
    "name": "Milky Way"
}
```

Ora, se esegui di nuovo la query `GET /galaxies`, dovresti vedere la galassia appena creata restituita nell'array.

## Relazioni

Cosa sono le galassie senza stelle! Diamo un'occhiata rapida alle potenti funzionalità relazionali di Fluent aggiungendo una relazione uno-a-molti tra `Galaxy` e un nuovo modello `Star`.

```swift
final class Star: Model, Content {
    // Nome della tabella o collezione.
    static let schema = "stars"

    // Identificatore univoco per questa Stella.
    @ID(key: .id)
    var id: UUID?

    // Il nome della Stella.
    @Field(key: "name")
    var name: String

    // Riferimento alla Galassia a cui appartiene questa Stella.
    @Parent(key: "galaxy_id")
    var galaxy: Galaxy

    // Crea una nuova Stella vuota.
    init() { }

    // Crea una nuova Stella con tutte le proprietà impostate.
    init(id: UUID? = nil, name: String, galaxyID: UUID) {
        self.id = id
        self.name = name
        self.$galaxy.id = galaxyID
    }
}
```

### Parent

Il nuovo modello `Star` è molto simile a `Galaxy` tranne per un nuovo tipo di campo: `@Parent`.

```swift
@Parent(key: "galaxy_id")
var galaxy: Galaxy
```

La proprietà parent è un campo che memorizza l'identificatore di un altro modello. Il modello che contiene il riferimento è chiamato "figlio" e il modello a cui si fa riferimento è chiamato "genitore". Questo tipo di relazione è anche noto come "uno-a-molti". Il parametro `key` della proprietà specifica il nome del campo da usare per memorizzare la chiave del genitore nel database.

Nel metodo init, l'identificatore del genitore viene impostato usando `$galaxy`.

```swift
self.$galaxy.id = galaxyID
```

Anteporre il nome della proprietà parent con `$` ti consente di accedere al property wrapper sottostante. Questo è necessario per ottenere l'accesso all'`@Field` interno che memorizza il valore dell'identificatore effettivo.

!!! seealso "Vedi anche"
    Consulta la proposta Swift Evolution per i property wrapper per ulteriori informazioni: [[SE-0258] Property Wrappers](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0258-property-wrappers.md)

Successivamente, crea una migrazione per preparare il database a gestire `Star`.

```swift
struct CreateStar: AsyncMigration {
    // Prepara il database per memorizzare i modelli Star.
    func prepare(on database: Database) async throws {
        try await database.schema("stars")
            .id()
            .field("name", .string)
            .field("galaxy_id", .uuid, .references("galaxies", "id"))
            .create()
    }

    // Ripristina opzionalmente le modifiche apportate nel metodo prepare.
    func revert(on database: Database) async throws {
        try await database.schema("stars").delete()
    }
}
```

Questo è praticamente uguale alla migrazione della galassia tranne per il campo aggiuntivo per memorizzare l'identificatore della galassia genitore.

```swift
field("galaxy_id", .uuid, .references("galaxies", "id"))
```

Questo campo specifica un vincolo opzionale che dice al database che il valore del campo fa riferimento al campo "id" nello schema "galaxies". Questo è anche noto come chiave esterna e aiuta a garantire l'integrità dei dati.

Una volta creata la migrazione, aggiungila a `app.migrations` dopo la migrazione `CreateGalaxy`.

```swift
app.migrations.add(CreateGalaxy())
app.migrations.add(CreateStar())
```

Poiché le migrazioni vengono eseguite in ordine e `CreateStar` fa riferimento allo schema delle galassie, l'ordinamento è importante. Infine, [esegui le migrazioni](#migrazioni) per preparare il database.

Aggiungi una route per creare nuove stelle.

```swift
app.post("stars") { req async throws -> Star in
    let star = try req.content.decode(Star.self)
    try await star.create(on: req.db)
    return star
}
```

Crea una nuova stella che fa riferimento alla galassia precedentemente creata usando la seguente richiesta HTTP.

```http
POST /stars HTTP/1.1
content-length: 36
content-type: application/json

{
    "name": "Sun",
    "galaxy": {
        "id": ...
    }
}
```

Dovresti vedere la nuova stella creata restituita con un identificatore univoco.

```json
{
    "id": ...,
    "name": "Sun",
    "galaxy": {
        "id": ...
    }
}
```

### Children

Ora vediamo come puoi utilizzare la funzionalità di eager loading di Fluent per restituire automaticamente le stelle di una galassia nella route `GET /galaxies`. Aggiungi la seguente proprietà al modello `Galaxy`.

```swift
// All the Stars in this Galaxy.
@Children(for: \.$galaxy)
var stars: [Star]
```

Il property wrapper `@Children` è l'inverso di `@Parent`. Accetta un key-path al campo `@Parent` del figlio come argomento `for`. Il suo valore è un array di figli poiché possono esistere zero o più modelli figlio. Non sono necessarie modifiche alla migrazione della galassia poiché tutte le informazioni necessarie per questa relazione sono memorizzate su `Star`.

### Eager Load

Ora che la relazione è completa, puoi usare il metodo `with` sul query builder per recuperare e serializzare automaticamente la relazione galassia-stella.

```swift
app.get("galaxies") { req in
    try await Galaxy.query(on: req.db).with(\.$stars).all()
}
```

Un key-path alla relazione `@Children` viene passato a `with` per dire a Fluent di caricare automaticamente questa relazione in tutti i modelli risultanti. Compila ed esegui e invia un'altra richiesta a `GET /galaxies`. Dovresti ora vedere le stelle automaticamente incluse nella risposta.

```json
[
    {
        "id": ...,
        "name": "Milky Way",
        "stars": [
            {
                "id": ...,
                "name": "Sun",
                "galaxy": {
                    "id": ...
                }
            }
        ]
    }
]
```

## Logging delle Query

I driver Fluent registrano l'SQL generato al livello di log di debug. Alcuni driver, come FluentPostgreSQL, consentono di configurarlo quando si configura il database.

Per impostare il livello di log, in **configure.swift** (o dove si imposta l'applicazione) aggiungi:

```swift
app.logger.logLevel = .debug
```

Questo imposta il livello di log su debug. La prossima volta che compili ed esegui la tua app, le istruzioni SQL generate da Fluent verranno registrate nella console.

## Prossimi Passi

Congratulazioni per aver creato i tuoi primi modelli e migrazioni e per aver eseguito operazioni di base di creazione e lettura. Per informazioni più approfondite su tutte queste funzionalità, consulta le rispettive sezioni nella guida di Fluent.
