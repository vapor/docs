# Sessions

Mit Sessions kannst du die Daten eines Nutzers zwischen mehreren Requests persistieren. Sessions funktionieren, indem beim Initialisieren einer neuen Session zusammen mit der HTTP-Response ein eindeutiges Cookie erstellt und zurückgegeben wird. Browser erkennen dieses Cookie automatisch und schicken es bei zukünftigen Requests mit. Dadurch kann Vapor die Session eines bestimmten Nutzers in deinem Request-Handler automatisch wiederherstellen.

Sessions eignen sich hervorragend für Frontend-Webanwendungen, die in Vapor erstellt werden und HTML direkt an Webbrowser ausliefern. Für APIs empfehlen wir die Verwendung von zustandsloser, [Token-basierter Authentifizierung](../security/authentication.md), um Nutzerdaten zwischen Requests zu persistieren.

## Konfiguration

Damit Sessions in einer Route genutzt werden können, muss der Request die `SessionsMiddleware` durchlaufen. Der einfachste Weg, dies zu erreichen, besteht darin, diese Middleware global hinzuzufügen. Es wird empfohlen, sie hinzuzufügen, nachdem du die Cookie-Factory deklariert hast. Das liegt daran, dass Sessions eine struct und somit ein Wertetyp und kein Referenztyp ist. Da es sich um einen Wertetyp handelt, musst du den Wert setzen, bevor du die `SessionsMiddleware` verwendest.

```swift
app.middleware.use(app.sessions.middleware)
```

Wenn nur ein Teil deiner Routen Sessions nutzt, kannst du die `SessionsMiddleware` stattdessen zu einer Routengruppe hinzufügen.

```swift
let sessions = app.grouped(app.sessions.middleware)
```

Das von Sessions erzeugte HTTP-Cookie kann über `app.sessions.configuration` konfiguriert werden. Du kannst den Cookie-Namen ändern und eine benutzerdefinierte Funktion zur Erzeugung der Cookie-Werte festlegen.

```swift
// Change the cookie name to "foo".
app.sessions.configuration.cookieName = "foo"

// Configures cookie value creation.
app.sessions.configuration.cookieFactory = { sessionID in
    .init(string: sessionID.string, isSecure: true)
}

app.middleware.use(app.sessions.middleware)
```

Standardmäßig verwendet Vapor `vapor_session` als Cookie-Namen.

## Driver

Session-Driver sind dafür verantwortlich, Session-Daten anhand eines Identifiers zu speichern und abzurufen. Du kannst eigene Driver erstellen, indem du dem `SessionDriver`-Protokoll entsprichst.

!!! warning
    Der Session-Driver sollte konfiguriert werden, _bevor_ du `app.sessions.middleware` zu deiner Anwendung hinzufügst.

### In-Memory

Vapor verwendet standardmäßig In-Memory-Sessions. In-Memory-Sessions benötigen keinerlei Konfiguration und bleiben zwischen den Starts der Anwendung nicht erhalten, was sie ideal für Tests macht. Um In-Memory-Sessions manuell zu aktivieren, verwende `.memory`:

```swift
app.sessions.use(.memory)
```

Für den produktiven Einsatz solltest du dir die anderen Session-Driver ansehen, die Datenbanken nutzen, um Sessions über mehrere Instanzen deiner Anwendung hinweg zu persistieren und zu teilen.

### Fluent

Fluent bietet Unterstützung zum Speichern von Session-Daten in der Datenbank deiner Anwendung. Dieser Abschnitt setzt voraus, dass du [Fluent konfiguriert](../fluent/overview.md) hast und eine Verbindung zu einer Datenbank herstellen kannst. Der erste Schritt besteht darin, den Fluent-Session-Driver zu aktivieren.

```swift
import Fluent

app.sessions.use(.fluent)
```

Dies konfiguriert Sessions so, dass sie die Standarddatenbank der Anwendung verwenden. Um eine bestimmte Datenbank anzugeben, übergib den Identifier der Datenbank.

```swift
app.sessions.use(.fluent(.sqlite))
```

Füge abschließend die Migration von `SessionRecord` zu den Migrationen deiner Datenbank hinzu. Dadurch wird deine Datenbank darauf vorbereitet, Session-Daten im Schema `_fluent_sessions` zu speichern.

```swift
app.migrations.add(SessionRecord.migration)
```

Stelle sicher, dass du die Migrationen deiner Anwendung ausführst, nachdem du die neue Migration hinzugefügt hast. Sessions werden nun in der Datenbank deiner Anwendung gespeichert, wodurch sie Neustarts überdauern und zwischen mehreren Instanzen deiner Anwendung geteilt werden können.

### Redis

Redis bietet Unterstützung zum Speichern von Session-Daten in deiner konfigurierten Redis-Instanz. Dieser Abschnitt setzt voraus, dass du [Redis konfiguriert](../redis/overview.md) hast und Befehle an die Redis-Instanz senden kannst.

Um Redis für Sessions zu verwenden, wähle es bei der Konfiguration deiner Anwendung aus:

```swift
import Redis

app.sessions.use(.redis)
```

Dies konfiguriert Sessions so, dass sie den Redis-Session-Driver mit dem Standardverhalten verwenden.

!!! seealso
    Siehe [Redis &rarr; Sessions](../redis/sessions.md) für detailliertere Informationen zu Redis und Sessions.

## Session-Daten

Jetzt, da Sessions konfiguriert sind, kannst du Daten zwischen Requests persistieren. Neue Sessions werden automatisch initialisiert, sobald Daten zu `req.session` hinzugefügt werden. Der folgende Beispiel-Route-Handler nimmt einen dynamischen Routenparameter entgegen und fügt den Wert zu `req.session.data` hinzu.

```swift
app.get("set", ":value") { req -> HTTPStatus in
    req.session.data["name"] = req.parameters.get("value")
    return .ok
}
```

Verwende den folgenden Request, um eine Session mit dem Namen Vapor zu initialisieren.

```http
GET /set/vapor HTTP/1.1
content-length: 0
```

Du solltest eine Response ähnlich der folgenden erhalten:

```http
HTTP/1.1 200 OK
content-length: 0
set-cookie: vapor-session=123; Expires=Fri, 10 Apr 2020 21:08:09 GMT; Path=/
```

Beachte, dass der `set-cookie`-Header der Response automatisch hinzugefügt wurde, nachdem Daten zu `req.session` hinzugefügt wurden. Wenn dieses Cookie bei nachfolgenden Requests mitgesendet wird, ermöglicht dies den Zugriff auf die Session-Daten.

Füge den folgenden Route-Handler hinzu, um auf den Namenswert aus der Session zuzugreifen.

```swift
app.get("get") { req -> String in
    req.session.data["name"] ?? "n/a"
}
```

Verwende den folgenden Request, um auf diese Route zuzugreifen, und stelle dabei sicher, dass du den Cookie-Wert aus der vorherigen Response mitsendest.

```http
GET /get HTTP/1.1
cookie: vapor-session=123
```

Du solltest den Namen Vapor in der Response zurückerhalten sehen. Du kannst Daten nach Belieben zur Session hinzufügen oder daraus entfernen. Die Session-Daten werden automatisch mit dem Session-Driver synchronisiert, bevor die HTTP-Response zurückgegeben wird.

Um eine Session zu beenden, verwende `req.session.destroy`. Dadurch werden die Daten aus dem Session-Driver gelöscht und das Session-Cookie invalidiert.

```swift
app.get("del") { req -> HTTPStatus in
    req.session.destroy()
    return .ok
}
```
