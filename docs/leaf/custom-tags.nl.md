# Aangepaste Tags

U kunt aangepaste Leaf tags maken met het [`LeafTag`](https://api.vapor.codes/leaf-kit/main/LeafKit/LeafTag/) protocol. 

Om dit te demonstreren, laten we eens kijken naar het maken van een aangepaste tag `#now` die de huidige tijdstempel afdrukt. De tag ondersteunt ook een enkele, optionele parameter voor het specificeren van het datumformaat.

!!! tip
	Als je aangepaste tag HTML rendert, moet je je tag conformeren aan `UnsafeUnescapedLeafTag` zodat de HTML niet ge-escaped wordt. Vergeet niet om alle gebruikersinvoer te controleren of te zuiveren.

## `LeafTag`

Maak eerst een klasse genaamd `NowTag` en conformeer deze aan `LeafTag`.

```swift
struct NowTag: LeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        ...
    }
}
```

Laten we nu de `render(_:)` methode implementeren. De `LeafContext` context die aan deze methode wordt doorgegeven heeft alles wat we nodig zouden moeten hebben.

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

## Tag Configureren

Nu we `NowTag` hebben geïmplementeerd, hoeven we alleen Leaf er nog maar over te vertellen. Je kunt elke tag op deze manier toevoegen - zelfs als ze uit een apart pakket komen. Je doet dit meestal in `configure.swift`:

```swift
app.leaf.tags["now"] = NowTag()
```

En dat is het! We kunnen nu onze aangepaste tag gebruiken in Leaf.

```leaf
The time is #now()
```

## Context Eigenschappen

De `LeafContext` bevat twee belangrijke eigenschappen. `parameters` en `data` die alles bevatten wat we nodig zouden moeten hebben.

- `parameters`: Een array die de parameters van de tag bevat.
- `data`: Een woordenboek dat de gegevens bevat van de view die doorgegeven is aan `render(_:_:)` als de context.

### Voorbeeld Hello Tag

Om te zien hoe dit te gebruiken, laten we een eenvoudige "hello" tag implementeren die beide eigenschappen gebruikt.

#### Parameters Gebruiken

We hebben toegang tot de eerste parameter die de naam zou bevatten.

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

#### Data Gebruiken

We kunnen de waarde van de naam benaderen door de sleutel "name" te gebruiken in de data property.

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
