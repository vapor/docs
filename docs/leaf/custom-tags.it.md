# Tag Personalizzati

Puoi creare tag Leaf personalizzati usando il protocollo [`LeafTag`](https://api.vapor.codes/leafkit/documentation/leafkit/leaftag). 

Per mostrare come funziona, diamo un'occhiata alla creazione di un tag personalizzato `#now` che stampa l'attuale marca temporale. Il tag supporterà anche un singolo parametro opzionale per specificare il formato della data.

!!! tip
	Se il tuo tag personalizzato renderizza HTML dovresti conformare il tuo tag personalizzato a `UnsafeUnescapedLeafTag` così che l'HTML non sia "escaped". Ricorda di controllare o ripulire ogni input dell'utente.

## `LeafTag`

Prima crea una classe chiamata `NowTag` e conformala a `LeafTag`.

```swift
struct NowTag: LeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        ...
    }
}
```

Adesso implementiamo il metodo `render(_:)`. Il contesto `LeafContext` passato a questo metodo ha tutto quello che ci dovrebbe servire.

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

## Configura il Tag

Adesso che abbiamo implementato `NowTag`, dobbiamo solo dirlo a Leaf. Puoi aggiungere qualsiasi tag così - anche se vengono da un pacchetto separato. Di solito si fa in `configure.swift`:

```swift
app.leaf.tags["now"] = NowTag()
```

Fatto! Ora possiamo usare la nostra tag personalizzata in Leaf.

```leaf
The time is #now()
```

## Proprietà del Contesto

Il `LeafContext` contiene due proprietà importanti. `parameters` e `data` che ha tutto quello che ci dovrebbe servire.

- `parameters`: Un array che contiene i parametri del tag.
- `data`: Un dizionario che contiene i dati della view passata a `render(_:_:)` come contesto.

### Tag Hello di Esempio

Per vedere come usarlo, implementiamo un semplice tag di saluto usando entrambe le proprietà.

#### Usando i Parametri

Possiamo accedere al primo parametro che dovrebbe contenere il nome.

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

#### Usando i Dati

Possiamo accedere al valore del nome usando la chiame "name" dentro la proprietà dei dati.

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
