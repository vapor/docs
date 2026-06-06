# Struktura folderów

Udało Ci się stworzyć, zbudować oraz uruchomić swoją pierwszą aplikacje Vapor, użyjmy tego momentu aby zapoznać Cię z strukturą folderów w projekcie. Struktura jest bazowana na strukturze [SPM](spm.md)a, więc jeśli wcześniej pracowałeś/aś z jego pomocą powinna być dla Ciebie znana.  

```
.
├── Public
├── Sources
│   ├── App
│   │   ├── Controllers
│   │   ├── Migrations
│   │   ├── Models
│   │   ├── configure.swift 
│   │   ├── entrypoint.swift
│   │   └── routes.swift
│       
├── Tests
│   └── AppTests
└── Package.swift
```

Sekcja poniżej wyjaśnia każdą część struktury folderów w detalach.

## Public

Then folder zawiera wszystkie publiczne pliki, które będą serwowane przez aplikacje jeśli `FileMiddleware` jest włączony. To zazwyczaj są obrazy, arkusze stylów i skrypty przeglądarki. Dla przykładu, zapytanie do `localhost:8080/favicon.ico` będzie sprawdzać czy `Public/favicon.ico` istnieje i zwracać je. 

Musisz aktywować `FileMiddleware` w pliku `configure.swift` twojego projektu, zanim Vapor będzie potrafił serwować pliki publiczne.

```swift
// Serwuje pliki folderu `Public/`
let fileMiddleware = FileMiddleware(
    publicDirectory: app.directory.publicDirectory
)
app.middleware.use(fileMiddleware)
```

## Sources

Ten folder zawiera wszystkie pliki źródłowe twojego projektu.
Folder o na górze zagnieżdżenia, `App`, odzwierciedla moduł pakietu,
zadeklarowany w manifeście [SwiftPM](spm.md).

### App

To miejsce na cała logikę twojej aplikacji.

#### Controllers

Kontrolery to świetny sposób na grupowania razem logiki aplikacji. Większość kontrolerów posiada wiele funkcji które przyjmują jakąś formę zapytania i zwracają dla niej odpowiedź.

#### Migrations

W tym folderze znajdują się wszystkie migracje bazy danych jeśli używać Fluenta.

#### Models

To świetne miejsce do trzymania `Content` struct lub `Model` z Fluenta. 

#### configure.swift

Ten plik zawiera funkcję `configure(_:)`. Metoda ta jest wywoływana przez `entrypoint.swift` w celu skonfigurowania nowo utworzonej `Aplikacji`. W tym miejscu należy zarejestrować usługi, takie jak trasy, bazy danych, dostawców i inne.

#### entrypoint.swift

Ten plik zawiera punkt wejścia `@main` dla aplikacji, która ustawia, konfiguruje i uruchamia aplikację Vapor.

#### routes.swift

Ten plik zawiera funkcję `routes(_:)`. Metoda ta jest wywoływana pod koniec `configure(_:)` w celu zarejestrowania ścieżek czy inaczej końcówek w `Application`.

## Tests

Każdy niewykonywalny moduł w folderze `Sources` może mieć odpowiadający mu folder w `Tests`. Zawiera on kod zbudowany na module `XCTest` do testowania aplikacji. Testy można uruchomić za pomocą `swift test` w wierszu poleceń lub naciskając ⌘+U w Xcode.

### AppTests

Ten folder zawiera testy jednostkowe dla kodu w module `App`.

## Package.swift

Na końcu znajduje się manifest pakietu [SPM](spm.md).
