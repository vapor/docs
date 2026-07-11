# Routing

Beim Routing geht es um das Verteilen der eingehenden Serveranfragen, an die richtigen Anwendungsendpunkte. Endpunkte sind Einheiten zur Verarbeitung der Anfragen. Sie werden im Controller definiert und beim Starten der Anwendung registriert. Im Kern von Vapors Routing steckt ein hochperformanter, trie-basierter Router aus [RoutingKit](https://github.com/vapor/routing-kit).

## Grundlagen

Um das Ganze besser zu verstehen, werfen wir einen Blick auf den Aufbau einer solchen Serveranfrage.

```http
GET /hello/vapor HTTP/1.1
host: vapor.codes
content-length: 0
```

Im Beispiel handelt es sich eine typische Anfrage an die URL `/hello/vapor/`. Die selbe Anfrage wird erstellt, wenn wir im Browser folgenden Link aufrufen:

```
http://vapor.codes/hello/vapor
```

### Anfragemethode

Ganz am Anfang der Serveranfrage steht die Anfragemethode. Wie im Beispiel, ist _GET_ die meistgenutzte Methode, jedoch gibt es noch weitere Methoden, die zumeist in Verbindung mit [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) zum Einsatz kommen.

|Methode|Aktion |Beschreibung                                          |
|-------|-------|------------------------------------------------------|
|GET    |Read   |Daten werden vom Server angefordert.                  |
|POST   |Create |Daten werden an den Server gesendet.|
|PUT    |Replace|Daten werden an den Server gesendet.|
|PATCH  |Update |Daten werden an den Server gesendet|
|DELETE |Delete |Daten werden vom Server gelöscht.|

### Anfragepfad

Auf die Methode folgt der Zielpfad der Anfrage. Die Zielpfad besteht aus einem Pfad und einer optionalen Zeichenabfolge `?`. Vapor benutzt beides um die Anfrage an den richtigen Endpunkt weiterzuleiten. 

Nach der URI folgt die HTTP-Version, gefolgt von keinem, einem oder mehreren Headern und schließlich einem Body. Da es sich um eine `GET`-Anfrage handelt, hat sie keinen Body.

### Endpunktmethoden

Vapor stellt alle Anfragemethoden als Methoden über die Application-Instanz zur Verfügung. Die Methoden akzeptieren einen oder mehrere Pfadangaben vom Typ _String_, die nachfolgend mit einem '/' getrennt zu einem Pfad zusammengestellt werden.

```swift
/// [controller.swift]

app.get("hello", "vapor") { req in 
    return "Hello, vapor!"
}

/// Die .on()-Variante ist ebenfalls möglich.
app.on(.GET, "hello", "vapor") { ... }
```

Nachdem dieser Endpunkt registriert ist, führt die obige Beispielanfrage zu folgender Antwort:

```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, vapor!
```

### Endpunktargumente

Durch das Voransetzen eines Doppelpunktes vor Parameterangabe zum Beispiel _:name_, erkennt Vapor, dass es sich hierbei um einem variablen Angabe handeln soll und somit jeder Parameter von Typ _String_ akzeptiert wird. Über die Eigenschaft _Parameters_ können wir nun auf den Angabe zugreifen.

```swift
/// [controllers.swift]

app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

Wenn wir nun die Anfrage im Beispiel erneut ausführen, bekommen wir immer noch die selbe Antwort. Allerdings können wir nun hinter `/hello/` einen beliebige Angabe machen, zum Beispiel `/hello/swift` und bekommen folgende Antwort zurück:

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

Nachdem wir uns die Einführung angesehen haben, können wir uns den nachfolgenden Abschnitten widmen.

## Endpunktdefinition

Ein Endpunkt legt einen Request-Handler für eine bestimmte HTTP-Methode und einen URI-Pfad fest. Er kann zudem zusätzliche Metadaten speichern.

### Methoden

Endpunkte können der Anwendung über die Instanz _Application_ und den Methoden bekannt gemacht werden.

```swift
// [controllers.swift]

app.get("foo", "bar", "baz") { req in
    ...
}
```

Die Methode kann auch mit einem Rückgabewert versehen werden. Der Rückgabewert muss zwingend vom Typ *ResponseEncodable* sein.

```swift
app.get("foo") { req -> String in
    return "bar"
}
```

Dies sind die unterstützten Endpunkt-Hilfsmethoden:

- `get`
- `post`
- `patch`
- `put`
- `delete`

Neben den HTTP-Methoden-Hilfsmethoden gibt es die Funktion `on`, die die HTTP-Methode als Eingabeparameter entgegennimmt.

```swift
// responds to OPTIONS /foo/bar/baz
app.on(.OPTIONS, "foo", "bar", "baz") { req in
    ...
}
```

### Argumente

Die Endpunktmethoden akzeptieren eine Vielzahl von Argumenten. Es gibt vier Arten davon

- [Konstanten](#konstante)
- [Parameter](#parameter)
- [Sternchen](#sternchen)
- [Doppelsternchen](#doppelsternchen)

#### Konstante

Bei der Konstante handelt es sich um eine statische Angabe. Somit werden von der Methode nur Anfragen mit einem übereinstimmen Pfad angenommen.

```swift
// responds to GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
    ...
}
```

#### Parameter

Beim Parameter handelt sich um eine variable Angabe. Somit werden jegliche Angaben entgegegen genommen. Dem Parameter muss ein Doppelpunkt vorangestellt werden. Die Deklaration nach dem Doppelpunkt steht für den Parameternamen. Mit dem Namen können wir später den Wert abfragen.

```swift
// responds to GET /foo/bar/baz
// responds to GET /foo/qux/baz
// ...
app.get("foo", ":bar", "baz") { req in
    ...
}
```

Wenn wir einen Parameter festlegen, wird der Wert der Angabe in der Eigenschaft *Parameters* auf der Instanz *Request* abgelegt und kann über den Namen abgefragt werden.

```swift
// responds to GET /hello/foo
// responds to GET /hello/bar
// ...
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

!!! tip
    Wir können sicher sein, dass `req.parameters.get` hier niemals `nil` zurückgibt, da unser Endpunktpfad `:name` enthält. Wenn wir jedoch in einer Middleware oder in Code, der von mehreren Endpunkten ausgelöst wird, auf Parameter zugreifen, sollten wir die Möglichkeit von `nil` berücksichtigen.

!!! tip
    Wenn wir URL-Query-Parameter abrufen möchten, z. B. `/hello/?name=foo`, müssen wir Vapors Content-APIs verwenden, um URL-kodierte Daten in der Query-Zeichenfolge der URL zu verarbeiten. Weitere Informationen finden sich in der [`Content`-Referenz](content.md).

`req.parameters.get` unterstützt außerdem automatisch die Umwandlung des Parameters in Typen, die `LosslessStringConvertible` entsprechen.

```swift
// responds to GET /number/42
// responds to GET /number/1337
// ...
app.get("number", ":x") { req -> String in 
    guard let int = req.parameters.get("x", as: Int.self) else {
        throw Abort(.badRequest)
    }
    return "\(int) is a great number"
}
```

#### Sternchen

Für eine beliebige Angabe in einem Pfadabschnitt kann ein einfacher Asterisk angegeben werden. Es verhält sich ähnlich zu einer Parameterangabe, allerdings wird in diesem Fall der Wert verworfen.

```swift
// responds to GET /foo/bar/baz
// responds to GET /foo/qux/baz
// ...
app.get("foo", "*", "baz") { req in
    ...
}
```

#### Doppelsternchen

Für eine beliebige Angabe über mehrere Pfadabschnitte hinweg, können zwei Asterisk angegeben werden.

```swift
// responds to GET /foo/bar
// responds to GET /foo/bar/baz
// ...
app.get("foo", "**") { req in 
    ...
}
```

Werte, die mit dem Pfadabschnitt übereinstimmen werden in der Eigenschaft _parameters_ abgelegt und können mit der Methode _getCatchall(:)_ abgerufen werden. 

```swift
// responds to GET /hello/foo
// responds to GET /hello/foo/bar
// ...
app.get("hello", "**") { req -> String in
    let name = req.parameters.getCatchall().joined(separator: " ")
    return "Hello, \(name)!"
}
```

### Verarbeitung

Wenn wir einen Endpunkt mit der Methode *on(:)* festlegen, können wir definieren, wie mit dem Inhalt umgegangen werden soll. Standardmäßig wird der Inhalt zwischengespeichert, bevor er an den Endpunkt übergeben wird. Das ist hilfreich, da Vapor den Anfrageinhalt nacheinander arbeiten kann, während zeitlgeich neue Anfrage eintreffen.

Vapor hat standardmäßig das Limit auf 16 KB festgelegt. Wir können allerdings den Wert mit der Eigenschaft *Routes* für alle Endpunkte überschreiben:

```swift
// Increases the streaming body collection limit to 500kb
app.routes.defaultMaxBodySize = "500kb"
```

Wenn das Limit erreicht wird, wird ein Fehler 413 (413 Payload Too Lage) ausgeworfen. 

Der Wert kann aber auch für einen einzelnen Endpunkt abgeändert werden. Hierzu müssen wir der Methode beim Parameter *body:* einen Wert mitgeben. Wenn ein neuer Maximalwert mit angegeben wird, wird der Standardwert für den Endpunkt überschrieben.

```swift
// Collects streaming bodies (up to 1mb in size) before calling this route.
app.on(.POST, "listings", body: .collect(maxSize: "1mb")) { req in
    // Handle request. 
}
```

Bei leistungsintensivere Aufgaben, wie zum Beispiel das Hochladen von Dateien, kann das Zwischenspeichern des Inhalts den Arbeitsspeicher stark beanspruchen, daher ist es zu empfehlen, den Inhalt eher zu stream. In dem Fall bleibt *req.body.data* leer und die Daten müssen mit *req.body.drain*  Stück für Stück entgegengenommen werden.

```swift
// Request body will not be collected into a buffer.
app.on(.POST, "upload", body: .stream) { req in
    ...
}
```

### Groß- und Kleinschreibung

Grundsätzlich muss bei Endpunkten die Groß- und Kleinschreibung beachten werden. Bei *Konstanten* kann allerdings eine Ausnahme gemacht werden.

```swift
app.routes.caseInsensitive = true
```

Die ursprüngliche Anfrage bleibt dabei unverändert; die Endpunkt-Handler erhalten die Pfadkomponenten der Anfrage unverändert.

### Ansicht

Über die Eigenschaft *all* kann auf die Endpunkte zugegriffen werden.

```swift
print(app.routes.all) // [Route]
```

Vapor bringt außerdem den Befehl `routes` mit, der alle verfügbaren Endpunkte in einer ASCII-formatierten Tabelle ausgibt.

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

### Metadaten

Alle Endpunktmethoden liefern ein Objekt von Typ *Route* zurück. Damit können wir ihr Metadaten über die Sammlung *userInfo* mitgeben oder andere vordefinierte Methoden verwenden wie zum Beispiel, hinzufügen einer Beschreibung:

```swift
app.get("hello", ":name") { req in
    ...
}.description("says hello")
```

## Endpunktgruppen

Endpunkte können zu Gruppen mit einem gemeinsamen Pfadpräfix oder einer bestimmten Middleware zusammengefasst werden. Die Gruppierung unterstützt sowohl eine Builder- als auch eine Closure-basierte Syntax.

Alle Gruppierungsmethoden liefern einen `RouteBuilder` zurück, sodass sich Gruppen beliebig mit anderen Endpunkt-Methoden mischen, kombinieren und verschachteln lassen.

### Pfadpräfix

Mit einem Pfadpräfix lassen sich einer Gruppe von Endpunkten ein oder mehrere Pfadabschnitte voranstellen.

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

Jede Pfadangabe, die sich auch an Methoden wie `get` oder `post` übergeben lässt, kann ebenso an `grouped` übergeben werden. Alternativ gibt es auch eine Closure-basierte Syntax.

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

### Untergruppen

Gruppen können wiederum verschachteln werden.

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

Gruppen können zudem mit Middlewares versehen werden.

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

Dies ist besonders nützlich, um Teilmengen unserer Endpunkte mit unterschiedlichen Authentifizierungs-Middlewares zu schützen.

```swift
app.post("login") { ... }
let auth = app.grouped(AuthMiddleware())
auth.get("dashboard") { ... }
auth.get("logout") { ... }
```

## Weiterleitung

Weiterleitungen sind in vielen Fällen nützlich, etwa um alte Adressen aus SEO-Gründen auf neue umzuleiten, einen nicht authentifizierten Benutzer zur Login-Seite weiterzuleiten oder die Abwärtskompatibilität mit einer neuen Version der eigenen API zu wahren.

Um eine Anfrage weiterzuleiten, verwenden wir:

```swift
req.redirect(to: "/some/new/path")
```

Wir können auch die Art der Weiterleitung angeben, zum Beispiel um eine Seite dauerhaft weiterzuleiten (damit die SEO korrekt aktualisiert wird):

```swift
req.redirect(to: "/some/new/path", redirectType: .permanent)
```

Folgende `Redirect`-Arten stehen zur Verfügung:

* `.permanent` - liefert eine **301 Permanent**-Weiterleitung
* `.normal` - liefert eine **303 see other**-Weiterleitung. Dies ist die Standardeinstellung von Vapor und weist den Client an, der Weiterleitung mit einer **GET**-Anfrage zu folgen.
* `.temporary` - liefert eine **307 Temporary**-Weiterleitung. Dies weist den Client an, die in der Anfrage verwendete HTTP-Methode beizubehalten.

> Informationen zur Wahl des passenden Weiterleitungsstatuscodes gibt es in [der vollständigen Liste](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes#3xx_redirection)