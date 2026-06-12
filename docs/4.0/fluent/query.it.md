# Query

L'API di query di Fluent ti consente di creare, leggere, aggiornare ed eliminare modelli dal database. Supporta il filtraggio dei risultati, i join, il chunking, gli aggregati e molto altro.

```swift
// Un esempio di query Fluent.
let planets = try await Planet.query(on: database)
    .filter(\.$type == .gasGiant)
    .sort(\.$name)
    .with(\.$star)
    .all()
```

I query builder sono legati a un singolo tipo di modello e possono essere creati usando il metodo statico [`query`](model.it.md#query). Possono anche essere creati passando il tipo di modello al metodo `query` su un oggetto database.

```swift
// Crea anche un query builder.
database.query(Planet.self)
```

!!! note "Nota"
    Devi `import Fluent` nel file con le tue query affinché il compilatore possa vedere le funzioni helper di Fluent.

## All

Il metodo `all()` restituisce un array di modelli.

```swift
// Recupera tutti i pianeti.
let planets = try await Planet.query(on: database).all()
```

Il metodo `all` supporta anche il recupero di un solo campo dal set di risultati.

```swift
// Recupera tutti i nomi dei pianeti.
let names = try await Planet.query(on: database).all(\.$name)
```

### First

Il metodo `first()` restituisce un singolo modello opzionale. Se la query restituisce più di un modello, viene restituito solo il primo. Se la query non ha risultati, viene restituito `nil`.

```swift
// Recupera il primo pianeta chiamato Terra.
let earth = try await Planet.query(on: database)
    .filter(\.$name == "Earth")
    .first()
```

!!! tip "Suggerimento"
    Se si usano `EventLoopFuture`, questo metodo può essere combinato con [`unwrap(or:)`](../basics/errors.it.md#abort) per restituire un modello non opzionale o lanciare un errore.

## Filter

Il metodo `filter` ti consente di vincolare i modelli inclusi nel set di risultati. Ci sono diversi overload per questo metodo.

### Filtro per Valore

Il metodo `filter` più comunemente usato accetta un'espressione con operatore e un valore.

```swift
// Tutti i pianeti di tipo gas gigante.
Planet.query(on: database).filter(\.$type == .gasGiant)
```

Queste espressioni con operatore accettano un key path del campo sul lato sinistro e un valore sul lato destro. Il valore fornito deve corrispondere al tipo di valore atteso del campo ed è legato alla query risultante. Le espressioni di filtro sono fortemente tipizzate consentendo l'uso della sintassi con punto iniziale.

Di seguito è riportato un elenco di tutti gli operatori di valore supportati.

|Operatore|Descrizione|
|-|-|
|`==`|Uguale a.|
|`!=`|Diverso da.|
|`>=`|Maggiore o uguale a.|
|`>`|Maggiore di.|
|`<`|Minore di.|
|`<=`|Minore o uguale a.|

### Filtro per Campo

Il metodo `filter` supporta il confronto tra due campi.

```swift
// Tutti gli utenti il cui nome è uguale al cognome.
User.query(on: database)
    .filter(\.$firstName == \.$lastName)
```

I filtri per campo supportano gli stessi operatori dei [filtri per valore](#filtro-per-valore).

### Filtro per Sottoinsieme

Il metodo `filter` supporta il controllo se il valore di un campo esiste in un dato insieme di valori.

```swift
// Tutti i pianeti il cui tipo è gas gigante o piccolo roccioso.
Planet.query(on: database)
    .filter(\.$type ~~ [.gasGiant, .smallRocky])
```

L'insieme di valori fornito può essere qualsiasi `Collection` Swift il cui tipo `Element` corrisponde al tipo di valore del campo.

Di seguito è riportato un elenco di tutti gli operatori di sottoinsieme supportati.

|Operatore|Descrizione|
|-|-|
|`~~`|Valore nel set.|
|`!~`|Valore non nel set.|

### Filtro per Contenuto

Il metodo `filter` supporta il controllo se il valore di un campo stringa contiene una data sottostringa.

```swift
// Tutti i pianeti il cui nome inizia con la lettera M.
Planet.query(on: database)
    .filter(\.$name =~ "M")
```

Questi operatori sono disponibili solo sui campi con valori stringa.

Di seguito è riportato un elenco di tutti gli operatori di contenuto supportati.

|Operatore|Descrizione|
|-|-|
|`~~`|Contiene la sottostringa.|
|`!~`|Non contiene la sottostringa.|
|`=~`|Corrisponde al prefisso.|
|`!=~`|Non corrisponde al prefisso.|
|`~=`|Corrisponde al suffisso.|
|`!~=`|Non corrisponde al suffisso.|

### Gruppo

Per impostazione predefinita, tutti i filtri aggiunti a una query dovranno corrispondere. Il query builder supporta la creazione di un gruppo di filtri in cui solo un filtro deve corrispondere.

```swift
// Tutti i pianeti il cui nome è Terra o Marte.
Planet.query(on: database).group(.or) { group in
    group.filter(\.$name == "Earth").filter(\.$name == "Mars")
}.all()
```

Il metodo `group` supporta la combinazione di filtri con logica `and` o `or`. Questi gruppi possono essere annidati indefinitamente. I filtri di livello superiore possono essere considerati come se fossero in un gruppo `and`.

## Aggregate

Il query builder supporta diversi metodi per eseguire calcoli su un insieme di valori come il conteggio o la media.

```swift
// Numero di pianeti nel database.
Planet.query(on: database).count()
```

Tutti i metodi aggregati tranne `count` richiedono che venga passato un key path a un campo.

```swift
// Nome più basso ordinato alfabeticamente.
Planet.query(on: database).min(\.$name)
```

Di seguito è riportato un elenco di tutti i metodi aggregati disponibili.

|Aggregato|Descrizione|
|-|-|
|`count`|Numero di risultati.|
|`sum`|Somma dei valori dei risultati.|
|`average`|Media dei valori dei risultati.|
|`min`|Valore minimo dei risultati.|
|`max`|Valore massimo dei risultati.|

Tutti i metodi aggregati tranne `count` restituiscono il tipo di valore del campo come risultato. `count` restituisce sempre un intero.

## Chunk

Il query builder supporta la restituzione di un set di risultati come chunk separati. Questo ti aiuta a controllare l'utilizzo della memoria durante la gestione di letture di database di grandi dimensioni.

```swift
// Recupera tutti i pianeti in chunk di massimo 64 alla volta.
Planet.query(on: self.database).chunk(max: 64) { planets in
    // Gestisci il chunk di pianeti.
}
```

La closure fornita verrà chiamata zero o più volte a seconda del numero totale di risultati. Ogni elemento restituito è un `Result` contenente il modello o un errore restituito nel tentativo di decodificare la voce del database.

## Campo

Per impostazione predefinita, tutti i campi di un modello verranno letti dal database da una query. Puoi scegliere di selezionare solo un sottoinsieme dei campi di un modello usando il metodo `field`.

```swift
// Seleziona solo i campi id e name del pianeta
Planet.query(on: database)
    .field(\.$id).field(\.$name)
    .all()
```

Tutti i campi del modello non selezionati durante una query saranno in uno stato non inizializzato. Il tentativo di accedere direttamente ai campi non inizializzati provocherà un errore fatale. Per verificare se il valore di un campo del modello è impostato, usa la proprietà `value`.

```swift
if let name = planet.$name.value {
    // Il nome è stato recuperato.
} else {
    // Il nome non è stato recuperato.
    // L'accesso a `planet.name` fallirà.
}
```

## Unique

Il metodo `unique` del query builder fa sì che vengano restituiti solo risultati distinti (senza duplicati).

```swift
// Restituisce tutti i nomi unici degli utenti.
User.query(on: database).unique().all(\.$firstName)
```

`unique` è particolarmente utile quando si recupera un singolo campo con `all`. Tuttavia, puoi anche selezionare più campi usando il metodo [`field`](#campo). Poiché gli identificatori dei modelli sono sempre univoci, dovresti evitare di selezionarli quando usi `unique`.

## Range

I metodi `range` del query builder ti consentono di scegliere un sottoinsieme dei risultati usando i range di Swift.

```swift
// Recupera i primi 5 pianeti.
Planet.query(on: self.database)
    .range(..<5)
```

I valori del range sono interi senza segno che iniziano da zero. Per saperne di più sui [range di Swift](https://developer.apple.com/documentation/swift/range).

```swift
// Salta i primi 2 risultati.
.range(2...)
```

## Join

Il metodo `join` del query builder ti consente di includere i campi di un altro modello nel tuo set di risultati. È possibile unire più di un modello alla tua query.

```swift
// Recupera tutti i pianeti con una stella chiamata Sole.
Planet.query(on: database)
    .join(Star.self, on: \Planet.$star.$id == \Star.$id)
    .filter(Star.self, \.$name == "Sun")
    .all()
```

Il parametro `on` accetta un'espressione di uguaglianza tra due campi. Uno dei campi deve già esistere nel set di risultati corrente. L'altro campo deve esistere sul modello che viene unito. Questi campi devono avere lo stesso tipo di valore.

La maggior parte dei metodi del query builder, come `filter` e `sort`, supportano i modelli uniti. Se un metodo supporta i modelli uniti, accetterà il tipo di modello unito come primo parametro.

```swift
// Ordina per il campo unito "name" sul modello Star.
.sort(Star.self, \.$name)
```

Le query che usano i join restituiranno comunque un array del modello base. Per accedere al modello unito, usa il metodo `joined`.

```swift
// Accedi al modello unito.
let planet: Planet = ...
let star = try planet.joined(Star.self)
```

### Alias di Modello

Gli alias di modello ti consentono di unire lo stesso modello a una query più volte. Per dichiarare un alias di modello, crea uno o più tipi che si conformano a `ModelAlias`.

```swift
// Esempio di alias di modello.
final class HomeTeam: ModelAlias {
    static let name = "home_teams"
    let model = Team()
}
final class AwayTeam: ModelAlias {
    static let name = "away_teams"
    let model = Team()
}
```

Questi tipi fanno riferimento al modello a cui si fa l'alias tramite la proprietà `model`. Una volta creati, puoi usare gli alias di modello come i modelli normali in un query builder.

```swift
// Recupera tutte le partite in cui il nome della squadra di casa è Vapor
// e ordina per il nome della squadra ospite.
let matches = try await Match.query(on: self.database)
    .join(HomeTeam.self, on: \Match.$homeTeam.$id == \HomeTeam.$id)
    .join(AwayTeam.self, on: \Match.$awayTeam.$id == \AwayTeam.$id)
    .filter(HomeTeam.self, \.$name == "Vapor")
    .sort(AwayTeam.self, \.$name)
    .all()
```

Tutti i campi del modello sono accessibili tramite il tipo alias del modello via `@dynamicMemberLookup`.

```swift
// Accedi al modello unito.
let home = try match.joined(HomeTeam.self)
print(home.name)
```

## Update

Il query builder supporta l'aggiornamento di più di un modello alla volta usando il metodo `update`.

```swift
// Aggiorna tutti i pianeti chiamati "Plutone"
Planet.query(on: database)
    .set(\.$type, to: .dwarf)
    .filter(\.$name == "Pluto")
    .update()
```

`update` supporta i metodi `set`, `filter` e `range`.

## Delete

Il query builder supporta l'eliminazione di più di un modello alla volta usando il metodo `delete`.

```swift
// Elimina tutti i pianeti chiamati "Vulcan"
Planet.query(on: database)
    .filter(\.$name == "Vulcan")
    .delete()
```

`delete` supporta il metodo `filter`.

## Paginate

L'API di query di Fluent supporta la paginazione automatica dei risultati usando il metodo `paginate`.

```swift
// Esempio di paginazione basata sulla richiesta.
app.get("planets") { req in
    try await Planet.query(on: req.db).paginate(for: req)
}
```

Il metodo `paginate(for:)` userà i parametri `page` e `per` disponibili nell'URI della richiesta per restituire il set di risultati desiderato. I metadati sulla pagina corrente e il numero totale di risultati sono inclusi nella chiave `metadata`.

```http
GET /planets?page=2&per=5 HTTP/1.1
```

La richiesta sopra produrrebbe una risposta strutturata come segue.

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

I numeri di pagina iniziano da `1`. Puoi anche fare una richiesta di pagina manuale.

```swift
// Esempio di paginazione manuale.
.paginate(PageRequest(page: 1, per: 2))
```

## Sort

I risultati della query possono essere ordinati per valori di campo usando il metodo `sort`.

```swift
// Recupera i pianeti ordinati per nome.
Planet.query(on: database).sort(\.$name)
```

È possibile aggiungere ordinamenti aggiuntivi come fallback in caso di parità. I fallback verranno usati nell'ordine in cui sono stati aggiunti al query builder.

```swift
// Recupera gli utenti ordinati per nome. Se due utenti hanno lo stesso nome, ordina per età.
User.query(on: database).sort(\.$name).sort(\.$age)
```
