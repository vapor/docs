# Swift Package Manager

[Swift Package Manager](https://swift.org/package-manager/) (SPM) jest używany do budowania kodu źródłowego twojego projektu i zależności. Vapor bardzo mocno polega na SPM, więc dobrym pomysłem jest zrozumieć podstawy tego jak działa.

SPM jest podobny do Cocoapods, Ruby gems albo NPM. Można również używać SPM z poziomu wiersza poleceń na przykład `swift build` lub `swift test` lub z kompatybilnymi IDE. Natomiast, coś co wyróżnia go od innych managerów zależności, nie ma on centralnego indexu pakietów (central package index). Zamiast tego SPM wykorzystuje adresy URL do repozytoriów Git i zależności wersji za pomocą [Git tags](https://git-scm.com/book/en/v2/Git-Basics-Tagging).

## Manifest pakietu

Pierwszym miejscem, do którego SPM zagląda w projekcie jest manifest pakietu. Powinien on zawsze znajdować się w katalogu głównym projektu i nosić nazwę `Package.swift`.

Spójrz na ten przykładowy manifest pakietu.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
```

Każda część manifestu jest wyjaśniona w poniższych sekcjach.

### Tools Version

Pierwszy wiersz manifestu pakietu wskazuje wymaganą wersję narzędzi Swift. Określa ona minimalną wersję języka Swift obsługiwaną przez pakiet. Interfejs API opisu pakietu może również zmieniać się między wersjami Swift, więc ten wiersz zapewnia, że Swift będzie wiedział, jak przeanalizować manifest.

### Package Name

Pierwszym argumentem do `Package` jest nazwa pakietu. Jeśli pakiet jest publiczny, jako nazwy należy użyć ostatniego segmentu adresu URL repozytorium Git.

### Platforms

Tablica `platforms` określa, które platformy obsługuje ten pakiet. Określając `.macOS(.v12)` pakiet wymaga systemu macOS 12 lub nowszego. Gdy Xcode załaduje ten projekt, automatycznie ustawi minimalną wersję wdrożenia na macOS 12, aby można było korzystać ze wszystkich dostępnych interfejsów API.

### Dependencies

Zależności (z ang. dependencies) to inne pakiety SPM, na których opiera się pakiet. Wszystkie aplikacje Vapor opierają się na pakiecie Vapor, ale można dodać dowolną liczbę innych zależności.

W powyższym przykładzie widać, że pakiet [vapor/vapor](https://github.com/vapor/vapor) w wersji 4.76.0 lub nowszej jest zależny od tego pakietu. Po dodaniu zależności do pakietu, musisz następnie zasygnalizować, które [targets](#targets) zależą od
nowo dostępnych modułów.

### Targets

Cele (z ang. targets) to wszystkie moduły, pliki wykonywalne i testy, które zawiera pakiet. Większość aplikacji Vapor będzie miała dwa obiekty docelowe, chociaż możesz dodać tyle, ile chcesz, aby uporządkować swój kod. Każdy cel deklaruje, od których modułów zależy. Musisz dodać nazwy modułów w tym miejscu, aby zaimportować je w swoim kodzie. Cel może zależeć od innych celów w projekcie lub dowolnych modułów udostępnionych przez pakiety dodane do
tablicy [głównych zależności](#dependencies).

## Folder Structure

Poniżej znajduje się typowa struktura folderów dla pakietu SPM.

```fish
.
├── Sources
│   └── App
│       └── (Kod źródłowy)
├── Tests
│   └── AppTests
└── Package.swift
```

Każdy `.target` lub `.executableTarget` odpowiada folderowi w folderze `Sources`. 
Każdy `.testTarget` odpowiada folderowi w folderze `Tests`.

## Package.resolved

Przy pierwszej kompilacji projektu, SPM utworzy plik `Package.resolved`, który przechowuje wersję każdej zależności. Przy następnej kompilacji projektu te same wersje zostaną użyte, nawet jeśli dostępne są nowsze wersje. 

Aby zaktualizować zależności, uruchom `swift package update`.

## Xcode

Jeśli korzystasz z Xcode 11 lub nowszego, zmiany w zależnościach, celach, produktach itp. będą wprowadzane automatycznie za każdym razem, gdy plik `Package.swift` zostanie zmodyfikowany. 

Jeśli chcesz zaktualizować do najnowszych zależności, użyj File &rarr; Swift Packages &rarr; Update To Latest Swift Package Versions.

Możesz również dodać plik `.swiftpm` do pliku `.gitignore`. Jest to miejsce, w którym Xcode będzie przechowywać konfigurację projektu Xcode.
