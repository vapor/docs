# Relazioni

L'[API dei modelli](model.it.md) di Fluent ti aiuta a creare e mantenere riferimenti tra i tuoi modelli attraverso le relazioni. Sono supportati tre tipi di relazioni:

- [Parent](#parent) / [Child](#optional-child) (Uno-a-uno)
- [Parent](#parent) / [Children](#children) (Uno-a-molti)
- [Siblings](#siblings) (Molti-a-molti)

## Parent

La relazione `@Parent` memorizza un riferimento alla proprietà `@ID` di un altro modello.

```swift
final class Planet: Model {
    // Esempio di relazione parent.
    @Parent(key: "star_id")
    var star: Star
}
```

`@Parent` contiene un `@Field` denominato `id` che viene usato per impostare e aggiornare la relazione.

```swift
// Imposta l'id della relazione parent
earth.$star.id = sun.id
```

Per esempio, l'inizializzatore di `Planet` apparirebbe così:

```swift
init(name: String, starID: Star.IDValue) {
    self.name = name
    // ...
    self.$star.id = starID
}
```

Il parametro `key` definisce la chiave del campo da usare per memorizzare l'identificatore del genitore. Assumendo che `Star` abbia un identificatore `UUID`, questa relazione `@Parent` è compatibile con la seguente [definizione di campo](schema.it.md#campo).

```swift
.field("star_id", .uuid, .required, .references("star", "id"))
```

Nota che il vincolo [`.references`](schema.it.md#vincolo-di-campo) è opzionale. Vedi [schema](schema.it.md) per ulteriori informazioni.

### Optional Parent

La relazione `@OptionalParent` memorizza un riferimento opzionale alla proprietà `@ID` di un altro modello. Funziona in modo simile a `@Parent` ma consente alla relazione di essere `nil`.

```swift
final class Planet: Model {
    // Esempio di relazione parent opzionale.
    @OptionalParent(key: "star_id")
    var star: Star?
}
```

La definizione del campo è simile a quella di `@Parent` tranne che il vincolo `.required` deve essere omesso.

```swift
.field("star_id", .uuid, .references("star", "id"))
```

### Codifica e Decodifica dei Parent

Una cosa a cui prestare attenzione quando si lavora con le relazioni `@Parent` è il modo in cui le invii e le ricevi. Per esempio, in JSON, un `@Parent` per un modello `Planet` potrebbe apparire così:

```json
{
    "id": "A616B398-A963-4EC7-9D1D-B1AA8A6F1107",
    "star": {
        "id": "A1B2C3D4-1234-5678-90AB-CDEF12345678"
    }
}
```

Nota come la proprietà `star` sia un oggetto piuttosto che l'ID che potresti aspettarti. Quando si invia il modello come corpo HTTP, deve corrispondere a questo per far funzionare la decodifica. Per questo motivo, raccomandiamo fortemente di usare un DTO per rappresentare il modello quando lo si invia sulla rete. Per esempio:

```swift
struct PlanetDTO: Content {
    var id: UUID?
    var name: String
    var star: Star.IDValue
}
```

Poi puoi decodificare il DTO e convertirlo in un modello:

```swift
let planetData = try req.content.decode(PlanetDTO.self)
let planet = Planet(id: planetData.id, name: planetData.name, starID: planetData.star)
try await planet.create(on: req.db)
```

Lo stesso vale quando si restituisce il modello ai client. I tuoi client devono essere in grado di gestire la struttura annidata, oppure devi convertire il modello in un DTO prima di restituirlo. Per ulteriori informazioni sui DTO, vedi la [documentazione del modello](model.it.md#data-transfer-object).

## Optional Child

La proprietà `@OptionalChild` crea una relazione uno-a-uno tra i due modelli. Non memorizza alcun valore sul modello radice.

```swift
final class Planet: Model {
    // Esempio di relazione child opzionale.
    @OptionalChild(for: \.$planet)
    var governor: Governor?
}
```

Il parametro `for` accetta un key path a una relazione `@Parent` o `@OptionalParent` che fa riferimento al modello radice.

Un nuovo modello può essere aggiunto a questa relazione usando il metodo `create`.

```swift
// Esempio di aggiunta di un nuovo modello a una relazione.
let jane = Governor(name: "Jane Doe")
try await mars.$governor.create(jane, on: database)
```

Questo imposterà automaticamente l'id del genitore sul modello figlio.

Poiché questa relazione non memorizza alcun valore, non è necessaria alcuna voce dello schema del database per il modello radice.

La natura uno-a-uno della relazione dovrebbe essere applicata nello schema del modello figlio usando un vincolo `.unique` sulla colonna che fa riferimento al modello genitore.

```swift
try await database.schema(Governor.schema)
    .id()
    .field("name", .string, .required)
    .field("planet_id", .uuid, .required, .references("planets", "id"))
    // Esempio di vincolo unique
    .unique(on: "planet_id")
    .create()
```

!!! warning "Attenzione"
    Omettere il vincolo unique sull'ID del genitore dallo schema del client può portare a risultati imprevedibili.
    Se non c'è un vincolo di unicità, la tabella figlio potrebbe finire per contenere più di una riga figlio per qualsiasi genitore dato; in questo caso, una proprietà `@OptionalChild` potrà comunque accedere a un solo figlio alla volta, senza alcun modo di controllare quale figlio viene caricato. Se potresti dover memorizzare più righe figlio per qualsiasi genitore dato, usa invece `@Children`.

## Children

La proprietà `@Children` crea una relazione uno-a-molti tra due modelli. Non memorizza alcun valore sul modello radice.

```swift
final class Star: Model {
    // Esempio di relazione children.
    @Children(for: \.$star)
    var planets: [Planet]
}
```

Il parametro `for` accetta un key path a una relazione `@Parent` o `@OptionalParent` che fa riferimento al modello radice. In questo caso, facciamo riferimento alla relazione `@Parent` dall'[esempio](#parent) precedente.

Nuovi modelli possono essere aggiunti a questa relazione usando il metodo `create`.

```swift
// Esempio di aggiunta di un nuovo modello a una relazione.
let earth = Planet(name: "Earth")
try await sun.$planets.create(earth, on: database)
```

Questo imposterà automaticamente l'id del genitore sul modello figlio.

Poiché questa relazione non memorizza alcun valore, non è necessaria alcuna voce dello schema del database.

## Siblings

La proprietà `@Siblings` crea una relazione molti-a-molti tra due modelli. Lo fa attraverso un modello terziario chiamato pivot.

Vediamo un esempio di relazione molti-a-molti tra un `Planet` e un `Tag`.

```swift
enum PlanetTagStatus: String, Codable { case accepted, pending }

// Esempio di modello pivot.
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

Qualsiasi modello che include almeno due relazioni `@Parent`, una per ciascun modello da mettere in relazione, può essere usato come pivot. Il modello può contenere proprietà aggiuntive, come il suo ID, e può anche contenere altre relazioni `@Parent`.

Aggiungere un vincolo [unique](schema.it.md#unique) al modello pivot può aiutare a prevenire voci ridondanti. Vedi [schema](schema.it.md) per ulteriori informazioni.

```swift
// Impedisce relazioni duplicate.
.unique(on: "planet_id", "tag_id")
```

Una volta creato il pivot, usa la proprietà `@Siblings` per creare la relazione.

```swift
final class Planet: Model {
    // Esempio di relazione siblings.
    @Siblings(through: PlanetTag.self, from: \.$planet, to: \.$tag)
    public var tags: [Tag]
}
```

La proprietà `@Siblings` richiede tre parametri:

- `through`: Il tipo del modello pivot.
- `from`: Key path dal pivot alla relazione parent che fa riferimento al modello radice.
- `to`: Key path dal pivot alla relazione parent che fa riferimento al modello correlato.

La proprietà `@Siblings` inversa sul modello correlato completa la relazione.

```swift
final class Tag: Model {
    // Esempio di relazione siblings.
    @Siblings(through: PlanetTag.self, from: \.$tag, to: \.$planet)
    public var planets: [Planet]
}
```

### Allegare Siblings

La proprietà `@Siblings` ha metodi per aggiungere e rimuovere modelli dalla relazione.

Usa il metodo `attach()` per aggiungere un singolo modello o un array di modelli alla relazione. I modelli pivot vengono creati e salvati automaticamente secondo necessità. È possibile specificare una closure di callback per popolare le proprietà aggiuntive di ogni pivot creato:

```swift
let earth: Planet = ...
let inhabited: Tag = ...
// Aggiunge il modello alla relazione.
try await earth.$tags.attach(inhabited, on: database)
// Popola gli attributi del pivot quando si stabilisce la relazione.
try await earth.$tags.attach(inhabited, on: database) { pivot in
    pivot.comments = "This is a life-bearing planet."
    pivot.status = .accepted
}
// Aggiunge più modelli con attributi alla relazione.
let volcanic: Tag = ..., oceanic: Tag = ...
try await earth.$tags.attach([volcanic, oceanic], on: database) { pivot in
    pivot.comments = "This planet has a tag named \(pivot.$tag.name)."
    pivot.status = .pending
}
```

Quando si allega un singolo modello, puoi usare il parametro `method` per scegliere se la relazione deve essere verificata prima del salvataggio.

```swift
// Aggiunge il modello alla relazione solo se non esiste già.
try await earth.$tags.attach(inhabited, method: .ifNotExists, on: database)
```

Usa il metodo `detach` per rimuovere un modello dalla relazione. Questo elimina il corrispondente modello pivot.

```swift
// Rimuove il modello dalla relazione.
try await earth.$tags.detach(inhabited, on: database)
```

Puoi verificare se un modello è correlato o meno usando il metodo `isAttached`.

```swift
// Verifica se i modelli sono correlati.
earth.$tags.isAttached(to: inhabited)
```

## Get

Usa il metodo `get(on:)` per recuperare il valore di una relazione.

```swift
// Recupera tutti i pianeti del sole.
sun.$planets.get(on: database).map { planets in
    print(planets)
}

// Oppure

let planets = try await sun.$planets.get(on: database)
print(planets)
```

Usa il parametro `reload` per scegliere se la relazione deve essere recuperata nuovamente dal database se è già stata caricata.

```swift
try await sun.$planets.get(reload: true, on: database)
```

## Query

Usa il metodo `query(on:)` su una relazione per creare un query builder per i modelli correlati.

```swift
// Recupera tutti i pianeti del sole il cui nome inizia con "M".
try await sun.$planets.query(on: database).filter(\.$name =~ "M").all()
```

Vedi [query](query.it.md) per ulteriori informazioni.

## Eager Loading

Il query builder di Fluent ti consente di precaricare le relazioni di un modello quando viene recuperato dal database. Questo si chiama eager loading e ti consente di accedere alle relazioni in modo sincrono senza dover chiamare prima [`get`](#get).

Per eseguire l'eager load di una relazione, passa un key path alla relazione al metodo `with` sul query builder.

```swift
// Esempio di eager loading.
Planet.query(on: database).with(\.$star).all().map { planets in
    for planet in planets {
        // `star` è accessibile in modo sincrono qui
        // poiché è stato precaricato.
        print(planet.star.name)
    }
}

// Oppure

let planets = try await Planet.query(on: database).with(\.$star).all()
for planet in planets {
    // `star` è accessibile in modo sincrono qui
    // poiché è stato precaricato.
    print(planet.star.name)
}
```

Nell'esempio sopra, un key path alla relazione [`@Parent`](#parent) denominata `star` viene passato a `with`. Questo fa sì che il query builder esegua una query aggiuntiva dopo che tutti i pianeti sono stati caricati per recuperare tutte le loro stelle correlate. Le stelle sono poi accessibili in modo sincrono tramite la proprietà `@Parent`.

Ogni relazione caricata in modo eager richiede solo una query aggiuntiva, indipendentemente dal numero di modelli restituiti. L'eager loading è possibile solo con i metodi `all` e `first` del query builder.

### Eager Load Annidato

Il metodo `with` del query builder ti consente di eseguire l'eager load delle relazioni sul modello interrogato. Tuttavia, puoi anche eseguire l'eager load delle relazioni sui modelli correlati.

```swift
let planets = try await Planet.query(on: database).with(\.$star) { star in
    star.with(\.$galaxy)
}.all()
for planet in planets {
    // `star.galaxy` è accessibile in modo sincrono qui
    // poiché è stato precaricato.
    print(planet.star.galaxy.name)
}
```

Il metodo `with` accetta una closure opzionale come secondo parametro. Questa closure accetta un eager load builder per la relazione scelta. Non c'è limite alla profondità a cui l'eager loading può essere annidato.

## Lazy Eager Loading

Nel caso in cui tu abbia già recuperato il modello genitore e vuoi caricare una delle sue relazioni, puoi usare il metodo `get(reload:on:)` per questo scopo. Questo recupererà il modello correlato dal database (o dalla cache, se disponibile) e consente di accedervi come proprietà locale.

```swift
planet.$star.get(on: database).map {
    print(planet.star.name)
}

// Oppure

try await planet.$star.get(on: database)
print(planet.star.name)
```

Nel caso in cui tu voglia assicurarti che i dati ricevuti non vengano estratti dalla cache, usa il parametro `reload:`.

```swift
try await planet.$star.get(reload: true, on: database)
print(planet.star.name)
```

Per verificare se una relazione è stata caricata o meno, usa la proprietà `value`.

```swift
if planet.$star.value != nil {
    // La relazione è stata caricata.
    print(planet.star.name)
} else {
    // La relazione non è stata caricata.
    // Tentare di accedere a planet.star fallirà.
}
```

Se hai già il modello correlato in una variabile, puoi impostare la relazione manualmente usando la proprietà `value` menzionata sopra.

```swift
planet.$star.value = star
```

Questo collegherà il modello correlato al genitore come se fosse stato caricato tramite eager load o lazy load senza una query al database aggiuntiva.
