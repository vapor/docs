# Leaf Überblick

Leaf ist eine leistungsstarke Template-Sprache mit einer an Swift angelehnten Syntax. Du kannst sie verwenden, um dynamische HTML-Seiten für eine Frontend-Website zu erzeugen oder um umfangreiche E-Mails zu generieren, die von einer API aus versendet werden.

Diese Anleitung gibt dir einen Überblick über die Syntax von Leaf und die verfügbaren Tags.

## Template-Syntax

Hier ist ein Beispiel für die grundlegende Verwendung eines Leaf-Tags.

```leaf
There are #count(users) users.
```

Leaf-Tags bestehen aus vier Elementen:

- Token `#`: Dieses signalisiert dem Leaf-Parser, mit der Suche nach einem Tag zu beginnen.
- Name `count`: identifiziert den Tag.
- Parameterliste `(users)`: Kann null oder mehr Argumente akzeptieren.
- Body: Manchen Tags kann optional ein Body mittels eines Doppelpunkts und eines schließenden Tags übergeben werden

Abhängig von der Implementierung des jeweiligen Tags gibt es viele unterschiedliche Verwendungsmöglichkeiten dieser vier Elemente. Schauen wir uns ein paar Beispiele an, wie die integrierten Tags von Leaf verwendet werden können:

```leaf
#(variable)
#extend("template"): I'm added to a base template! #endextend
#export("title"): Welcome to Vapor #endexport
#import("body")
#count(friends)
#for(friend in friends): <li>#(friend.name)</li> #endfor
```

Leaf unterstützt außerdem viele Ausdrücke, die dir aus Swift bekannt sind.

- `+`
- `%`
- `>`
- `==`
- `||`
- usw.

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

Im Beispiel aus [Erste Schritte](getting-started.md) haben wir ein `[String: String]`-Dictionary verwendet, um Daten an Leaf zu übergeben. Du kannst jedoch alles übergeben, was `Encodable` konformiert. Tatsächlich ist es vorzuziehen, `Encodable`-Structs zu verwenden, da `[String: Any]` nicht unterstützt wird. Das bedeutet, dass du *kein* Array übergeben kannst und es stattdessen in eine Struct einpacken solltest:

```swift
struct WelcomeContext: Encodable {
    var title: String
    var numbers: [Int]
}
return req.view.render("home", WelcomeContext(title: "Hello!", numbers: [42, 9001]))
```

Dadurch werden `title` und `numbers` unserem Leaf-Template zur Verfügung gestellt, die anschließend innerhalb von Tags verwendet werden können. Zum Beispiel:

```leaf
<h1>#(title)</h1>
#for(number in numbers):
    <p>#(number)</p>
#endfor
```

## Verwendung

Hier sind einige gängige Anwendungsbeispiele für Leaf.

### Bedingungen

Leaf ist in der Lage, mit seinem `#if`-Tag eine Reihe von Bedingungen auszuwerten. Wenn du zum Beispiel eine Variable angibst, prüft es, ob diese Variable in seinem Context existiert:

```leaf
#if(title):
    The title is #(title)
#else:
    No title was provided.
#endif
```

Du kannst auch Vergleiche schreiben, zum Beispiel:

```leaf
#if(title == "Welcome"):
    This is a friendly web page.
#else:
    No strangers allowed!
#endif
```

Wenn du einen anderen Tag als Teil deiner Bedingung verwenden möchtest, solltest du das `#` beim inneren Tag weglassen. Zum Beispiel:

```leaf
#if(count(users) > 0):
    You have users!
#else:
    There are no users yet :(
#endif
```

Du kannst auch `#elseif`-Anweisungen verwenden:

```leaf
#if(title == "Welcome"):
    Hello new user!
#elseif(title == "Welcome back!"):
    Hello old user
#else:
    Unexpected page!
#endif
```

### Schleifen

Wenn du ein Array von Elementen bereitstellst, kann Leaf mit seinem `#for`-Tag darüber iterieren und dir erlauben, jedes Element einzeln zu bearbeiten.

Zum Beispiel könnten wir unseren Swift-Code so anpassen, dass er eine Liste von Planeten bereitstellt:

```swift
struct SolarSystem: Codable {
    let planets = ["Venus", "Earth", "Mars"]
}

return req.view.render("solarSystem", SolarSystem())
```

Anschließend könnten wir in Leaf so darüber iterieren:

```leaf
Planets:
<ul>
#for(planet in planets):
    <li>#(planet)</li>
#endfor
</ul>
```

Dies würde eine Ansicht rendern, die folgendermaßen aussieht:

```
Planets:
- Venus
- Earth
- Mars
```

### Templates erweitern

Der `#extend`-Tag von Leaf erlaubt es dir, den Inhalt eines Templates in ein anderes zu kopieren. Bei der Verwendung solltest du immer die `.leaf`-Dateiendung des Template-Files weglassen.

Das Erweitern ist nützlich, um einen standardmäßigen Inhalt zu kopieren, zum Beispiel eine Seiten-Fußzeile, Werbecode oder eine Tabelle, die von mehreren Seiten gemeinsam genutzt wird:

```leaf
#extend("footer")
```

Dieser Tag ist auch nützlich, um ein Template auf einem anderen aufzubauen. Du könntest zum Beispiel eine layout.leaf-Datei haben, die den gesamten Code enthält, der benötigt wird, um deine Website aufzubauen – HTML-Struktur, CSS und JavaScript –, mit einigen Lücken, die anzeigen, wo sich der Seiteninhalt unterscheidet.

Mit diesem Ansatz würdest du ein Kind-Template erstellen, das seinen eigenen Inhalt einfügt und dann das Eltern-Template erweitert, das den Inhalt entsprechend platziert. Dazu kannst du die Tags `#export` und `#import` verwenden, um Inhalt im Context zu speichern und später abzurufen.

Zum Beispiel könntest du ein `child.leaf`-Template wie folgt erstellen:

```leaf
#extend("main"):
    #export("body"):
        <p>Welcome to Vapor!</p>
    #endexport
#endextend
```

Wir rufen `#export` auf, um etwas HTML zu speichern und es für das Template verfügbar zu machen, das wir gerade erweitern. Anschließend rendern wir `main.leaf` und verwenden die exportierten Daten bei Bedarf zusammen mit allen anderen aus Swift übergebenen Context-Variablen. Zum Beispiel könnte `main.leaf` folgendermaßen aussehen:

```leaf
<html>
    <head>
        <title>#(title)</title>
    </head>
    <body>#import("body")</body>
</html>
```

Hier verwenden wir `#import`, um den Inhalt abzurufen, der an den `#extend`-Tag übergeben wurde. Wenn `["title": "Hi there!"]` aus Swift übergeben wird, rendert `child.leaf` wie folgt:

```html
<html>
    <head>
        <title>Hi there!</title>
    </head>
    <body><p>Welcome to Vapor!</p></body>
</html>
```

### Weitere Tags

#### `#count`

Der `#count`-Tag gibt die Anzahl der Elemente in einem Array zurück. Zum Beispiel:

```leaf
Your search matched #count(matches) pages.
```

#### `#lowercased`

Der `#lowercased`-Tag wandelt alle Buchstaben einer Zeichenkette in Kleinbuchstaben um.

```leaf
#lowercased(name)
```

#### `#uppercased`

Der `#uppercased`-Tag wandelt alle Buchstaben einer Zeichenkette in Großbuchstaben um.

```leaf
#uppercased(name)
```

#### `#capitalized`

Der `#capitalized`-Tag wandelt den ersten Buchstaben jedes Wortes einer Zeichenkette in einen Großbuchstaben um und die übrigen Buchstaben in Kleinbuchstaben. Weitere Informationen findest du unter [`String.capitalized`](https://developer.apple.com/documentation/foundation/nsstring/1416784-capitalized).

```leaf
#capitalized(name)
```

#### `#contains`

Der `#contains`-Tag akzeptiert ein Array und einen Wert als seine beiden Parameter und gibt `true` zurück, wenn das Array im ersten Parameter den Wert im zweiten Parameter enthält.

```leaf
#if(contains(planets, "Earth")):
    Earth is here!
#else:
    Earth is not in this array.
#endif
```

#### `#date`

Der `#date`-Tag formatiert Daten in eine lesbare Zeichenkette. Standardmäßig verwendet er die ISO8601-Formatierung.

```swift
render(..., ["now": Date()])
```

```leaf
The time is #date(now)
```

Du kannst als zweites Argument eine benutzerdefinierte Formatierungszeichenkette für das Datum übergeben. Weitere Informationen findest du in Swifts [`DateFormatter`](https://developer.apple.com/documentation/foundation/dateformatter).

```leaf
The date is #date(now, "yyyy-MM-dd")
```

Du kannst dem Datumsformatierer außerdem als drittes Argument eine Zeitzonen-ID übergeben. Weitere Informationen findest du in Swifts [`DateFormatter.timeZone`](https://developer.apple.com/documentation/foundation/dateformatter/1411406-timezone) und [`TimeZone`](https://developer.apple.com/documentation/foundation/timezone).

```leaf
The date is #date(now, "yyyy-MM-dd", "America/New_York")
```

#### `#unsafeHTML`

Der `#unsafeHTML`-Tag verhält sich wie ein Variablen-Tag – z. B. `#(variable)`. Allerdings escaped er kein HTML, das `variable` enthalten könnte:

```leaf
The time is #unsafeHTML(styledTitle)
```

!!! note
    Du solltest bei der Verwendung dieses Tags darauf achten, dass die Variable, die du ihm übergibst, deine Benutzer keinem XSS-Angriff aussetzt.

#### `#comment`

Der `#comment`-Tag erlaubt es dir, Anmerkungen zu deinen Templates hinzuzufügen, die nicht in der gerenderten Ausgabe erscheinen. Der Tag akzeptiert einen String-Parameter, der beim Rendern vollständig ignoriert wird.

```leaf
#comment("This is a single-line comment")
<h1>#(title)</h1>
```

Für längere Kommentare kannst du die Multi-Line-String-Syntax verwenden:

```leaf
#comment("""
This template renders the home page.
It expects a "title" and "body" variable.
""")
<h1>#(title)</h1>
```

#### `#isEmpty`

Der `#isEmpty`-Tag gibt `true` zurück, wenn eine an das Template übergebene String-Eigenschaft leer ist. Er wird typischerweise innerhalb einer `#if`-Bedingung verwendet:

```leaf
#if(isEmpty(title)):
    No title was provided.
#else:
    The title is #(title)
#endif
```

#### `#dumpContext`

Der `#dumpContext`-Tag rendert den gesamten Context in eine für Menschen lesbare Zeichenkette. Verwende diesen Tag, um zu überprüfen,
welcher Context an das aktuelle Rendering übergeben wird.

```leaf
Hello, world!
#dumpContext
```
