# Routing

Routing is het proces van het vinden van de juiste request handler voor een inkomend verzoek. De kern van Vapor's routering is een krachtige, trie-node router van [RoutingKit](https://github.com/vapor/routing-kit).

## Overview 

Om te begrijpen hoe routing werkt in Vapor, moet je eerst een paar basisbegrippen over HTTP verzoeken begrijpen. Kijk eens naar het volgende voorbeeld verzoek.

```http
GET /hello/vapor HTTP/1.1
host: vapor.codes
content-length: 0
```

Dit is een eenvoudig `GET` HTTP verzoek naar de URL `/hello/vapor`. Dit is het soort HTTP verzoek dat uw browser zou maken als u hem op de volgende URL zou richten.

```
http://vapor.codes/hello/vapor
```

### HTTP Method

Het eerste deel van het verzoek is de HTTP methode. `GET` is de meest voorkomende HTTP methode, maar er zijn er meerdere die je vaak zult gebruiken. Deze HTTP methodes worden vaak geassocieerd met [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) semantiek.

|Method|CRUD|
|-|-|
|`GET`|Lezen|
|`POST`|Maken|
|`PUT`|Vervangen|
|`PATCH`|Updaten|
|`DELETE`|Verwijderen|

### Request Path

Direct na de HTTP methode staat de URI van het verzoek. Deze bestaat uit een pad dat begint met `/` en een optionele query string na `?`. De HTTP methode en het pad zijn wat Vapor gebruikt om verzoeken te routeren.

Na de URI volgt de HTTP versie, gevolgd door nul of meer headers en tenslotte een body. Omdat dit een `GET` verzoek is, heeft het geen body.

### Router Methodes

Laten we eens kijken hoe dit verzoek in Vapor zou kunnen worden behandeld.

```swift
app.get("hello", "vapor") { req in 
    return "Hello, vapor!"
}
```

Alle gebruikelijke HTTP methodes zijn beschikbaar als methodes op `Application`. Ze accepteren een of meer string argumenten die het pad van het verzoek weergeven, gescheiden door `/`. 

Merk op dat je dit ook zou kunnen schrijven met `on` gevolgd door de methode.

```swift
app.on(.GET, "hello", "vapor") { ... }
```

Met deze route geregistreerd, zal het voorbeeld HTTP verzoek van hierboven resulteren in het volgende HTTP antwoord.

```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, vapor!
```

### Route Parameters

Nu we met succes een verzoek hebben gerouteerd op basis van de HTTP methode en het pad, laten we eens proberen het pad dynamisch te maken. Merk op dat de naam "vapor" hard gecodeerd is in zowel het pad als het antwoord. Laten we dit dynamisch maken, zodat je `/hello/<elke naam>` kunt bezoeken en een antwoord kunt krijgen.

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

Door het gebruik van een path component voorafgegaan door `:`, geven we aan de router aan dat dit een dynamische component is. Elke string die hier wordt aangeleverd zal nu overeenkomen met deze route. We kunnen dan `req.parameters` gebruiken om de waarde van de string op te vragen.

Als je het voorbeeld verzoek opnieuw uitvoert, krijg je nog steeds een antwoord dat hallo zegt tegen Vapor. U kunt nu echter elke naam na `/hello/` invoegen en het in het antwoord zien staan. Laten we `/hello/swift` eens proberen.

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

Nu dat je de basis begrijpt, bekijk dan elke sectie om meer te leren over parameters, groepen, en meer.

## Routes

Een route specificeert een request handler voor een gegeven HTTP methode en URI pad. Het kan ook extra metadata opslaan.

### Methods

Routes kunnen direct worden geregistreerd in uw `Application` met behulp van verschillende HTTP methode helpers. 

```swift
// responds to GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
	...
}
```

Route handlers ondersteunen het retourneren van alles dat `ResponseEncodable` is. Dit is inclusief `Content`, een `async` closure, en elke `EventLoopFuture` waar de toekomstige waarde `ResponseEncodable` is.

Je kunt het return type van een route specificeren met `-> T` voor `in`. Dit kan handig zijn in situaties waar de compiler het return type niet kan bepalen.

```swift
app.get("foo") { req -> String in
	return "bar"
}
```

Dit zijn de ondersteunde route helper methodes:

- `get`
- `post`
- `patch`
- `put`
- `delete`

Naast de HTTP methode helpers, is er een `on` functie die HTTP methode accepteert als een input parameter. 

```swift
// reageert op OPTIONS /foo/bar/baz
app.on(.OPTIONS, "foo", "bar", "baz") { req in
	...
}
```

### Path Component

Elke route registratie methode accepteert een variadische lijst van `PathComponent`. Dit type is uit te drukken door string literal en heeft vier gevallen:

- Constante (`foo`)
- Parameter (`:foo`)
- Alles (`*`)
- CatchAll (`**`)

#### Constant

Dit is een statische routecomponent. Alleen verzoeken met een exact overeenkomende string op deze positie worden toegestaan.

```swift
// reageert op GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
	...
}
```

#### Parameter

Dit is een dynamische routecomponent. Elke string op deze positie is toegestaan. Een parameter path component wordt gespecificeerd met een `:` prefix. De string achter de `:` wordt gebruikt als parameter naam. Je kunt de naam gebruiken om later de waarde van de parameter uit het request te halen.

```swift
// reageert op GET /foo/bar/baz
// reageert op GET /foo/qux/baz
// ...
app.get("foo", ":bar", "baz") { req in
	...
}
```

#### Alles

Dit lijkt veel op parameter, behalve dat de waarde wordt weggegooid. Deze path component wordt gespecificeerd als alleen `*`. 

```swift
// reageert op GET /foo/bar/baz
// reageert op GET /foo/qux/baz
// ...
app.get("foo", "*", "baz") { req in
	...
}
```

#### CatchAll

Dit is een dynamische routecomponent die overeenkomt met een of meer componenten. Het wordt gespecificeerd met alleen `**`. Elke string op deze positie of latere posities zal worden gematched in het verzoek. 

```swift
// reageert op GET /foo/bar
// reageert op GET /foo/bar/baz
// ...
app.get("foo", "**") { req in 
    ...
}
```

### Parameters

Bij gebruik van een parameter path component (voorafgegaan door `:`), zal de waarde van de URI op die positie worden opgeslagen in `req.parameters`. U kunt de naam van de path component gebruiken om de waarde te benaderen. 

```swift
// reageert op GET /hello/foo
// reageert op GET /hello/bar
// ...
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

!!! tip
    We kunnen er zeker van zijn dat `req.parameters.get` hier nooit `nil` zal teruggeven, omdat ons route pad `:name` bevat. Echter, als u route parameters benadert in middleware of in code die getriggerd wordt door meerdere routes, zult u de mogelijkheid van `nil` willen behandelen.

!!! tip
    Als je URL query params wilt ophalen, bijvoorbeeld `/hello/?name=foo` moet je Vapor's Content APIs gebruiken om URL gecodeerde data in de URL's query string te verwerken. Zie [`Content` referentie](/content/) voor meer details.

`req.parameters.get` ondersteunt ook het automatisch casten van de parameter naar `LosslessStringConvertible` types. 

```swift
// reageert op GET /number/42
// reageert op GET /number/1337
// ...
app.get("number", ":x") { req -> String in 
	guard let int = req.parameters.get("x", as: Int.self) else {
		throw Abort(.badRequest)
	}
	return "\(int) is a great number"
}
```

De waarden van de door CatchAll gematchte URI (`**`) worden in `req.parameters` opgeslagen als `[String]`. Je kunt `req.parameters.getCatchall` gebruiken om toegang te krijgen tot deze componenten. 

```swift
// reageert op GET /hello/foo
// reageert op GET /hello/foo/bar
// ...
app.get("hello", "**") { req -> String in
    let name = req.parameters.getCatchall().joined(separator: " ")
    return "Hello, \(name)!"
}
```

### Body Streaming

Wanneer je een route registreert met de `on` methode, kun je specificeren hoe de request body behandeld moet worden. Standaard worden request bodies in het geheugen verzameld voordat je je handler aanroept. Dit is handig omdat het mogelijk maakt om de request inhoud synchroon te decoderen, ook al leest uw applicatie inkomende requests asynchroon. 

Standaard zal Vapor het verzamelen van streaming body's beperken tot 16KB in grootte. U kunt dit configureren met `app.routes`.

```swift
// Verhoogt de limiet voor het verzamelen van streaming body collectie tot 500kb
app.routes.defaultMaxBodySize = "500kb"
```

Als een streaming body die wordt verzameld de geconfigureerde limiet overschrijdt, zal een `413 Payload Too Large` foutmelding worden gegeven.

Om de request body collectie strategie te configureren voor een individuele route, gebruik de `body` parameter.

```swift
// Verzamelt streaming bodies (tot 1mb groot) voordat deze route wordt aangeroepen.
app.on(.POST, "listings", body: .collect(maxSize: "1mb")) { req in
    // Verzoek afhandelen. 
}
```

Als een `maxSize` wordt doorgegeven aan `collect`, zal het de standaard van de applicatie voor die route overschrijven. Om de standaard van de applicatie te gebruiken, laat je het `maxSize` argument weg. 

Voor grote requests, zoals file uploads, kan het verzamelen van de request body in een buffer het systeemgeheugen belasten. Om te voorkomen dat de request body wordt verzameld, kunt u de `stream` strategie gebruiken.

```swift
// De inhoud van het verzoek wordt niet in een buffer verzameld.
app.on(.POST, "upload", body: .stream) { req in
    ...
}
```

Wanneer de request body wordt gestreamd, zal `req.body.data` `nil` zijn. Je moet `req.body.drain` gebruiken om elke chunk af te handelen als deze naar je route wordt gestuurd.

### Hoofdletterongevoelige routering

Standaard gedrag voor routing is zowel hoofdlettergevoelig als hoofdletterbehoudend. `Constante` padcomponenten kunnen afwisselend hoofdletterongevoelig en hoofdletterbehoudend worden behandeld voor de routering; om dit gedrag in te schakelen, configureer dit voor het opstarten van de applicatie:
```swift
app.routes.caseInsensitive = true
```
Er worden geen wijzigingen aangebracht aan het oorspronkelijke verzoek; de routebehandelaars ontvangen de onderdelen van het verzoekpad zonder wijziging.


### Routes Bekijken

U kunt de routes van uw applicatie benaderen door de `Routes` service te maken of door `app.routes` te gebruiken.

```swift
print(app.routes.all) // [Route]
```

Vapor wordt ook geleverd met een `routes` commando dat alle beschikbare routes afdrukt in een ASCII geformatteerde tabel. 

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

### Metadata

Alle route registratie methodes retourneren de aangemaakte `Route`. Hiermee kun je metadata toevoegen aan de `userInfo` dictionary van de route. Er zijn enkele standaard methodes beschikbaar, zoals het toevoegen van een beschrijving.

```swift
app.get("hello", ":name") { req in
	...
}.description("says hello")
```

## Route Groepen

Route groepering maakt het mogelijk om een set van routes te maken met een pad voorvoegsel of specifieke middleware. Grouperen ondersteunt een builder en closure gebaseerde syntax.

Alle groepering methoden retourneren een `RouteBuilder` wat betekent dat je oneindig kunt mixen, matchen, en nesten met andere route bouw methoden.

### Pad Voorvoegsel

Pad voorvoegsel route groepen staan u toe om een of meer path componenten aan een groep van routes te prependeren. 

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

Elke pad component die je kunt doorgeven aan methodes als `get` of `post` kan worden doorgegeven aan `grouped`. Er is ook een alternatieve, closure-gebaseerde syntax.

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

Door het nesten van pad voorvoegsel route groepen kunt u beknopt CRUD APIs definiëren.

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

Naast het prefixen van padcomponenten, kunt u ook middleware toevoegen aan routegroepen. 

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

Dit is vooral nuttig voor het beschermen van subsets van uw routes met verschillende authenticatie middleware. 

```swift
app.post("login") { ... }
let auth = app.grouped(AuthMiddleware())
auth.get("dashboard") { ... }
auth.get("logout") { ... }
```

## Omleidingen

Omleidingen zijn nuttig in een aantal scenario's, zoals het doorsturen van oude locaties naar nieuwe voor SEO, het doorsturen van een niet-geauthenticeerde gebruiker naar de login pagina of het behouden van achterwaartse compatibiliteit met de nieuwe versie van uw API.

Om een verzoek om te leiden, gebruik:

```swift
req.redirect(to: "/some/new/path")
```

U kunt ook het type omleiding specificeren, bijvoorbeeld om een pagina permanent om te leiden (zodat uw SEO correct wordt bijgewerkt) gebruiken we:

```swift
req.redirect(to: "/some/new/path", type: .permanent)
```

De verschillende `RedirectType`s zijn:

* `.permanent` - geeft een **301 Permanent** omleiding.
* `.normal` - retourneert een **303 see other** redirect. Dit is de standaard door Vapor en vertelt de client om de omleiding te volgen met een **GET** verzoek.
* `.temporary` - retourneert een **307 temporary** redirect. Dit vertelt de client om de HTTP methode gebruikt in het verzoek te behouden.

> Bekijk [de volledige lijst](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes#3xx_redirection) om de juiste omleidingsstatuscode te kiezen.
