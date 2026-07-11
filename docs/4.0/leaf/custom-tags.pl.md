# Własne tagi

Możesz tworzyć własne tagi Leaf, korzystając z protokołu [`LeafTag`](https://api.vapor.codes/leafkit/documentation/leafkit/leaftag).

Aby to zademonstrować, stwórzmy własny tag `#now`, który wypisuje aktualny znacznik czasu. Tag będzie również wspierał pojedynczy, opcjonalny parametr określający format daty.

!!! tip
    Jeśli Twój własny tag renderuje HTML, powinieneś dostosować go do protokołu `UnsafeUnescapedLeafTag`, aby HTML nie był escape'owany. Pamiętaj, aby sprawdzać lub sanitizować wszelkie dane wprowadzane przez użytkownika.

## `LeafTag`

Najpierw stwórz klasę o nazwie `NowTag` i dostosuj ją do `LeafTag`.

```swift
struct NowTag: LeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        ...
    }
}
```

Teraz zaimplementujmy metodę `render(_:)`. Kontekst `LeafContext` przekazywany do tej metody zawiera wszystko, czego możemy potrzebować.

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

## Konfiguracja tagu

Teraz, gdy zaimplementowaliśmy `NowTag`, musimy tylko poinformować o nim Leaf. Możesz w ten sposób dodać dowolny tag - nawet jeśli pochodzi z osobnego pakietu. Zwykle robi się to w `configure.swift`:

```swift
app.leaf.tags["now"] = NowTag()
```

I to wszystko! Możemy teraz używać naszego własnego tagu w Leaf.

```leaf
The time is #now()
```

## Właściwości kontekstu

`LeafContext` zawiera dwie ważne właściwości: `parameters` oraz `data`, które zawierają wszystko, czego możemy potrzebować.

- `parameters`: Tablica zawierająca parametry tagu.
- `data`: Słownik zawierający dane widoku przekazane do `render(_:_:)` jako kontekst.

### Przykładowy tag Hello

Aby zobaczyć, jak z tego korzystać, zaimplementujmy prosty tag hello wykorzystujący obie właściwości.

#### Korzystanie z parametrów

Możemy uzyskać dostęp do pierwszego parametru, który będzie zawierał imię.

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

#### Korzystanie z danych

Możemy uzyskać dostęp do wartości imienia, korzystając z klucza "name" wewnątrz właściwości data.

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

_Kontroler_:

```swift
return try await req.view.render("home", ["name": "John"])
```
