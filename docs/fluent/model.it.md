# Modelli

I modelli rappresentano i dati memorizzati in tabelle o collezioni nel tuo database. I modelli hanno uno o più campi che memorizzano valori codificabili. Tutti i modelli hanno un identificatore univoco. I property wrapper vengono usati per denotare identificatori, campi e relazioni.

Di seguito è riportato un esempio di un modello semplice con un solo campo. Nota che i modelli non descrivono l'intero schema del database, come vincoli, indici e chiavi esterne. Gli schemi sono definiti nelle [migrazioni](migration.it.md). I modelli sono focalizzati sulla rappresentazione dei dati memorizzati negli schemi del tuo database.

```swift
final class Planet: Model {
    // Name of the table or collection.
    static let schema = "planets"

    // Unique identifier for this Planet.
    @ID(key: .id)
    var id: UUID?

    // The Planet's name.
    @Field(key: "name")
    var name: String

    // Creates a new, empty Planet.
    init() { }

    // Creates a new Planet with all properties set.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

## Schema

Tutti i modelli richiedono una proprietà `schema` statica e di sola lettura. Questa stringa fa riferimento al nome della tabella o collezione che questo modello rappresenta.

```swift
final class Planet: Model {
    // Name of the table or collection.
    static let schema = "planets"
}
```

Quando si interroga questo modello, i dati verranno recuperati e memorizzati nello schema denominato `"planets"`.

!!! tip "Suggerimento"
    Il nome dello schema è tipicamente il nome della classe al plurale e in minuscolo.

## Identificatore

Tutti i modelli devono avere una proprietà `id` definita usando il property wrapper `@ID`. Questo campo identifica in modo univoco le istanze del tuo modello.

```swift
final class Planet: Model {
    // Unique identifier for this Planet.
    @ID(key: .id)
    var id: UUID?
}
```

Per impostazione predefinita, la proprietà `@ID` dovrebbe usare la chiave speciale `.id` che si risolve in una chiave appropriata per il driver di database sottostante. Per SQL è `"id"` e per NoSQL è `"_id"`.

`@ID` dovrebbe essere anche di tipo `UUID`. Questo è l'unico valore identificatore attualmente supportato da tutti i driver di database. Fluent genererà automaticamente nuovi identificatori UUID quando i modelli vengono creati.

`@ID` ha un valore opzionale poiché i modelli non salvati potrebbero non avere ancora un identificatore. Per ottenere l'identificatore o lanciare un errore, usa `requireID`.

```swift
let id = try planet.requireID()
```

### Exists

`@ID` ha una proprietà `exists` che rappresenta se il modello esiste nel database o meno. Quando inizializzi un modello, il valore è `false`. Dopo aver salvato un modello o quando recuperi un modello dal database, il valore è `true`. Questa proprietà è mutabile.

```swift
if planet.$id.exists {
    // Questo modello esiste nel database.
}
```

### Identificatore Personalizzato

Fluent supporta chiavi e tipi di identificatore personalizzati usando l'overload `@ID(custom:)`.

```swift
final class Planet: Model {
    // Identificatore univoco per questo Planet.
    @ID(custom: "foo")
    var id: Int?
}
```

L'esempio sopra usa un `@ID` con la chiave personalizzata `"foo"` e il tipo di identificatore `Int`. Questo è compatibile con i database SQL che usano chiavi primarie con incremento automatico, ma non è compatibile con NoSQL.

Gli `@ID` personalizzati consentono all'utente di specificare come deve essere generato l'identificatore usando il parametro `generatedBy`.

```swift
@ID(custom: "foo", generatedBy: .user)
```

Il parametro `generatedBy` supporta questi casi:

|Generato Da|Descrizione|
|-|-|
|`.user`|La proprietà `@ID` deve essere impostata prima di salvare un nuovo modello.|
|`.random`|Il tipo di valore `@ID` deve conformarsi a `RandomGeneratable`.|
|`.database`|Il database è previsto che generi un valore al momento del salvataggio.|

Se il parametro `generatedBy` viene omesso, Fluent tenterà di dedurre un caso appropriato in base al tipo di valore `@ID`. Per esempio, `Int` avrà come default la generazione `.database` a meno che non sia specificato diversamente.

## Inizializzatore

I modelli devono avere un metodo inizializzatore vuoto.

```swift
final class Planet: Model {
    // Creates a new, empty Planet.
    init() { }
}
```

Fluent richiede questo metodo internamente per inizializzare i modelli restituiti dalle query. Viene anche usato per la riflessione.

Potresti voler aggiungere un inizializzatore di convenienza al tuo modello che accetta tutte le proprietà.

```swift
final class Planet: Model {
    // Crea un nuovo Planet con tutte le proprietà impostate.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

L'uso di inizializzatori di convenienza rende più facile aggiungere nuove proprietà al modello in futuro.

## Campo

I modelli possono avere zero o più proprietà `@Field` per memorizzare dati.

```swift
final class Planet: Model {
    // Il nome del Planet.
    @Field(key: "name")
    var name: String
}
```

I campi richiedono che la chiave del database sia definita esplicitamente. Non è necessario che sia uguale al nome della proprietà.

!!! tip "Suggerimento"
    Fluent raccomanda di usare `snake_case` per le chiavi del database e `camelCase` per i nomi delle proprietà.

I valori dei campi possono essere di qualsiasi tipo che si conformi a `Codable`. Memorizzare strutture annidate e array in `@Field` è supportato, ma le operazioni di filtraggio sono limitate. Vedi [`@Group`](#group) per un'alternativa.

Per i campi che contengono un valore opzionale, usa `@OptionalField`.

```swift
@OptionalField(key: "tag")
var tag: String?
```

!!! warning "Attenzione"
    Un campo non opzionale che ha un osservatore di proprietà `willSet` che fa riferimento al suo valore corrente o un osservatore di proprietà `didSet` che fa riferimento al suo `oldValue` provocherà un errore fatale.

## Relazioni

I modelli possono avere zero o più proprietà di relazione che fanno riferimento ad altri modelli come `@Parent`, `@Children` e `@Siblings`. Per saperne di più sulle relazioni, consulta la sezione [relazioni](relations.it.md).

## Timestamp

`@Timestamp` è un tipo speciale di `@Field` che memorizza una `Foundation.Date`. I timestamp vengono impostati automaticamente da Fluent in base al trigger scelto.

```swift
final class Planet: Model {
    // Quando questo Planet è stato creato.
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    // Quando questo Planet è stato aggiornato l'ultima volta.
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
}
```

`@Timestamp` supporta i seguenti trigger.

|Trigger|Descrizione|
|-|-|
|`.create`|Impostato quando una nuova istanza del modello viene salvata nel database.|
|`.update`|Impostato quando un'istanza del modello esistente viene salvata nel database.|
|`.delete`|Impostato quando un modello viene eliminato dal database. Vedi [eliminazione temporanea](#eliminazione-temporanea).|

Il valore data di `@Timestamp` è opzionale e dovrebbe essere impostato a `nil` quando si inizializza un nuovo modello.

### Formato Timestamp

Per impostazione predefinita, `@Timestamp` utilizzerà una codifica `datetime` efficiente basata sul tuo driver di database. Puoi personalizzare come il timestamp viene memorizzato nel database usando il parametro `format`.

```swift
// Memorizza un timestamp formattato ISO 8601 rappresentante
// quando questo modello è stato aggiornato l'ultima volta.
@Timestamp(key: "updated_at", on: .update, format: .iso8601)
var updatedAt: Date?
```

Nota che la migrazione associata per questo esempio `.iso8601` richiederebbe la memorizzazione in formato `.string`.

```swift
.field("updated_at", .string)
```

I formati di timestamp disponibili sono elencati di seguito.

|Formato|Descrizione|Tipo|
|-|-|-|
|`.default`|Usa la codifica `datetime` efficiente per il database specifico.|Date|
|`.iso8601`|Stringa [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601). Supporta il parametro `withMilliseconds`.|String|
|`.unix`|Secondi dall'epoca Unix inclusa la frazione.|Double|

Puoi accedere al valore grezzo del timestamp direttamente usando la proprietà `timestamp`.

```swift
// Imposta manualmente il valore del timestamp su questo @Timestamp 
// formattato ISO 8601.
model.$updatedAt.timestamp = "2020-06-03T16:20:14+00:00"
```

### Eliminazione Temporanea

Aggiungere un `@Timestamp` che usa il trigger `.delete` al tuo modello abiliterà l'eliminazione temporanea.

```swift
final class Planet: Model {
    // Quando questo Planet è stato eliminato.
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?
}
```

I modelli eliminati temporaneamente esistono ancora nel database dopo l'eliminazione, ma non verranno restituiti nelle query.

!!! tip "Suggerimento"
    Puoi impostare manualmente un timestamp di eliminazione a una data nel futuro. Questo può essere usato come data di scadenza.

Per forzare la rimozione dal database di un modello eliminabile temporaneamente, usa il parametro `force` in `delete`.

```swift
// Elimina dal database anche se il modello è eliminabile temporaneamente.
model.delete(force: true, on: database)
```

Per ripristinare un modello eliminato temporaneamente, usa il metodo `restore`.

```swift
// Cancella il timestamp di eliminazione permettendo a questo
// modello di essere restituito nelle query.
model.restore(on: database)
```

Per includere i modelli eliminati temporaneamente in una query, usa `withDeleted`.

```swift
// Recupera tutti i pianeti inclusi quelli eliminati temporaneamente.
Planet.query(on: database).withDeleted().all()
```

## Enum

`@Enum` è un tipo speciale di `@Field` per memorizzare tipi rappresentabili come stringhe come enum nativi del database. Gli enum nativi del database forniscono un ulteriore livello di sicurezza dei tipi al tuo database e possono essere più performanti degli enum grezzi.

```swift
// Enum rappresentabile come stringa e conforme a Codable per i tipi di animali.
enum Animal: String, Codable {
    case dog, cat
}

final class Pet: Model {
    // Memorizza il tipo di animale come enum nativo del database.
    @Enum(key: "type")
    var type: Animal
}
```

Solo i tipi che si conformano a `RawRepresentable` dove `RawValue` è `String` sono compatibili con `@Enum`. Gli enum basati su `String` soddisfano questo requisito per impostazione predefinita.

Per memorizzare un enum opzionale, usa `@OptionalEnum`.

Il database deve essere preparato per gestire gli enum tramite una migrazione. Vedi [enum](schema.it.md#enum) per ulteriori informazioni.

### Enum Grezzi

Qualsiasi enum basato su un tipo `Codable`, come `String` o `Int`, può essere memorizzato in `@Field`. Verrà memorizzato nel database come valore grezzo.

## Group

`@Group` ti consente di memorizzare un gruppo annidato di campi come una singola proprietà sul tuo modello. A differenza delle struct Codable memorizzate in un `@Field`, i campi in un `@Group` sono interrogabili. Fluent ottiene questo memorizzando `@Group` come struttura piatta nel database.

Per usare un `@Group`, prima definisci la struttura annidata che vorresti memorizzare usando il protocollo `Fields`. Questo è molto simile a `Model` tranne che non è richiesto nessun identificatore o nome schema. Puoi memorizzare qui molte proprietà che `Model` supporta come `@Field`, `@Enum` o anche un altro `@Group`.

```swift
// Un animale con nome e tipo.
final class Pet: Fields {
    // Il nome del Pet.
    @Field(key: "name")
    var name: String

    // Il tipo di Pet.
    @Field(key: "type")
    var type: String

    // Crea un nuovo Pet vuoto.
    init() { }
}
```

Dopo aver creato la definizione dei campi, puoi usarla come valore di una proprietà `@Group`.

```swift
final class User: Model {
    // Il pet annidato dell'utente.
    @Group(key: "pet")
    var pet: Pet
}
```

I campi di un `@Group` sono accessibili tramite la sintassi a punti.

```swift
let user: User = ...
print(user.pet.name) // String
```

Puoi interrogare i campi annidati normalmente usando la sintassi a punti sui property wrapper.

```swift
User.query(on: database).filter(\.$pet.$name == "Zizek").all()
```

Nel database, `@Group` è memorizzato come una struttura piatta con le chiavi unite da `_`. Di seguito è riportato un esempio di come `User` apparirebbe nel database.

|id|name|pet_name|pet_type|
|-|-|-|-|
|1|Tanner|Zizek|Cat|
|2|Logan|Runa|Dog|

## Codable

I modelli si conformano a `Codable` per impostazione predefinita. Questo significa che puoi usare i tuoi modelli con l'[API dei contenuti](../basics/content.it.md) di Vapor aggiungendo la conformità al protocollo `Content`.

```swift
extension Planet: Content { }

app.get("planets") { req async throws in
    // Recupera tutti i pianeti dal database e li restituisce come JSON.
    try await Planet.query(on: req.db).all()
}
```

Quando si serializza da/verso `Codable`, le proprietà del modello useranno i loro nomi di variabile invece delle chiavi. Le relazioni verranno serializzate come strutture annidate e qualsiasi dato caricato in modo eager verrà incluso.

!!! info "Informazione"
    Raccomandiamo che nella quasi totalità dei casi tu utilizzi un DTO invece di un modello per le risposte dell'API e i corpi delle richieste. Vedi [Data Transfer Object](#data-transfer-object) per ulteriori informazioni.

### Data Transfer Object

La conformità `Codable` predefinita del modello può rendere più facile l'utilizzo semplice e la prototipazione. Tuttavia, espone le informazioni del database sottostante all'API. Questo di solito non è desiderabile sia da un punto di vista della sicurezza - restituire campi sensibili come l'hash della password di un utente è una cattiva idea - sia da un punto di vista dell'usabilità. Rende difficile cambiare lo schema del database senza rompere l'API, accettare o restituire dati in un formato diverso, o aggiungere o rimuovere campi dall'API.

Per la maggior parte dei casi dovresti usare un DTO, o data transfer object, invece di un modello (noto anche come domain transfer object). Un DTO è un tipo `Codable` separato che rappresenta la struttura dati che vorresti codificare o decodificare. Questi disaccoppiano la tua API dallo schema del database e ti consentono di apportare modifiche ai tuoi modelli senza rompere l'API pubblica della tua app, avere versioni diverse e rendere la tua API più gradevole da usare per i tuoi client.

Assume il seguente modello `User` negli esempi seguenti.

```swift
// Abridged user model for reference.
final class User: Model {
    @ID(key: .id)
    var id: UUID?

    @Field(key: "first_name")
    var firstName: String

    @Field(key: "last_name")
    var lastName: String
}
```

Un caso d'uso comune per i DTO è nell'implementazione delle richieste `PATCH`. Queste richieste includono solo i valori per i campi che devono essere aggiornati. Tentare di decodificare un `Model` direttamente da tale richiesta fallirebbe se mancasse uno qualsiasi dei campi richiesti. Nell'esempio seguente, puoi vedere un DTO utilizzato per decodificare i dati della richiesta e aggiornare un modello.

```swift
// Struttura della richiesta PATCH /users/:id.
struct PatchUser: Decodable {
    var firstName: String?
    var lastName: String?
}

app.patch("users", ":id") { req async throws -> User in
    // Decodifica i dati della richiesta.
    let patch = try req.content.decode(PatchUser.self)
    // Recupera l'utente desiderato dal database.
    guard let user = try await User.find(req.parameters.get("id"), on: req.db) else {
        throw Abort(.notFound)
    }
    // Se è stato fornito un nuovo nome, aggiornalo.
    if let firstName = patch.firstName {
        user.firstName = firstName
    }
    // Se è stato fornito un nuovo cognome, aggiornalo.
    if let lastName = patch.lastName {
        user.lastName = lastName
    }
    // Salva l'utente e restituiscilo.
    try await user.save(on: req.db)
    return user
}
```

Un altro caso d'uso comune per i DTO è la personalizzazione del formato delle risposte dell'API. L'esempio seguente mostra come un DTO può essere utilizzato per aggiungere un campo calcolato a una risposta.

```swift
// Struttura della risposta GET /users.
struct GetUser: Content {
    var id: UUID
    var name: String
}

app.get("users") { req async throws -> [GetUser] in
    // Recupera tutti gli utenti dal database.
    let users = try await User.query(on: req.db).all()
    return try users.map { user in
        // Converte ogni utente nel tipo di ritorno GET.
        try GetUser(
            id: user.requireID(),
            name: "\(user.firstName) \(user.lastName)"
        )
    }
}
```

Un altro caso d'uso comune è quando si lavora con le relazioni, come le relazioni parent o children. Vedi la [documentazione di Parent](relations.it.md##encoding-and-decoding-of-parents) per un esempio di come usare un DTO per rendere più facile decodificare un modello con una relazione `@Parent`.

Anche se la struttura del DTO è identica alla conformità `Codable` del modello, averlo come tipo separato può aiutare a mantenere in ordine i grandi progetti. Se hai mai bisogno di apportare una modifica alle proprietà dei tuoi modelli, non devi preoccuparti di rompere l'API pubblica della tua app. Potresti anche considerare di mettere i tuoi DTO in un pacchetto separato che può essere condiviso con i consumatori della tua API e aggiungere la conformità `Content` nella tua app Vapor.

## Alias

Il protocollo `ModelAlias` ti consente di identificare in modo univoco un modello che viene unito più volte in una query. Per ulteriori informazioni, vedi [join](query.it.md#join).

## Salvataggio

Per salvare un modello nel database, usa il metodo `save(on:)`.

```swift
planet.save(on: database)
```

Questo metodo chiamerà `create` o `update` internamente a seconda che il modello esista già nel database.

### Creazione

Puoi chiamare il metodo `create` per salvare un nuovo modello nel database.

```swift
let planet = Planet(name: "Earth")
planet.create(on: database)
```

`create` è disponibile anche su un array di modelli. Questo salva tutti i modelli nel database in un singolo batch/query.

```swift
// Esempio di creazione in batch.
[earth, mars].create(on: database)
```

!!! warning "Attenzione"
    I modelli che usano [`@ID(custom:)`](#identificatore-personalizzato) con il generatore `.database` (di solito `Int` con incremento automatico) non avranno i loro identificatori appena creati accessibili dopo la creazione in batch. Per le situazioni in cui hai bisogno di accedere agli identificatori, chiama `create` su ogni modello.

Per creare un array di modelli separatamente, usa `map` + `flatten`.

```swift
[earth, mars].map { $0.create(on: database) }
    .flatten(on: database.eventLoop)
```

Se si usa `async`/`await` puoi usare:

```swift
await withThrowingTaskGroup(of: Void.self) { taskGroup in
    [earth, mars].forEach { model in
        taskGroup.addTask { try await model.create(on: database) }
    }
}
```

### Aggiornamento

Puoi chiamare il metodo `update` per salvare un modello che è stato recuperato dal database.

```swift
guard let planet = try await Planet.find(..., on: database) else {
    throw Abort(.notFound)
}
planet.name = "Earth"
try await planet.update(on: database)
```

Per aggiornare un array di modelli, usa `map` + `flatten`.

```swift
[earth, mars].map { $0.update(on: database) }
    .flatten(on: database.eventLoop)

// TODO
```

## Query

I modelli espongono un metodo statico `query(on:)` che restituisce un query builder.

```swift
Planet.query(on: database).all()
```

Per saperne di più sulle query, consulta la sezione [query](query.it.md).

## Find

I modelli hanno un metodo statico `find(_:on:)` per cercare un'istanza del modello tramite identificatore.

```swift
Planet.find(req.parameters.get("id"), on: database)
```

Questo metodo restituisce `nil` se non viene trovato nessun modello con quell'identificatore.

## Ciclo di Vita

Il middleware del modello ti consente di agganciarti agli eventi del ciclo di vita del tuo modello. Sono supportati i seguenti eventi del ciclo di vita.

|Metodo|Descrizione|
|-|-|
|`create`|Eseguito prima che un modello venga creato.|
|`update`|Eseguito prima che un modello venga aggiornato.|
|`delete(force:)`|Eseguito prima che un modello venga eliminato.|
|`softDelete`|Eseguito prima che un modello venga eliminato temporaneamente.|
|`restore`|Eseguito prima che un modello venga ripristinato (opposto dell'eliminazione temporanea).|

Il middleware del modello viene dichiarato usando il protocollo `ModelMiddleware` o `AsyncModelMiddleware`. Tutti i metodi del ciclo di vita hanno un'implementazione predefinita, quindi devi implementare solo i metodi che richiedi. Ogni metodo accetta il modello in questione, un riferimento al database e l'azione successiva nella catena. Il middleware può scegliere di tornare presto, restituire un futuro fallito, o chiamare l'azione successiva per continuare normalmente.

Usando questi metodi puoi eseguire azioni sia prima che dopo il completamento dell'evento specifico. L'esecuzione di azioni dopo il completamento dell'evento può essere fatta mappando il futuro restituito dal responder successivo.

```swift
// Esempio di middleware che capitalizza i nomi.
struct PlanetMiddleware: ModelMiddleware {
    func create(model: Planet, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        // Il modello può essere modificato qui prima che venga creato.
        model.name = model.name.capitalized()
        return next.create(model, on: db).map {
            // Una volta che il pianeta è stato creato, il codice
            // qui verrà eseguito.
            print ("Planet \(model.name) was created")
        }
    }
}
```

oppure se si usa `async`/`await`:

```swift
struct PlanetMiddleware: AsyncModelMiddleware {
    func create(model: Planet, on db: Database, next: AnyAsyncModelResponder) async throws {
        // Il modello può essere modificato qui prima che venga creato.
        model.name = model.name.capitalized()
        try await next.create(model, on: db)
        // Una volta che il pianeta è stato creato, il codice
        // qui verrà eseguito.
        print ("Planet \(model.name) was created")
    }
}
```

Una volta creato il tuo middleware, puoi abilitarlo usando `app.databases.middleware`.

```swift
// Esempio di configurazione del middleware del modello.
app.databases.middleware.use(PlanetMiddleware(), on: .psql)
```

## Spazio del Database

Fluent supporta l'impostazione di uno spazio per un modello, che consente la partizione dei singoli modelli Fluent tra schemi PostgreSQL, database MySQL e più database SQLite collegati. MongoDB non supporta gli spazi al momento della stesura. Per collocare un modello in uno spazio diverso da quello predefinito, aggiungi una nuova proprietà statica al modello:

```swift
public static let schema = "planets"
public static let space: String? = "mirror_universe"

// ...
```

Fluent lo userà quando costruisce tutte le query del database.
