# Leaf

Leaf to wszechstronny język szablonów ze składnią inspirowaną językiem programowania Swift. Ta biblioteka pozwala generować dynamiczne strony HTML dla przeglądarek oraz np. maile oparte o HTML (tzw. rich emails) do wysyłania za pomocą API.

## Biblioteka

Pierwszym krokiem do użycia Leaf jest dodanie go jako zależności w projekcie, w pliku manifest managera SPM.

```swift
// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        /// Inne zależności ...
        .package(url: "https://github.com/vapor/leaf.git", from: "4.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "Leaf", package: "leaf"),
            // Inne zależności
        ]),
        // Inne "targety" (cele)
    ]
)
```

## Konfiguracja

Od razu po dodaniu biblioteki do projektu, framework Vapor jest gotowy do jej konfiguracji. Więcej informacji tutaj: [`configure.swift`](../getting-started/folder-structure.md#configureswift).

```swift
import Leaf

app.views.use(.leaf)
```

Powyższy kod ustawia `Leaf` jako domyślny język szablonów. Podczas wywołania `req.view`, w kodzie zostanie użyty `LeafRenderer`.

!!! Warto wiedzieć
Leaf zawiera wewnętrzny system cachowania dla wyrenderowanych stron. `Cache` jest wyłączony dla aplikacji w trybie `developerskim` - to powoduje, że zmiany w szablonach są widoczne natychmiast. W środowisku `produkcyjnym` i innych `Cache` jest włączony automatycznie - jakiekolwiek zmiany będą widoczne dopiero po restarcie aplikacji.

!!! Uwaga
Aby umożliwić Leaf znalezienie szablonów kiedy projekt jest otwarty za pomocą Xcode, należy ustawić [custom working directory](../getting-started/xcode.md#custom-working-directory) dla Xcode workspace.

## Struktura folderów

Po skonfigurowaniu Leaf, należy upewnić się czy istnieje folder `Views`, w którym są przechowywane szablony `.leaf`. Leaf oczekuje szablonów w folderze `./Resources/Views` - relatywnie do root'a projektu.

Do serwowania plików np. Javascript i CSS, bezpośrednio z folderu `/Public` przyda się [`FileMiddleware`](https://api.vapor.codes/vapor/documentation/vapor/filemiddleware).

```
VaporApp
├── Package.swift
├── Resources
│   ├── Views
│   │   └── hello.leaf
├── Public
│   ├── images (obrazki)
│   ├── styles (zasoby css - style)
└── Sources
    └── ...
```

## Renderowanie widoku

Teraz, kiedy Leaf jest skonfigurowany, wyrenderujmy pierwszy szablon. W folderze `Resources/Views`, stwórz plik o nazwie `hello.leaf` z następującą zawartością:

```leaf
Cześć, #(name)!
```

!!! tip
Jeśli korzystasz z VSCode, rekomendowane jest zainstalowanie rozszerzenia do Vapor (Podpowiedzi i podkreślanie składni): [Vapor for VS Code](https://marketplace.visualstudio.com/items?itemName=Vapor.vapor-vscode).

Następnie: Dodaj ścieżkę (przeważnie w `routes.swift` lub w kontrolerze), żeby wyrenderować widok.

```swift
app.get("hello") { req -> EventLoopFuture<View> in
    return req.view.render("hello", ["name": "Leaf"])
}

// lub

app.get("hello") { req async throws -> View in
    return try await req.view.render("hello", ["name": "Leaf"])
}
```

Powyższy przykład używa generycznej właściwości `view` z obiektu `Request` zamiast wywoływać Leaf bezpośrednio. To podejście pozwala używać różnych języków/silników szablonów podczas testów.

Przejdź w przeglądarce pod adres `/hello`. Powinien być widoczny napis `Hello, Leaf!`. Gratulacje! Właśnie udało Ci się wyrenderować swój pierwszy widok za pomocą Leaf!
