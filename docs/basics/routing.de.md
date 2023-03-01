# Routing

Beim Routing geht es um das Verteilen der eingehenden Serveranfragen, an die richtigen Anwendungsendpunkte. Endpunkte sind Einheiten zur Verarbeitung der Anfragen. Sie werden im Controller definiert und beim Starten der Anwendung registriert.

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

### Endpunkte

Vapor stellt alle Anfragemethoden als Methoden über die Application-Instanz zur Verfügung. Die Methoden akzeptieren einen oder mehrere Pfadangaben vom Typ _String_, die nachfolgend mit einem '/' getrennt zu einem Pfad zusammengestellt werden.

Beispiel:

```swift
/// [controller.swift]

app.get("hello", "vapor") { req in 
    return "Hello, vapor!"
}

/// Die .on()-Variante ist ebenfalls möglich.
app.on(.GET, "hello", "vapor") { ... }
```

Ergebnis:

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

### Methoden

Endpunkte können der Anwendung über die Instanz _Application_ und den Methoden bekannt gemacht werden.

Beispiel:
```swift
// [controllers.swift]

app.get("foo", "bar", "baz") { req in
	...
}
```

Die Methode kann auch mit einem Rückgabewert versehen werden. Der Rückgabewert muss zwingend vom Typ *ResponseEncodable* sein. Das betrifft [Content](), jede Asyncklammer und jede EventLoopFuture, deren Wert vom Typ *ResponseEncodable* ist. Wir können den Rückgabewert einer Methode festlegen, indem. Das kann in Situation hilfreich sein, in denen der Compiler den Wert nicht bestimmen kann. 

```swift
app.get("foo") { req -> String in
	return "bar"
}
```

```swift
// responds to OPTIONS /foo/bar/baz
app.on(.OPTIONS, "foo", "bar", "baz") { req in
	...
}
```

### Argumente

Die Endpunktmethoden akzeptieren eine Vielzahl von Argumenten. Es gibt vier Arten davon

- [Konstanten](#constant)
- [Parameter](#parameter)
- [Anything](#anything)
- [Catchall](#catchall)

#### Konstante

Bei der Konstante handelt es sich um eine statische Angabe. Somit werden von der Methode nur Anfragen mit einem übereinstimmen Pfad angenommen.

```swift
// responds to GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
	...
}
```

#### Parameter

Beim Parameter handelt sich um eine variable Angabe. Somit werden jegliche Angaben entgegegen genommen. Dem Parameter muss ein *:* vorangesetzt werden. Die Deklaration nach dem Doppelpunkt steht für den Parameternamen. Mit dem Namen können wir später den Wert abfragen.

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
    We can be sure that `req.parameters.get` will never return `nil` here since our route path includes `:name`. However, if you are accessing route parameters in middleware or in code triggered by multiple routes, you will want to handle the possibility of `nil`.

!!! tip
    If you want to retrieve URL query params, e.g. `/hello/?name=foo` you need to use Vapor's Content APIs to handle URL encoded data in the URL's query string. See [`Content` reference](/content/) for more details.

`req.parameters.get` also supports casting the parameter to `LosslessStringConvertible` types automatically. 

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

Asterisk verhält sich ähnlich zu den Parametern, allerdings wird der Wert verworfen.

```swift
// responds to GET /foo/bar/baz
// responds to GET /foo/qux/baz
// ...
app.get("foo", "*", "baz") { req in
	...
}
```

#### Doppelsternchen

Beim Catchall handelt es sich um eine variable Angabe.

```swift
// responds to GET /foo/bar
// responds to GET /foo/bar/baz
// ...
app.get("foo", "**") { req in 
    ...
}
```

The values of the URI matched by Catchall (`**`) will be stored in `req.parameters` as `[String]`. You can use `req.parameters.getCatchall` to access those components. 

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

Wenn wir einen Endpunkt mit der Methode *on(_:)* festlegen, können wir definieren, wie mit dem Inhalt umgegangen werden soll. Standardmäßig wird der Inhalt zwischengespeichert, bevor er an den Endpunkt übergeben wird. Das ist hilfreich, da Vapor den Anfrageinhalt nacheinander arbeiten kann, während zeitlgeich neue Anfrage eintreffen.

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
/// [configure.swift]

app.routes.caseInsensitive = true
```

### Ansicht

Über die Eigenschaft *all* kann auf die Endpunkte zugegriffen werden.

```swift
print(app.routes.all) // [Route]
```

Vapor also ships with a `routes` command that prints all available routes in an ASCII formatted table. 

```sh
$ swift run Run routes
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

Endpunkte können zu Gruppen zusammengefasst werden.

### Pfadabschnitt

Mit einem Pfadabschnitt können wir Endpunkte zu einer Gruppe zusammenfassen. Der Name der Gruppe wird als Pfadabschnitt den enhaltenen Endpunkten vorangestellt.

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

Gruppen können mit [Middlewwares]() versehen werden.

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

```swift
app.post("login") { ... }
let auth = app.grouped(AuthMiddleware())
auth.get("dashboard") { ... }
auth.get("logout") { ... }
```

## Weiterleitung

Für eine Weiterleitung kann es verschiedenste Gründe geben. Mit der Methode *redirect(_:)* über die Instanz *Request*. können wir die Anfrage weiterleiten.

```swift

req.redirect(to: "/some/new/path")

/// redirect a page permanently
req.redirect(to: "/some/new/path", type: .permanent)
```

Es gibt verschiedene Arten von Weiterleitungen:

|Art      |Statuscode |Beschreibung                                                                                                                           |
|---------|---|---------------------------------------------------------------------------------------------------------------------------------------|
|permanent|301| Liefert einen Statuscode 301 zurück.  |
|normal   |303| This is the default by Vapor and tells the client to follow the redirect with a **GET** request. |
|temporary|307| This tells the client to preserve the HTTP method used in the request.|
|To choose the proper redirection status code check out [the full list](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes#3xx_redirection)|