# Autenticazione

L'autenticazione è la verifica dell'identità di un utente. Ciò può avvenire attraverso la verifica di credenziali come un nome utente e una password o un tramite un token. L'autenticazione (talvolta chiamata auth/c) si distingue dall'autorizzazione (auth/z), che è l'atto di verificare i permessi di un utente precedentemente autenticato per permettergli di eseguire determinate operazioni.

## Introduzione

Le API di autenticazione di Vapor supportano l'autenticazione di un utente tramite l'intestazione `Authorization` della richiesta, utilizzando le autorizzazioni [Basic](https://tools.ietf.org/html/rfc7617) e [Bearer](https://tools.ietf.org/html/rfc6750). È supportata anche l'autenticazione di un utente tramite la decodifica dei dati dall'API [Content](../basics/content.md).

L'autenticazione viene implementata creando un `Authenticator` che contiene la logica di verifica. Un autenticatore può essere utilizzato per proteggere singoli gruppi di route o un'intera applicazione. Vapor fornisce i seguenti autenticatori:

|Protocollo|Descrizione|
|-|-|
|`RequestAuthenticator`/`AsyncRequestAuthenticator`|Autenticatore di base in grado di creare middleware.|
|[`BasicAuthenticator`/`AsyncBasicAuthenticator`](#basic)|Autenticatore che verifica l'header Basic.|
|[`BearerAuthenticator`/`AsyncBearerAuthenticator`](#bearer)|Autenticatore che verifica l'header Bearer.|
|[`CredentialsAuthenticator`/`AsyncCredentialsAuthenticator`](#credentials)|Autenticatore che verifica le credenziali decodificate dal contenuto della richiesta.|

Se l'autenticazione ha successo, l'autenticatore aggiunge l'utente verificato a `req.auth`. Si può quindi accedere a questo utente usando `req.auth.get(_:)` nelle route protette dall'autenticatore. Se l'autenticazione fallisce, l'utente non viene aggiunto a `req.auth` e qualsiasi tentativo di accesso fallirà.

## Authenticatable

Per utilizzare l'API di autenticazione, ti occorre innanzitutto un tipo di utente conforme ad `Authenticatable`. Questo può essere una `struct`, una `class` o anche un `Model` Fluent. Gli esempi seguenti assumono una semplice struttura `User` che ha una sola proprietà: `name`.

```swift
import Vapor

struct User: Authenticatable {
    var name: String
}
```


Ogni esempio che segue utilizzerà un'istanza di un autenticatore che abbiamo creato. In questi esempi, lo abbiamo chiamato `UserAuthenticator`.

### Route

Gli autenticatori sono middleware e possono essere utilizzati per proteggere le route.

```swift
let protected = app.grouped(UserAuthenticator())
protected.get("me") { req -> String in
    try req.auth.require(User.self).name
}
```

Per recuperare l'utente autenticato, viene usato il metodo `req.auth.require`. Se l'autenticazione fallisce, questo metodo lancia un errore, proteggendo la route.

### Middleware di Guardia

Puoi anche usare `GuardMiddleware` nel gruppo di route, per assicurarsi che un utente sia stato autenticato prima di raggiungere il gestore di route.

```swift
let protected = app.grouped(UserAuthenticator())
    .grouped(User.guardMiddleware())
```

La richiesta di autenticazione non viene effettuata dal middleware dell'autenticatore per consentire la composizione degli autenticatori. Per saperne di più sulla [composizione](#composition) leggi più sotto.

## Basic

L'autenticazione di base invia un nome utente e una password nell'intestazione `Authorization`. Il nome utente e la password sono concatenati con i due punti (ad esempio, `test:secret`), codificati in base 64 e preceduti da `"Basic"`. La seguente richiesta di esempio codifica il nome utente `test` con la password `secret`.

```http
GET /me HTTP/1.1
Authorization: Basic dGVzdDpzZWNyZXQ=
``` 

In genere, l'autenticazione di base viene utilizzata una sola volta per registrare un utente e generare un token. Questo riduce al minimo la frequenza di invio della password sensibile dell'utente. Non si dovrebbe mai inviare l'autorizzazione di base in chiaro o su una connessione TLS non verificata.

Per implementare l'autenticazione di base nella tua applicazione, puoi creare un nuovo autenticatore conforme a `BasicAuthenticator`. Di seguito è riportato un esempio di autenticatore codificato per verificare la richiesta di cui sopra.

```swift
import Vapor

struct UserAuthenticator: BasicAuthenticator {
    typealias User = App.User

    func authenticate(
        basic: BasicAuthorization,
        for request: Request
    ) -> EventLoopFuture<Void> {
        if basic.username == "test" && basic.password == "secret" {
            request.auth.login(User(name: "Vapor"))
        }
        return request.eventLoop.makeSucceededFuture(())
   }
}
```

Se stai usando `async`/`await`, puoi usare `AsyncBasicAuthenticator`:

```swift
import Vapor

struct UserAuthenticator: AsyncBasicAuthenticator {
    typealias User = App.User

    func authenticate(
        basic: BasicAuthorization,
        for request: Request
    ) async throws {
        if basic.username == "test" && basic.password == "secret" {
            request.auth.login(User(name: "Vapor"))
        }
   }
}
```

Questo protocollo richiede che implementi il metodo `authenticate(basic:for:)`, che sarà richiamato quando una richiesta in arrivo contiene l'intestazione `Authorization: Basic ...`. Al metodo viene passata una struct `BasicAuthorization` contenente il nome utente e la password.

In questo autenticatore di prova, il nome utente e la password vengono verificati rispetto ai valori codificati. In un autenticatore reale, potresti voler effettuare un controllo su un database o su un'API esterna, per questo motivo il metodo `authenticate` consente di restituire una future.

!!! tip
    Le password non devono mai essere memorizzate in un database in chiaro. Utilizzate sempre gli hash delle password per il confronto.

Se i parametri di autenticazione sono corretti, in questo caso corrispondono ai valori codificati, viene effettuato l'accesso a uno `User` di nome Vapor. Se i parametri di autenticazione non corrispondono, non viene registrato alcun utente, il che significa che l'autenticazione è fallita. 

Se aggiungi questo autenticatore alla tua applicazione e testi la route definita sopra, dovresti vedere il nome `"Vapor"` restituito per un login riuscito. Se le credenziali non sono corrette, dovresti vedere un errore `401 Unauthorized`.

## Bearer

L'autenticazione Bearer invia un token nell'intestazione `Authorization`. Il token è preceduto dalla stringa `"Bearer"`. La seguente richiesta di esempio invia un token di accesso `secret`.

```http
GET /me HTTP/1.1
Authorization: Bearer foo
``` 

L'autenticazione Bearer è comunemente usata per l'autenticazione degli endpoint API. L'utente in genere richiede un token Bearer inviando credenziali come nome utente e password a un endpoint di login. Questo token può durare minuti o giorni, a seconda delle esigenze dell'applicazione.

Finché il token è valido, l'utente può usarlo al posto delle proprie credenziali per autenticarsi con l'API. Se il token non è valido, è possibile generarne uno nuovo utilizzando l'endpoint di login.

Per implementare l'autenticazione Bearer nella tua applicazione, puoi creare un nuovo autenticatore conforme a `BearerAuthenticator`. Di seguito è riportato un esempio di autenticatore codificato per verificare la richiesta di cui sopra.

```swift
import Vapor

struct UserAuthenticator: BearerAuthenticator {
    typealias User = App.User

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) -> EventLoopFuture<Void> {
       if bearer.token == "foo" {
           request.auth.login(User(name: "Vapor"))
       }
       return request.eventLoop.makeSucceededFuture(())
   }
}
```

Se stai usando `async`/`await`, puoi usare `AsyncBearerAuthenticator`:

```swift
import Vapor

struct UserAuthenticator: AsyncBearerAuthenticator {
    typealias User = App.User

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) async throws {
       if bearer.token == "foo" {
           request.auth.login(User(name: "Vapor"))
       }
   }
}
```

Questo protocollo richiede l'implementazione di `authenticate(bearer:for:)` che verrà richiamata quando una richiesta in arrivo contiene l'intestazione `Authorization: Bearer ...`. Al metodo viene passata una struct `BearerAuthorization` contenente il token.

In questo autenticatore di prova, il token viene testato rispetto a un valore codificato. In un vero autenticatore, potresti voler verificare il token confrontandolo con un database o usando misure crittografiche, come si fa con JWT. Ecco perché il metodo `authenticate` consente di restituire una future.

!!! tip
    Quando si implementa la verifica dei token, è importante considerare la scalabilità orizzontale. Se l'applicazione deve gestire molti utenti contemporaneamente, l'autenticazione può essere un potenziale collo di bottiglia. Considera il modo in cui il tuo progetto scalerà su più istanze dell'applicazione in esecuzione contemporaneamente.

Se i parametri di autenticazione sono corretti, e in questo caso corrispondono al valore codificato, viene effettuato l'accesso a un `Utente` di nome Vapor. Se i parametri di autenticazione non corrispondono, non viene registrato alcun utente, il che significa che l'autenticazione è fallita. 

Se aggiungi questo autenticatore alla tua applicazione e testi la route definita sopra, dovresti vedere il nome `"Vapor"` restituito per un login riuscito. Se le credenziali non sono corrette, dovresti vedere un errore `401 Unauthorized`.

## Composizione

Puoi comporre (combinare insieme) più autenticatori per creare un'autenticazione dell'endpoint più complessa. Poiché un middleware autenticatore non rifiuta la richiesta se l'autenticazione fallisce, puoi concatenare più di un middleware. Puoi concatenare più autenticatori in due modi diversi.

### Composizione dei Metodi

Il primo metodo di composizione dell'autenticazione consiste nel concatenare più autenticatori per lo stesso tipo di utente. Prendi l'esempio seguente:

```swift
app.grouped(UserPasswordAuthenticator())
    .grouped(UserTokenAuthenticator())
    .grouped(User.guardMiddleware())
    .post("login") 
{ req in
    let user = try req.auth.require(User.self)
    // Fai qualcosa con l'utente.
}
```

Questo esempio presuppone due autenticatori `UserPasswordAuthenticator` e `UserTokenAuthenticator` che autenticano entrambi `User`. Entrambi gli autenticatori sono aggiunti al gruppo di route. Infine, `GuardMiddleware` viene aggiunto dopo gli autenticatori per richiedere che `User` sia stato autenticato con successo. 

Questa composizione di autenticatori dà come risultato una route a cui si può accedere sia tramite password che tramite token. Una route di questo tipo potrebbe consentire a un utente di effettuare il login e generare un token, per poi continuare a usare quel token per generare nuovi token.

### Composizione di Utenti

Il secondo metodo di composizione dell'autenticazione consiste nel concatenare gli autenticatori per diversi tipi di utenti. Prendiamo il seguente esempio:

```swift
app.grouped(AdminAuthenticator())
    .grouped(UserAuthenticator())
    .get("secure") 
{ req in
    guard req.auth.has(Admin.self) || req.auth.has(User.self) else {
        throw Abort(.unauthorized)
    }
    // Fai qualcosa.
}
```

Questo esempio presuppone due autenticatori `AdminAuthenticator` e `UserAuthenticator` che autenticano rispettivamente `Admin` e `User`. Entrambi gli autenticatori sono aggiunti al gruppo di route. Invece di usare `GuardMiddleware`, viene aggiunto un controllo nel gestore di route per vedere se `Admin` o `User` sono stati autenticati. In caso contrario, viene lanciato un errore.

Questa composizione di autenticatori dà luogo a un percorso a cui possono accedere due tipi diversi di utenti con metodi di autenticazione potenzialmente diversi. Un percorso di questo tipo potrebbe consentire l'autenticazione di un utente normale, pur consentendo l'accesso a un super-utente.

## Manualmente

Puoi anche gestire l'autenticazione manualmente, utilizzando `req.auth`. Questo è particolarmente utile per i test.

Per accedere manualmente a un utente, puoi utilizzare `req.auth.login(_:)`. A questo metodo può essere passato qualsiasi utente `Authenticatable`.

```swift
req.auth.login(User(name: "Vapor"))
```

Per ottenere l'utente autenticato puoi usare `req.auth.require(_:)`:

```swift
let user: User = try req.auth.require(User.self)
print(user.name) // String
```

Puoi anche usare `req.auth.get(_:)` se non vuoi lanciare automaticamente un errore quando l'autenticazione fallisce.

```swift
let user = req.auth.get(User.self)
print(user?.name) // String?
```

Per effettuare il logout di un utente, puoi usare `req.auth.logout(_:)`:

```swift
req.auth.logout(User.self)
```

## Fluent

[Fluent](../fluent/overview.md) definisce due protocolli `ModelAuthenticatable` e `ModelTokenAuthenticatable` che possono essere aggiunti ai modelli esistenti. Conformare i modelli a questi protocolli consente di creare autenticatori per proteggere gli endpoint.

`ModelTokenAuthenticatable` si autentica con un token Bearer. È quello che puoi usare per proteggere la maggior parte degli endpoint. `ModelAuthenticatable` si autentica con nome utente e password ed è usato da un singolo endpoint per generare token.

Questa guida presuppone che tu abbia già familiarità con Fluent e che abbia configurato con successo la tua applicazione per utilizzare un database. Se non conosci Fluent, inizia dalla [panoramica](../fluent/overview.md).

### User

Per iniziare, è necessario un modello che rappresenti l'utente da autenticare. Per questa guida, useremo il modello seguente, ma puoi usare un qualsiasi modello esistente.

```swift
import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    init() { }

    init(id: UUID? = nil, name: String, email: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
    }
}
```

Il modello deve essere in grado di memorizzare un nome utente, in questo caso un'e-mail, e un hash di password. Abbiamo anche impostato `email` come campo unico, per evitare utenti duplicati. La migrazione corrispondente per questo modello di esempio è qui:

```swift
import Fluent
import Vapor

extension User {
    struct Migration: AsyncMigration {
        var name: String { "CreateUser" }

        func prepare(on database: Database) async throws {
            try await database.schema("users")
                .id()
                .field("name", .string, .required)
                .field("email", .string, .required)
                .field("password_hash", .string, .required)
                .unique(on: "email")
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema("users").delete()
        }
    }
}
```

Non dimenticare di aggiungere la migrazione a `app.migrations`.

```swift
app.migrations.add(User.Migration())
```

!!! tip
    Poiché gli indirizzi email non sono sensibili alle maiuscole e alle minuscole, puoi aggiungere un [`Middleware`](../fluent/model.md#lifecycle) che coercizzi l'indirizzo email in minuscolo prima di salvarlo nella base dati. Tieni presente, però, che `ModelAuthenticatable` usa un confronto sensibile alle maiuscole e alle minuscole, quindi se fai questo devi assicurarti che l'input dell'utente sia tutto minuscolo, o con la coercizione delle maiuscole nel client o con un autenticatore personalizzato.

La prima cosa di cui hai bisogno è un endpoint per creare nuovi utenti. Useremo `POST /users`. Crea una struttura [Content](../basics/content.md) che rappresenti i dati che questo endpoint si aspetta.

```swift
import Vapor

extension User {
    struct Create: Content {
        var name: String
        var email: String
        var password: String
        var confirmPassword: String
    }
}
```

Se vuoi, puoi conformare questa struttura a [Validatable](../basics/validation.md) per aggiungere requisiti di validazione.

```swift
import Vapor

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}
```

Ora puoi creare l'endpoint `POST /users`.

```swift
app.post("users") { req async throws -> User in
    try User.Create.validate(content: req)
    let create = try req.content.decode(User.Create.self)
    guard create.password == create.confirmPassword else {
        throw Abort(.badRequest, reason: "Passwords did not match")
    }
    let user = try User(
        name: create.name,
        email: create.email,
        passwordHash: Bcrypt.hash(create.password)
    )
    try await user.save(on: req.db)
    return user
}
```

Questo endpoint convalida la richiesta in arrivo, decodifica la struttura `User.Create` e controlla che le password corrispondano. Utilizza quindi i dati decodificati per creare un nuovo `User` e lo salva nel database. La password in chiaro viene sottoposta a hash con `Bcrypt` prima di essere salvata nel database.

Compila ed esegui il progetto, assicurandoti di eseguire prima le migrazioni sul database, quindi utilizza la seguente richiesta per creare un nuovo utente.

```http
POST /users HTTP/1.1
Content-Length: 97
Content-Type: application/json

{
    "name": "Vapor",
    "email": "test@vapor.codes",
    "password": "secret42",
    "confirmPassword": "secret42"
}
```

#### Modello Authenticatable

Ora che hai un modello utente e un endpoint per creare nuovi utenti, conforma il modello a `ModelAuthenticatable`. Questo ti permetterà di autenticare il modello usando nome utente e password.

```swift
import Fluent
import Vapor

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}
```

Questa estensione aggiunge la conformità `ModelAuthenticatable` a `User`. Le prime due proprietà specificano quali campi devono essere utilizzati per memorizzare rispettivamente il nome utente e l'hash della password. La notazione `\` crea un percorso chiave per i campi che Fluent può usare per accedervi.

L'ultimo requisito è un metodo per verificare le password in chiaro inviate nell'intestazione di autenticazione Basic. Poiché usiamo Bcrypt per l'hash della password durante la registrazione, useremo Bcrypt per verificare che la password fornita corrisponda all'hash della password memorizzata.

Ora che l'utente `User` è conforme a `ModelAuthenticatable`, puoi creare un autenticatore per proteggere la route di login.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req -> User in
    try req.auth.require(User.self)
}
```

`ModelAuthenticatable` aggiunge un metodo statico `authenticator` per creare un autenticatore.

Verifica che questo percorso funzioni inviando la seguente richiesta:

```http
POST /login HTTP/1.1
Authorization: Basic dGVzdEB2YXBvci5jb2RlczpzZWNyZXQ0Mg==
```

Questa richiesta passa il nome utente `test@vapor.codes` e la password `secret42` tramite l'intestazione di autenticazione Basic. Dovrebbe essere restituito l'utente precedentemente creato.

Anche se in teoria si potrebbe usare l'autenticazione di base per proteggere tutti gli endpoint, è consigliato usare un token separato. In questo modo si riduce al minimo la frequenza di invio della password sensibile dell'utente su Internet. Inoltre, l'autenticazione è molto più veloce, poiché è sufficiente eseguire l'hashing della password durante l'accesso.

### Token Utente

Crea un nuovo modello per rappresentare i token degli utenti.

```swift
import Fluent
import Vapor

final class UserToken: Model, Content {
    static let schema = "user_tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "value")
    var value: String

    @Parent(key: "user_id")
    var user: User

    init() { }

    init(id: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
}
```

Questo modello deve avere un campo `value` per memorizzare la stringa unica del token. Deve anche avere una [relazione padre](../fluent/overview.md#parent) con il modello utente. Puoi aggiungere anche altre proprietà a questo token, come ad esempio una data di scadenza.

Quindi, crea una migrazione per questo modello.

```swift
import Fluent

extension UserToken {
    struct Migration: AsyncMigration {
        var name: String { "CreateUserToken" }
        
        func prepare(on database: Database) async throws {
            try await database.schema("user_tokens")
                .id()
                .field("value", .string, .required)
                .field("user_id", .uuid, .required, .references("users", "id"))
                .unique(on: "value")
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema("user_tokens").delete()
        }
    }
}
```

Nota che questa migrazione rende unico il campo `value`. Inoltre, crea un riferimento a chiave esterna tra il campo `user_id` e la tabella utenti.

Non dimenticare di aggiungere la migrazione a `app.migrations`.

```swift
app.migrations.add(UserToken.Migration())
```

Infine, aggiungi un metodo su `User` per generare un nuovo token. Questo metodo sarà utilizzato durante il login.

```swift
extension User {
    func generateToken() throws -> UserToken {
        try .init(
            value: [UInt8].random(count: 16).base64, 
            userID: self.requireID()
        )
    }
}
```

Qui usiamo `[UInt8].random(count:)` per generare un valore casuale di token. Per questo esempio, vengono utilizzati 16 byte, o 128 bit, di dati casuali. Puoi modificare questo numero come ritieni opportuno. I dati casuali vengono poi codificati in base-64 per facilitarne la trasmissione nelle intestazioni HTTP.

Ora che puoi generare i token utente, aggiorna la route `POST /login` per creare e restituire un token.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req async throws -> UserToken in
    let user = try req.auth.require(User.self)
    let token = try user.generateToken()
    try await token.save(on: req.db)
    return token
}
```

Verifica che questa route funzioni utilizzando la stessa richiesta di login di cui sopra. Ora dovresti ottenere un token al momento dell'accesso che assomigli a qualcosa di simile:

```
8gtg300Jwdhc/Ffw784EXA==
```

Conserva il token ottenuto: lo utilizzeremo a breve.

#### Modello Token Authenticatable

Conforma `UserToken` a `ModelTokenAuthenticatable`. Questo permetterà ai token di autenticare il modello `User`.

```swift
import Vapor
import Fluent

extension UserToken: ModelTokenAuthenticatable {
    static let valueKey = \UserToken.$value
    static let userKey = \UserToken.$user

    var isValid: Bool {
        true
    }
}
```

Il primo requisito del protocollo specifica quale campo memorizza il valore univoco del token. Questo è il valore che sarà inviato nell'intestazione di autenticazione Bearer. Il secondo requisito specifica la parentela con il modello `User`. Questo è il modo in cui Fluent cercherà l'utente autenticato.

Il requisito finale è un booleano `isValid`. Se è `false`, il token sarà cancellato dal database e l'utente non sarà autenticato. Per semplicità, renderemo i token eterni, codificando in modo rigido questo valore a `true`.

Ora che il token è conforme a `ModelTokenAuthenticatable`, si può creare un autenticatore per proteggere le route.

Crea un nuovo endpoint `GET /me` per ottenere l'utente attualmente autenticato.

```swift
let tokenProtected = app.grouped(UserToken.authenticator())
tokenProtected.get("me") { req -> User in
    try req.auth.require(User.self)
}
```

Simile a `User`, `UserToken` ha ora un metodo statico `authenticator()` che può generare un autenticatore. L'autenticatore cercherà di trovare un `UserToken` corrispondente, utilizzando il valore fornito nell'intestazione di autenticazione del portatore. Se trova una corrispondenza, recupera il relativo `User` e lo autentica.

Verifica che questa route funzioni inviando la seguente richiesta HTTP, dove il token è il valore salvato dalla richiesta `POST /login`.

```http
GET /me HTTP/1.1
Authorization: Bearer <token>
```

Dovresti vedere l'utente attualmente autenticato.

## Sessioni

L'[API delle Sessioni](../advanced/sessions.md) di Vapor può essere utilizzata per persistere automaticamente l'autenticazione dell'utente tra le richieste. Questo funziona memorizzando un identificatore univoco per l'utente nei dati di sessione della richiesta, dopo il successo del login. Nelle richieste successive, l'identificatore dell'utente viene recuperato dalla sessione e usato per autenticare l'utente prima di chiamare il gestore della route.

Le sessioni sono ottime per le applicazioni web front-end costruite in Vapor che servono HTML direttamente ai browser web. Per le API, si consiglia di utilizzare un'autenticazione stateless basata su token per conservare i dati dell'utente tra una richiesta e l'altra.

### Session Authenticatable

Per utilizzare l'autenticazione basata sulla sessione, occorre un tipo conforme a `SessionAuthenticatable`. Per questo esempio, useremo una semplice struct.

```swift
import Vapor

struct User {
    var email: String
}
```

Per essere conformi a `SessionAuthenticatable`, è necessario specificare un `sessionID`. Questo è il valore che verrà memorizzato nei dati di sessione e deve identificare in modo univoco l'utente.

```swift
extension User: SessionAuthenticatable {
    var sessionID: String {
        self.email
    }
}
```

Per il nostro tipo `User`, useremo l'indirizzo e-mail come identificatore unico di sessione.

### Autenticatore di Sessione

Poi, avrai bisogno di un `SessionAuthenticator` per gestire la risoluzione delle istanze dell'utente dall'identificatore di sessione persistito.

```swift
struct UserSessionAuthenticator: SessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: String, for request: Request) -> EventLoopFuture<Void> {
        let user = User(email: sessionID)
        request.auth.login(user)
        return request.eventLoop.makeSucceededFuture(())
    }
}
```

Se stai usando `async`/`await`, puoi usare `AsyncSessionAuthenticator`:

```swift
struct UserSessionAuthenticator: AsyncSessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: String, for request: Request) async throws {
        let user = User(email: sessionID)
        request.auth.login(user)
    }
}
```

Poiché tutte le informazioni necessarie per inizializzare il nostro `User` di esempio sono contenute nell'identificatore di sessione, possiamo creare e accedere all'utente in modo sincrono. In un'applicazione reale, è probabile che venga utilizzato l'identificatore di sessione per eseguire una ricerca nel database o una richiesta API per recuperare il resto dei dati dell'utente prima dell'autenticazione.

Quindi, crea un semplice autenticatore di portatori per eseguire l'autenticazione iniziale.

```swift
struct UserBearerAuthenticator: AsyncBearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        if bearer.token == "test" {
            let user = User(email: "hello@vapor.codes")
            request.auth.login(user)
        }
    }
}
```

Questo autenticatore autenticherà un utente con l'email `hello@vapor.codes` quando viene inviato il token portatore `test`.

Infine, combina tutti questi pezzi insieme nell'applicazione.

```swift
// Crea un gruppo di route protette che richiedono autenticazione.
let protected = app.routes.grouped([
    app.sessions.middleware,
    UserSessionAuthenticator(),
    UserBearerAuthenticator(),
    User.guardMiddleware(),
])

// Aggiungi una route GET /me che restituisce l'email dell'utente.
protected.get("me") { req -> String in
    try req.auth.require(User.self).email
}
```

Viene prima aggiunto `SessionsMiddleware`, per abilitare il supporto alle sessioni nell'applicazione. Puoi trovare maggiori informazioni sulla configurazione delle sessioni nella sezione [API di sessione](../advanced/sessions.md).

Successivamente, viene aggiunto il `SessionAuthenticator`. Questo gestisce l'autenticazione dell'utente se è attiva una sessione.

Se l'autenticazione non è ancora stata persistita nella sessione, la richiesta sarà inoltrata all'autenticatore successivo. L'autenticatore `UserBearerAuthenticator` controllerà il token del portatore e autenticherà l'utente se è uguale a `"test"`.

Infine, `User.guardMiddleware()` assicura che `User` sia stato autenticato da uno dei middleware precedenti. Se l'utente non è stato autenticato, verrà lanciato un errore.

Per testare questa route, invia prima la seguente richiesta:

```http
GET /me HTTP/1.1
authorization: Bearer test
```

Questo farà sì che `UserBearerAuthenticator` autentichi l'utente. Una volta autenticato, `UserSessionAuthenticator` persisterà l'identificatore dell'utente nella memoria di sessione e genererà un cookie. Puoi poi utilizzare il cookie dalla risposta in una seconda richiesta alla route.

```http
GET /me HTTP/1.1
cookie: vapor_session=123
```

Questa volta, `UserSessionAuthenticator` autenticherà l'utente e dovrebbe essere restituita l'e-mail dell'utente.

### Model Session Authenticatable

I modelli Fluent possono generare `SessionAuthenticator` conformandosi a `ModelSessionAuthenticatable`. Questo userà l'identificatore univoco del modello come identificatore di sessione ed eseguirà automaticamente una ricerca nel database per ripristinare il modello dalla sessione.

```swift
import Fluent

final class User: Model { ... }

// Consente di persistere il modello nelle sessioni.
extension User: ModelSessionAuthenticatable { }
```

Puoi aggiungere `ModelSessionAuthenticatable` a qualsiasi modello esistente come conformità vuota. Una volta aggiunto, sarà disponibile un nuovo metodo statico per creare un `SessionAuthenticator` per quel modello.

```swift
User.sessionAuthenticator()
```

Questo utilizzerà il database predefinito dell'applicazione per la risoluzione dell'utente. Per specificare un database, passa l'identificatore.

```swift
User.sessionAuthenticator(.sqlite)
```

## Autenticazione per Sito Web

I siti web sono un caso particolare per l'autenticazione, perché l'uso di un browser limita il modo in cui è possibile collegare le credenziali a un browser. Questo porta a due diversi scenari di autenticazione:

* l'accesso iniziale tramite un form
* chiamate successive autenticate con un cookie di sessione

Vapor e Fluent forniscono diversi aiutanti per rendere tutto ciò semplice.

### Autenticazione di Sessione

L'autenticazione di sessione funziona come descritto sopra. Devi applicare il middleware di sessione e l'autenticatore di sessione a tutte le route a cui l'utente accederà. Queste includono tutte le route protette, le route che sono pubbliche, ma per le quali vuoi accedere all'utente se è loggato (ad esempio, per visualizzare un pulsante per l'account), **e** le route di login.

È possibile attivarlo globalmente nella propria applicazione in `configure.swift` in questo modo:

```swift
app.middleware.use(app.sessions.middleware)
app.middleware.use(User.sessionAuthenticator())
```

Questi middleware svolgono le seguenti funzioni:

* Il middleware delle sessioni prende il cookie di sessione fornito nella richiesta e lo converte in una sessione.
* l'autenticatore di sessione prende la sessione e verifica se esiste un utente autenticato per quella sessione. In caso affermativo, il middleware autentica la richiesta. Nella risposta, l'autenticatore di sessione vede se la richiesta ha un utente autenticato e lo salva nella sessione, in modo che sia autenticato nella richiesta successiva.

!!! note
    Di default, il cookie di sessione non è impostato su `secure` e/o `httpOnly`. Per ulteriori informazioni su come configurare i cookie, consultare le [API di sessione](../advanced/sessions.md#configuration) di Vapor.

### Protezione delle Route

Quando si proteggono le route per un'API, tradizionalmente restituisci una risposta HTTP con un codice di stato come **401 Unauthorized** se la richiesta non è autenticata. Tuttavia, questa non è una buona esperienza per l'utente che utilizza un browser. Vapor fornisce un `RedirectMiddleware` per qualsiasi tipo `Authenticatable` da utilizzare in questo scenario:

```swift
let protectedRoutes = app.grouped(User.redirectMiddleware(path: "/login?loginRequired=true"))
```

L'oggetto `RedirectMiddleware` supporta anche il passaggio di una chiusura che restituisce il percorso di reindirizzamento come `Stringa` durante la creazione, per una gestione avanzata degli url. Ad esempio, includendo il percorso di reindirizzamento come parametro di query alla destinazione del reindirizzamento per la gestione dello stato.

```swift
let redirectMiddleware = User.redirectMiddleware { req -> String in
  return "/login?authRequired=true&next=\(req.url.path)"
}
```

Questo funziona in modo simile a `GuardMiddleware`. Qualsiasi richiesta alle route registrate su `protectedRoutes` che non sia autenticata sarà reindirizzata al percorso fornito. Questo permette di dire agli utenti di effettuare il login, invece di fornire semplicemente un **401 Unauthorized**.

Assicurati di includere un Autenticatore di sessione prima del `RedirectMiddleware` per garantire che l'utente autenticato sia caricato prima di passare attraverso il `RedirectMiddleware`.

```swift
let protectedRoutes = app.grouped([User.sessionAuthenticator(), redirectMiddleware])
```

### Form per il Login

Per autenticare un utente e le richieste future con una sessione, è necessario effettuare il login. Vapor fornisce un protocollo `ModelCredentialsAuthenticatable` a cui conformarsi. Questo gestisce l'accesso tramite un modulo. Per prima cosa, conforma il tuo `User` a questo protocollo:

```swift
extension User: ModelCredentialsAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
```

Questo è identico a `ModelAuthenticatable` e se lo `User` è già conforme a questo, non è necessario fare altro. Quindi applica il middleware `ModelCredentialsAuthenticator` alla richiesta POST del modulo di login:

```swift
let credentialsProtectedRoute = sessionRoutes.grouped(User.credentialsAuthenticator())
credentialsProtectedRoute.post("login", use: loginPostHandler)
```

Esso utilizza l'autenticatore di credenziali predefinito per proteggere il percorso di accesso. È necessario che invii `username` e `password` nella richiesta POST. Si può impostare il form in questo modo:

```html
 <form method="POST" action="/login">
    <label for="username">Username</label>
    <input type="text" id="username" placeholder="Username" name="username" autocomplete="username" required autofocus>
    <label for="password">Password</label>
    <input type="password" id="password" placeholder="Password" name="password" autocomplete="current-password" required>
    <input type="submit" value="Sign In">    
</form>
```

Il `CredentialsAuthenticator` estrae `username` e `password` dal corpo della richiesta, trova l'utente dal nome utente e verifica la password. Se la password è valida, il middleware autentica la richiesta. Il `SessionAuthenticator` autentica quindi la sessione per le richieste successive.

## JWT

[JWT](jwt.md) fornisce un `JWTAuthenticator` che può essere usato per autenticare i token web JSON nelle richieste in arrivo. Se non conosci JWT, dai un'occhiata alla [panoramica](jwt.md).

Per prima cosa, crea un tipo che rappresenti un payload JWT.

```swift
// Esempio di payload JWT.
struct SessionToken: Content, Authenticatable, JWTPayload {

    // Costanti
    let expirationTime: TimeInterval = 60 * 15
    
    // Dati del payload
    var expiration: ExpirationClaim
    var userId: UUID
    
    init(userId: UUID) {
        self.userId = userId
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
    }
    
    init(user: User) throws {
        self.userId = try user.requireID()
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
    }

    func verify(using signer: JWTSigner) throws {
        try expiration.verifyNotExpired()
    }
}
```

Successivamente, possiamo definire una rappresentazione dei dati contenuti in una risposta di login andata a buon fine. Per ora la risposta avrà solo una proprietà, una stringa che rappresenta un JWT firmato.

```swift
struct ClientTokenReponse: Content {
    var token: String
}
```

Utilizzando il nostro modello per il token JWT e la risposta, possiamo usare una route di login protetta da password che restituisce un `ClientTokenReponse` e include un `SessionToken` firmato.

```swift
let passwordProtected = app.grouped(User.authenticator(), User.guardMiddleware())
passwordProtected.post("login") { req -> ClientTokenReponse in
    let user = try req.auth.require(User.self)
    let payload = try SessionToken(with: user)
    return ClientTokenReponse(token: try req.jwt.sign(payload))
}
```

In alternativa, se non vuoi usare un autenticatore, puoi avere qualcosa di simile a questo:

```swift
app.post("login") { req -> ClientTokenReponse in
    // Valida le credenziali dell'utente
    // Ottieni lo userId dell'utente
    let payload = try SessionToken(userId: userId)
    return ClientTokenReponse(token: try req.jwt.sign(payload))
}
```

Conformando il payload a `Authenticatable` e `JWTPayload`, puoi generare un autenticatore di route usando il metodo `authenticator()`. Aggiungilo a un gruppo di route per recuperare e verificare automaticamente il JWT prima che la route venga chiamata.

```swift
// Crea un gruppo di route che richiede il SessionToken JWT.
let secure = app.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())
```

L'aggiunta dell'opzionale [middleware di guardia](#guard-middleware) richiede che l'autorizzazione sia riuscita.

All'interno delle route protette, si può accedere al payload JWT autenticato usando `req.auth`.

```swift
// Restituisce una risposta ok se il token fornito dall'utente è valido.
secure.post("validateLoggedInUser") { req -> HTTPStatus in
    let sessionToken = try req.auth.require(SessionToken.self)
    print(sessionToken.userId)
    return .ok
}
```
