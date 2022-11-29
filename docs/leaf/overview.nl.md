# Leaf Overzicht

Leaf is een krachtige templating taal met een op Swift geïnspireerde syntax. U kunt het gebruiken om dynamische HTML-pagina's te genereren voor een front-end website of om rijke e-mails te genereren om te verzenden vanuit een API.

Deze gids zal u een overzicht geven van de syntax van Leaf en de beschikbare tags.

## Template syntax

Hier is een voorbeeld van een basisgebruik van een Leaf tag.

```leaf
There are #count(users) users.
```

Leaf tags bestaan uit vier elementen::

- Token `#`: Dit geeft de leaf parser het signaal om te beginnen zoeken naar een tag.
- Naam `count`: die de tag identificeert.
- Parameter Lijst `(users)`: Kan nul of meer argumenten aanvaarden.
- Body: Een optionele body kan aan sommige tags worden toegevoegd met behulp van een puntkomma en een afsluitende tag

Er kunnen veel verschillende toepassingen zijn voor deze vier elementen, afhankelijk van de implementatie van de tag. Laten we eens kijken naar een paar voorbeelden van hoe de ingebouwde tags van Leaf gebruikt kunnen worden:

```leaf
#(variable)
#extend("template"): I'm added to a base template! #endextend
#export("title"): Welcome to Vapor #endexport
#import("body")
#count(friends)
#for(friend in friends): <li>#(friend.name)</li> #endfor
```

Leaf ondersteunt ook veel uitdrukkingen die je kent van Swift.

- `+`
- `%`
- `>`
- `==`
- `||`
- etc.

```leaf
#if(1 + 1 == 2):
    Hello!
#endif

#if(index % 2 == 0):
    This is even index.
#else:
    This is odd index.
#endif
```

## Context

In het voorbeeld uit [Getting Started](./getting-started.md), hebben we een `[String: String]` woordenboek gebruikt om gegevens door te geven aan Leaf. Je kunt echter alles doorgeven dat voldoet aan `Encodable`. Het is zelfs beter om `Encodable` structs te gebruiken, omdat `[String: Any]` niet ondersteund wordt. Dit betekent dat je *geen* array kunt doorgeven, en het in plaats daarvan moet verpakken in een struct:

```swift
struct WelcomeContext: Encodable {
    var title: String
    var numbers: [Int]
}
return req.view.render("home", WelcomeContext(title: "Hello!", numbers: [42, 9001]))
```

Dat zal `title` en `numbers` aan ons Leaf sjabloon laten zien, die dan in tags gebruikt kunnen worden. Bijvoorbeeld:

```leaf
<h1>#(title)</h1>
#for(number in numbers):
    <p>#(number)</p>
#endfor
```

## Gebruik

Hier zijn enkele veel voorkomende gebruiksvoorbeelden van Leaf.

### Condities

Leaf kan een reeks voorwaarden evalueren met de `#if` tag. Bijvoorbeeld, als je een variabele opgeeft, zal het controleren of die variabele bestaat in zijn context:

```leaf
#if(title):
    The title is #(title)
#else:
    No title was provided.
#endif
```

Je kunt ook vergelijkingen schrijven, bijvoorbeeld:

```leaf
#if(title == "Welcome"):
    This is a friendly web page.
#else:
    No strangers allowed!
#endif
```

Als je een andere tag wilt gebruiken als onderdeel van je voorwaarde, moet je de `#` voor de binnenste tag weglaten. Bijvoorbeeld:

```leaf
#if(count(users) > 0):
    You have users!
#else:
    There are no users yet :(
#endif
```

Je kunt ook `#elseif` statements gebruiken:

```leaf
#if(title == "Welcome"):
    Hello new user!
#elseif(title == "Welcome back!"):
    Hello old user
#else:
    Unexpected page!
#endif
```

### Loops

Als je een array van items opgeeft, kan Leaf er een loop overheen maken en je elk item afzonderlijk laten manipuleren met de `#for` tag.

We zouden bijvoorbeeld onze Swift code kunnen bijwerken om een lijst van planeten te geven:

```swift
struct SolarSystem: Codable {
    let planets = ["Venus", "Earth", "Mars"]
}

return req.view.render("solarSystem", SolarSystem())
```

We kunnen er dan over loopen in Leaf zoals dit:

```leaf
Planets:
<ul>
#for(planet in planets):
    <li>#(planet)</li>
#endfor
</ul>
```

Dit zou een view opleveren dat er zo uitziet:

```
Planets:
- Venus
- Earth
- Mars
```

### Templates Uitbreiden

Leaf's `#extend` tag maakt het mogelijk om de inhoud van een template naar een ander te kopiëren. Wanneer je deze tag gebruikt, moet je altijd de .leaf extensie van het sjabloonbestand weglaten.

Uitbreiden is handig voor het kopiëren van een standaard stuk inhoud, bijvoorbeeld een pagina voettekst, advertentie code of tabel die gedeeld wordt over meerdere pagina's:

```leaf
#extend("footer")
```

Deze tag is ook nuttig voor het bouwen van een sjabloon bovenop een ander. Je zou bijvoorbeeld een layout.leaf bestand kunnen hebben dat alle code bevat die nodig is om je website op te maken - HTML structuur, CSS en JavaScript - met enkele gaten op zijn plaats die weergeven waar de pagina-inhoud varieert.

Met deze aanpak maakt u een child template dat zijn unieke inhoud invult, en vervolgens breidt u het parent template uit dat de inhoud op de juiste manier plaatst. Om dit te doen, kun je de `#export` en `#import` tags gebruiken om inhoud op te slaan en later weer op te halen uit de context.

Bijvoorbeeld, je zou een `child.leaf` template als volgt kunnen maken:

```leaf
#extend("master"):
    #export("body"):
        <p>Welcome to Vapor!</p>
    #endexport
#endextend
```

We roepen `#export` aan om wat HTML op te slaan en beschikbaar te maken voor het template dat we nu aan het uitbreiden zijn. We renderen dan `master.leaf` en gebruiken de geëxporteerde data wanneer nodig, samen met andere context variabelen die zijn doorgegeven door Swift. Bijvoorbeeld, `master.leaf` zou er zo uit kunnen zien:

```leaf
<html>
    <head>
        <title>#(title)</title>
    </head>
    <body>#import("body")</body>
</html>
```

Hier gebruiken we `#import` om de inhoud van de `#extend` tag op te halen. Wanneer `["title": "Hi there!"]` van Swift wordt doorgegeven, zal `child.leaf` als volgt renderen:

```html
<html>
    <head>
        <title>Hi there!</title>
    </head>
    <body><p>Welcome to Vapor!</p></body>
</html>
```

### Andere tags

#### `#count`

De `#count` tag geeft het aantal items in een array. Bijvoorbeeld:

```leaf
Your search matched #count(matches) pages.
```

#### `#lowercased`

De `#lowercased` tag maakt alle letters in een string lowercased.

```leaf
#lowercased(name)
```

#### `#uppercased`

De `#uppercased` tag maakt alle letters in een string hoofdletters.

```leaf
#uppercased(name)
```

#### `#capitalized`

De `#capitalized` tag maakt de eerste letter in elk woord van een string hoofdletter en de andere kleine letters. Zie [`String.capitalized`](https://developer.apple.com/documentation/foundation/nsstring/1416784-capitalized) voor meer informatie.

```leaf
#capitalized(name)
```

#### `#contains`

De `#contains` tag accepteert een array en een waarde als zijn twee parameters, en geeft true terug als de array in parameter één de waarde in parameter twee bevat.

```leaf
#if(contains(planets, "Earth")):
    Earth is here!
#else:
    Earth is not in this array.
#endif
```

#### `#date`

Het `#date` label formatteert datums in een leesbare string. Standaard gebruikt het de ISO8601 opmaak.

```swift
render(..., ["now": Date()])
```

```leaf
The time is #date(now)
```

Je kunt een aangepaste datum formatter string doorgeven als tweede argument. Zie Swift's [`DateFormatter`](https://developer.apple.com/documentation/foundation/dateformatter) voor meer informatie.

```leaf
The date is #date(now, "yyyy-MM-dd")
```

#### `#unsafeHTML`

De `#unsafeHTML` tag werkt als een variabele tag - b.v. `#(variabele)`. Het ontsnapt echter niet aan de HTML die `variabele` kan bevatten:

```leaf
The time is #unsafeHTML(styledTitle)
```

!!! note "Opmerking"
    Je moet voorzichtig zijn met het gebruik van deze tag om er zeker van te zijn dat de variabele die je meegeeft je gebruikers niet blootstelt aan een XSS-aanval.

#### `#dumpContext`

De `#dumpContext` tag geeft de hele context weer in een door mensen leesbare string. Gebruik deze tag om te debuggen wat er wordt
wordt geleverd als context voor de huidige rendering.

```leaf
Hello, world!
#dumpContext
```
