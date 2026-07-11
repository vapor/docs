# Benutzerdefinierte Tags

Du kannst benutzerdefinierte Leaf-Tags mit dem [`LeafTag`](https://api.vapor.codes/leafkit/documentation/leafkit/leaftag) Protokoll erstellen.

Um das zu demonstrieren, schauen wir uns an, wie man einen benutzerdefinierten Tag `#now` erstellt, der den aktuellen Zeitstempel ausgibt. Der Tag unterstützt außerdem einen einzelnen, optionalen Parameter zur Angabe des Datumsformats.

!!! tip
    Wenn dein benutzerdefinierter Tag HTML rendert, solltest du ihn an `UnsafeUnescapedLeafTag` konformieren, damit das HTML nicht escaped wird. Denke daran, jegliche Benutzereingaben zu prüfen oder zu bereinigen.

## `LeafTag`

Erstelle zunächst eine Klasse namens `NowTag` und lasse sie `LeafTag` konformieren.

```swift
struct NowTag: LeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        ...
    }
}
```

Implementieren wir nun die `render(_:)` Methode. Der `LeafContext` Context, der dieser Methode übergeben wird, enthält alles, was wir benötigen.

```swift
enum NowTagError: Error {
    case invalidFormatParameter
    case tooManyParameters
}

struct NowTag: LeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        let formatter = DateFormatter()
        switch ctx.parameters.count {
        case 0: formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        case 1:
            guard let string = ctx.parameters[0].string else {
                throw NowTagError.invalidFormatParameter
            }

            formatter.dateFormat = string
        default:
            throw NowTagError.tooManyParameters
        }
    
        let dateAsString = formatter.string(from: Date())
        return LeafData.string(dateAsString)
    }
}
```

## Tag konfigurieren

Nachdem wir `NowTag` implementiert haben, müssen wir Leaf nur noch davon erzählen. Du kannst auf diese Weise jeden Tag hinzufügen - auch wenn er aus einem separaten Package stammt. Das machst du üblicherweise in `configure.swift`:

```swift
app.leaf.tags["now"] = NowTag()
```

Und das war's! Wir können unseren benutzerdefinierten Tag jetzt in Leaf verwenden.

```leaf
The time is #now()
```

## Context-Eigenschaften

Der `LeafContext` enthält zwei wichtige Eigenschaften: `parameters` und `data`, die alles enthalten, was wir benötigen.

- `parameters`: Ein Array, das die Parameter des Tags enthält.
- `data`: Ein Dictionary, das die Daten der View enthält, die `render(_:_:)` als Context übergeben wurden.

### Beispiel: Hello-Tag

Um zu sehen, wie man das verwendet, implementieren wir einen einfachen Hello-Tag, der beide Eigenschaften nutzt.

#### Parameter verwenden

Wir können auf den ersten Parameter zugreifen, der den Namen enthalten würde.

```swift
enum HelloTagError: Error {
    case missingNameParameter
}

struct HelloTag: UnsafeUnescapedLeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        guard let name = ctx.parameters[0].string else {
            throw HelloTagError.missingNameParameter
        }

        return LeafData.string("<p>Hello \(name)</p>")
    }
}
```

```leaf
#hello("John")
```

#### Daten verwenden

Wir können auf den Namenswert zugreifen, indem wir den Schlüssel "name" innerhalb der `data` Eigenschaft verwenden.

```swift
enum HelloTagError: Error {
    case nameNotFound
}

struct HelloTag: UnsafeUnescapedLeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        guard let name = ctx.data["name"]?.string else {
            throw HelloTagError.nameNotFound
        }

        return LeafData.string("<p>Hello \(name)</p>")
    }
}
```

```leaf
#hello()
```

_Controller_:

```swift
return try await req.view.render("home", ["name": "John"])
```
