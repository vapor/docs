# Routing

Il routing è il processo che individua l'handler appropriato per una richiesta in arrivo. Al centro del routing di Vapor c'è un router trie-node ad alte prestazioni proveniente da [RoutingKit](https://github.com/vapor/routing-kit).

## Panoramica

Per capire come funziona il routing in Vapor, bisogna prima comprendere alcune nozioni di base sulle richieste HTTP. Diamo un'occhiata alla seguente richiesta di esempio.

```http
GET /hello/vapor HTTP/1.1
host: vapor.codes
content-length: 0
```

Questa è una semplice richiesta HTTP `GET` all'URL `/hello/vapor`. Questo è il tipo di richiesta HTTP che il tuo browser farebbe se lo puntassi al seguente URL.

```
http://vapor.codes/hello/vapor
```

### Metodo HTTP

La prima parte della richiesta è il metodo HTTP. `GET` è il metodo HTTP più comune, ma ce ne sono diversi che userai spesso. Questi metodi HTTP sono spesso associati alla semantica [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete).

|Metodo|CRUD|
|-|-|
|`GET`|Read|
|`POST`|Create|
|`PUT`|Replace|
|`PATCH`|Update|
|`DELETE`|Delete|

### Path della Richiesta

Subito dopo il metodo HTTP c'è l'URI della richiesta. L'URI consiste in un path che inizia con `/` e una query string opzionale dopo `?`. Il metodo HTTP e il path sono ciò che Vapor usa per instradare le richieste.

Dopo l'URI c'è la versione HTTP seguita da zero o più header e infine un body. Poiché questa è una richiesta `GET`, non ha un body.

### Metodi del Router

Vediamo come questa richiesta potrebbe essere gestita in Vapor.

```swift
app.get("hello", "vapor") { req in
    return "Hello, vapor!"
}
```

Tutti i metodi HTTP comuni sono disponibili come metodi su `Application`. Accettano uno o più argomenti stringa che rappresentano il path della richiesta separato da `/`.

Nota che potresti scrivere questo anche usando `on` seguito dal metodo.

```swift
app.on(.GET, "hello", "vapor") { ... }
```

Con questa route registrata, la richiesta HTTP di esempio di cui sopra risulterà nella seguente risposta HTTP.

```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, vapor!
```

### Parametri di Route

Ora che abbiamo direzionato con successo una richiesta in base al metodo HTTP e al path, proviamo a rendere il path dinamico. Nota che il nome "vapor" è hardcoded sia nel path che nella risposta. Rendiamolo dinamico in modo da poter visitare `/hello/<qualsiasi nome>` e ottenere una risposta.

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

Usando un componente del path con il prefisso `:`, indichiamo al router che questo è un componente dinamico. Qualsiasi stringa fornita qui corrisponderà ora a questa route. Possiamo poi usare `req.parameters` per accedere al valore della stringa.

Se esegui nuovamente la richiesta di esempio, otterrai ancora una risposta che saluta vapor. Tuttavia, ora puoi includere qualsiasi nome dopo `/hello/` e vederlo incluso nella risposta. Proviamo `/hello/swift`.

```http
GET /hello/swift HTTP/1.1
content-length: 0
```
```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, swift!
```

Ora che hai capito le basi, dai un'occhiata a ciascuna sezione per saperne di più su parametri, gruppi e altro.

## Route

Una route specifica un request handler per un dato metodo HTTP e un path URI. Può anche memorizzare metadati aggiuntivi.

### Metodi

Le route possono essere registrate direttamente sulla tua `Application` usando vari helper per i metodi HTTP.

```swift
// risponde a GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
	...
}
```

Gli handler delle route supportano la restituzione di qualsiasi cosa che sia `ResponseEncodable`. Questo include `Content`, una closure `async` e qualsiasi `EventLoopFuture` dove il valore future è `ResponseEncodable`.

Puoi specificare il tipo di ritorno di una route usando `-> T` prima di `in`. Questo può essere utile in situazioni dove il compilatore non riesce a determinare il tipo di ritorno.

```swift
app.get("foo") { req -> String in
	return "bar"
}
```

Questi sono i metodi helper di route supportati:

- `get`
- `post`
- `patch`
- `put`
- `delete`

Oltre agli helper per i metodi HTTP, c'è una funzione `on` che accetta il metodo HTTP come parametro di input.

```swift
// risponde a OPTIONS /foo/bar/baz
app.on(.OPTIONS, "foo", "bar", "baz") { req in
	...
}
```

### Componente del Path

Ogni metodo di registrazione delle route accetta una lista variadica di `PathComponent`. Questo tipo è esprimibile tramite string literal e ha quattro casi:

- Costante (`foo`)
- Parametro (`:foo`)
- Qualsiasi (`*`)
- Catchall (`**`)

#### Costante

Questo è un componente di route statico. Solo le richieste con una stringa esattamente corrispondente in questa posizione saranno permesse.

```swift
// risponde a GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
	...
}
```

#### Parametro

Questo è un componente di route dinamico. Qualsiasi stringa in questa posizione sarà accettata. Un componente del path parametrico è specificato con il prefisso `:`. La stringa che segue `:` verrà usata come nome del parametro. Puoi usare il nome per recuperare successivamente il valore del parametro dalla richiesta.

```swift
// risponde a GET /foo/bar/baz
// risponde a GET /foo/qux/baz
// ...
app.get("foo", ":bar", "baz") { req in
	...
}
```

#### Qualsiasi

Questo è molto simile al parametro tranne che il valore viene scartato. Questo componente del path è specificato semplicemente come `*`.

```swift
// risponde a GET /foo/bar/baz
// risponde a GET /foo/qux/baz
// ...
app.get("foo", "*", "baz") { req in
	...
}
```

#### Catchall

Questo è un componente di route dinamico che corrisponde a uno o più componenti. È specificato usando semplicemente `**`. Qualsiasi stringa in questa posizione o nelle posizioni successive verrà abbinata nella richiesta.

```swift
// risponde a GET /foo/bar
// risponde a GET /foo/bar/baz
// ...
app.get("foo", "**") { req in
    ...
}
```

### Parametri

Quando si usa un componente del path parametro (con prefisso `:`), il valore dell'URI in quella posizione verrà memorizzato in `req.parameters`. Puoi usare il nome del componente del path per accedere al valore.

```swift
// risponde a GET /hello/foo
// risponde a GET /hello/bar
// ...
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

!!! tip "Suggerimento"
    Possiamo essere certi che `req.parameters.get` non restituirà mai `nil` qui poiché il path della nostra route include `:name`. Tuttavia, se stai accedendo ai parametri di route in un middleware o in codice attivato da più route, vorrai gestire la possibilità di `nil`.

!!! tip "Suggerimento"
    Se vuoi recuperare i parametri della query URL, ad esempio `/hello/?name=foo`, devi usare le Content API di Vapor per gestire i dati codificati in URL nella query string dell'URL. Consulta il [riferimento `Content`](content.it.md) per maggiori dettagli.

`req.parameters.get` supporta anche il casting del parametro a tipi `LosslessStringConvertible` automaticamente.

```swift
// risponde a GET /number/42
// risponde a GET /number/1337
// ...
app.get("number", ":x") { req -> String in
	guard let int = req.parameters.get("x", as: Int.self) else {
		throw Abort(.badRequest)
	}
	return "\(int) is a great number"
}
```

I valori dell'URI abbinati da Catchall (`**`) verranno memorizzati in `req.parameters` come `[String]`. Puoi usare `req.parameters.getCatchall` per accedere a questi componenti.

```swift
// risponde a GET /hello/foo
// risponde a GET /hello/foo/bar
// ...
app.get("hello", "**") { req -> String in
    let name = req.parameters.getCatchall().joined(separator: " ")
    return "Hello, \(name)!"
}
```

### Body Streaming

Quando si registra una route usando il metodo `on`, puoi specificare come il body della richiesta deve essere gestito. Il comportamento di default è che i body delle richieste vengono raccolti in memoria prima di chiamare il tuo handler. Questo è utile poiché permette alla decodifica del contenuto della richiesta di essere sincrona anche se la tua applicazione legge le richieste in arrivo in modo asincrono.

Per impostazione predefinita, Vapor limiterà la raccolta del body in streaming a 16KB di dimensione. Puoi configurarlo usando `app.routes`.

```swift
// Aumenta il limite di raccolta del body in streaming a 500kb
app.routes.defaultMaxBodySize = "500kb"
```

Se un body in streaming che viene raccolto supera il limite configurato, verrà lanciato un errore `413 Payload Too Large`.

Per configurare la strategia di raccolta del body della richiesta per una singola route, usa il parametro `body`.

```swift
// Raccoglie i body in streaming (fino a 1mb di dimensione) prima di chiamare questa route.
app.on(.POST, "listings", body: .collect(maxSize: "1mb")) { req in
    // Gestisce la richiesta.
}
```

Se un `maxSize` viene passato a `collect`, sovrascriverà il valore predefinito dell'applicazione per quella route. Per usare il valore predefinito dell'applicazione, ometti l'argomento `maxSize`.

Per richieste di grandi dimensioni, come gli upload di file, raccogliere il body della richiesta in un buffer può potenzialmente mettere sotto pressione la memoria del sistema. Per evitare che il body della richiesta venga raccolto, usa la strategia `stream`.

```swift
// Il body della richiesta non verrà raccolto in un buffer.
app.on(.POST, "upload", body: .stream) { req in
    ...
}
```

Quando il body della richiesta è in streaming, `req.body.data` sarà `nil`. Devi usare `req.body.drain` per gestire ogni chunk man mano che viene inviato alla tua route.

### Routing Case-Insensitive

Il comportamento predefinito per il routing è sia case-sensitive che case-preserving. I componenti del path `Constant` possono in alternativa essere gestiti in modo case-insensitive e case-preserving ai fini del routing; per abilitare questo comportamento, configura prima dell'avvio dell'applicazione:

```swift
app.routes.caseInsensitive = true
```

Non vengono apportate modifiche alla richiesta originante; gli handler delle route riceveranno i componenti del path della richiesta senza modifiche.

### Visualizzare le Route

Puoi accedere alle route della tua applicazione accedendo al servizio `Routes` o usando `app.routes`.

```swift
print(app.routes.all) // [Route]
```

Vapor viene anche fornito con un comando `routes` che stampa tutte le route disponibili in una tabella formattata ASCII.

```sh
$ swift run App routes
+--------+----------------+
| GET    | /              |
+--------+----------------+
| GET    | /hello         |
+--------+----------------+
| GET    | /todos         |
+--------+----------------+
| POST   | /todos         |
+--------+----------------+
| DELETE | /todos/:todoID |
+--------+----------------+
```

### Metadati

Tutti i metodi di registrazione delle route restituiscono la `Route` creata. Questo ti permette di aggiungere metadati al dizionario `userInfo` della route. Ci sono alcuni metodi predefiniti disponibili, come l'aggiunta di una descrizione.

```swift
app.get("hello", ":name") { req in
	...
}.description("says hello")
```

## Gruppi di Route

Il raggruppamento delle route ti permette di creare un insieme di route con un prefisso del path o middleware specifici. Il raggruppamento supporta sia la sintassi builder che quella basata su closure.

Tutti i metodi di raggruppamento restituiscono un `RouteBuilder`, il che significa che puoi combinare, abbinare e annidare infinitamente i tuoi gruppi con altri metodi di costruzione delle route.

### Prefisso del Path

I gruppi di route con prefisso del path ti permettono di anteporre uno o più componenti del path a un gruppo di route.

```swift
let users = app.grouped("users")
// GET /users
users.get { req in
    ...
}
// POST /users
users.post { req in
    ...
}
// GET /users/:id
users.get(":id") { req in
    let id = req.parameters.get("id")!
    ...
}
```

Qualsiasi componente del path che puoi passare in metodi come `get` o `post` può essere passato in `grouped`. Esiste anche una sintassi alternativa basata su closure.

```swift
app.group("users") { users in
    // GET /users
    users.get { req in
        ...
    }
    // POST /users
    users.post { req in
        ...
    }
    // GET /users/:id
    users.get(":id") { req in
        let id = req.parameters.get("id")!
        ...
    }
}
```

L'annidamento di gruppi di route con prefisso del path ti permette di definire concisamente API CRUD.

```swift
app.group("users") { users in
    // GET /users
    users.get { ... }
    // POST /users
    users.post { ... }

    users.group(":id") { user in
        // GET /users/:id
        user.get { ... }
        // PATCH /users/:id
        user.patch { ... }
        // PUT /users/:id
        user.put { ... }
    }
}
```

### Middleware

Oltre ad aggiungere prefissi ai componenti del path, puoi anche aggiungere middleware ai gruppi di route.

```swift
app.get("fast-thing") { req in
    ...
}
app.group(RateLimitMiddleware(requestsPerMinute: 5)) { rateLimited in
    rateLimited.get("slow-thing") { req in
        ...
    }
}
```

Questo è particolarmente utile per proteggere sottoinsiemi delle tue route con diversi middleware di autenticazione.

```swift
app.post("login") { ... }
let auth = app.grouped(AuthMiddleware())
auth.get("dashboard") { ... }
auth.get("logout") { ... }
```

## Redirect

I redirect sono utili in diversi scenari, come il reindirizzamento di vecchie posizioni verso nuove per la SEO, il reindirizzamento di un utente non autenticato alla pagina di login o il mantenimento della compatibilità con le versioni precedenti della tua API.

Per reindirizzare una richiesta, usa:

```swift
req.redirect(to: "/some/new/path")
```

Puoi anche specificare il tipo di redirect, per esempio per reindirizzare una pagina in modo permanente (in modo che la tua SEO venga aggiornata correttamente) usa:

```swift
req.redirect(to: "/some/new/path", redirectType: .permanent)
```

I diversi tipi di `Redirect` sono:

* `.permanent` - restituisce un redirect **301 Permanent**
* `.normal` - restituisce un redirect **303 see other**. Questo è il valore predefinito di Vapor e dice al client di seguire il redirect con una richiesta **GET**.
* `.temporary` - restituisce un redirect **307 Temporary**. Questo dice al client di preservare il metodo HTTP usato nella richiesta.

> Per scegliere il codice di stato di reindirizzamento appropriato consulta [l'elenco completo](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes#3xx_redirection)
