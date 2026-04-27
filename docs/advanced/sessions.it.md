# Sessioni

Le sessioni ti consentono di mantenere i dati di un utente tra più richieste. Le sessioni funzionano creando e restituendo un cookie univoco insieme alla risposta HTTP quando viene inizializzata una nuova sessione. I browser rileveranno automaticamente questo cookie e lo includeranno nelle richieste future. Questo consente a Vapor di ripristinare automaticamente la sessione di un utente specifico nel tuo gestore di richieste.

Le sessioni sono ottime per le applicazioni web front-end create in Vapor che servono HTML direttamente ai browser web. Per le API, raccomandiamo di usare l'[autenticazione basata su token](../security/authentication.it.md) stateless per mantenere i dati utente tra le richieste.

## Configurazione

Per usare le sessioni in una route, la richiesta deve passare attraverso `SessionsMiddleware`. Il modo più semplice per ottenere questo è aggiungere questo middleware globalmente. Si raccomanda di aggiungerlo dopo aver dichiarato la cookie factory. Questo perché Sessions è una `struct`, quindi è un tipo valore e non un tipo riferimento. Siccome è un tipo valore, devi impostarne il valore prima di usare `SessionsMiddleware`.

```swift
app.middleware.use(app.sessions.middleware)
```

Se solo un sottoinsieme delle tue route utilizza le sessioni, puoi invece aggiungere `SessionsMiddleware` a un gruppo di route.

```swift
let sessions = app.grouped(app.sessions.middleware)
```

Il cookie HTTP generato dalle sessioni può essere configurato usando `app.sessions.configuration`. Puoi cambiare il nome del cookie e dichiarare una funzione personalizzata per generare i valori dei cookie.

```swift
// Cambia il nome del cookie in "foo".
app.sessions.configuration.cookieName = "foo"

// Configura la creazione del valore del cookie.
app.sessions.configuration.cookieFactory = { sessionID in
    .init(string: sessionID.string, isSecure: true)
}

app.middleware.use(app.sessions.middleware)
```

Per impostazione predefinita, Vapor userà `vapor_session` come nome del cookie.

## Driver

I driver di sessione sono responsabili della memorizzazione e del recupero dei dati di sessione tramite identificatore. Puoi creare driver personalizzati conformandoti al protocollo `SessionDriver`.

!!! warning "Attenzione"
	Il driver di sessione dovrebbe essere configurato _prima_ di aggiungere `app.sessions.middleware` alla tua applicazione.

### In-Memory

Vapor utilizza le sessioni in-memory per impostazione predefinita. Le sessioni in-memory non richiedono alcuna configurazione e non persistono tra i riavvii dell'applicazione, il che le rende ottime per i test. Per abilitare manualmente le sessioni in-memory, usa `.memory`:

```swift
app.sessions.use(.memory)
```

Per i casi d'uso in produzione, dai un'occhiata agli altri driver di sessione che utilizzano database per mantenere e condividere le sessioni tra più istanze della tua app.

### Fluent

Fluent include il supporto per memorizzare i dati di sessione nel database della tua applicazione. Questa sezione presuppone che tu abbia [configurato Fluent](../fluent/overview.it.md) e possa connetterti a un database. Il primo passo è abilitare il driver di sessione Fluent.

```swift
import Fluent

app.sessions.use(.fluent)
```

Questo configurerà le sessioni in maniera da usare il database predefinito dell'applicazione. Per specificare un database specifico, passa l'ID del database.

```swift
app.sessions.use(.fluent(.sqlite))
```

Infine, aggiungi la migration di `SessionRecord` alle migration del tuo database. Questo preparerà il tuo database per memorizzare i dati di sessione nello schema `_fluent_sessions`.

```swift
app.migrations.add(SessionRecord.migration)
```

Assicurati di eseguire le migration della tua applicazione dopo aver aggiunto la nuova migration. Le sessioni verranno ora memorizzate nel database della tua applicazione, consentendo loro di persistere tra i riavvii e di essere condivise tra più istanze della tua app.

### Redis

Redis fornisce supporto per memorizzare i dati di sessione nell'istanza Redis configurata. Questa sezione presuppone che tu abbia [configurato Redis](../redis/overview.it.md) e possa inviare comandi all'istanza Redis.

Per usare Redis per le sessioni, selezionalo durante la configurazione della tua applicazione:

```swift
import Redis

app.sessions.use(.redis)
```

Questo configurerà le sessioni per usare il driver di sessione Redis con il comportamento predefinito.

!!! seealso "Vedi anche"
    Fai riferimento a [Redis &rarr; Sessions](../redis/sessions.it.md) per informazioni più dettagliate su Redis e le sessioni.

## Dati di Sessione

Ora che le sessioni sono configurate, sei pronto per mantenere i dati tra le richieste. Le nuove sessioni vengono inizializzate automaticamente quando i dati vengono aggiunti a `req.session`. Il gestore di route di esempio qui sotto accetta un parametro di route dinamico e aggiunge il valore a `req.session.data`.

```swift
app.get("set", ":value") { req -> HTTPStatus in
    req.session.data["name"] = req.parameters.get("value")
    return .ok
}
```

Usa la seguente richiesta per inizializzare una sessione con il nome Vapor.

```http
GET /set/vapor HTTP/1.1
content-length: 0
```

Dovresti ricevere una risposta simile alla seguente:

```http
HTTP/1.1 200 OK
content-length: 0
set-cookie: vapor-session=123; Expires=Fri, 10 Apr 2020 21:08:09 GMT; Path=/
```

Nota che l'header `set-cookie` è stato aggiunto automaticamente alla risposta dopo aver aggiunto dati a `req.session`. Includendo questo cookie nelle richieste successive sarà possibile accedere ai dati di sessione.

Aggiungi il seguente gestore di route per accedere al valore del nome dalla sessione.

```swift
app.get("get") { req -> String in
    req.session.data["name"] ?? "n/a"
}
```

Usa la seguente richiesta per accedere a questa route assicurandoti di passare il valore del cookie dalla risposta precedente.

```http
GET /get HTTP/1.1
cookie: vapor-session=123
```

Dovresti vedere il nome Vapor restituito nella risposta. Puoi aggiungere o rimuovere dati dalla sessione come preferisci. I dati di sessione verranno sincronizzati automaticamente con il driver di sessione prima di restituire la risposta HTTP.

Per terminare una sessione, usa `req.session.destroy`. Questo eliminerà i dati dal driver di sessione e invaliderà il cookie di sessione.

```swift
app.get("del") { req -> HTTPStatus in
    req.session.destroy()
    return .ok
}
```
