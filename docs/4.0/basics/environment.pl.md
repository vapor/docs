# Środowisko

API środowiska (Environment) Vapora pomaga dynamicznie konfigurować Twoją aplikację. Domyślnie Twoja aplikacja będzie używać środowiska `development`. Możesz zdefiniować inne przydatne środowiska, takie jak `production` czy `staging`, i zmieniać sposób konfiguracji aplikacji w każdym przypadku. Możesz również wczytywać zmienne ze środowiska procesu lub z plików `.env` (dotenv), w zależności od potrzeb.

Aby uzyskać dostęp do aktualnego środowiska, użyj `app.environment`. Możesz sprawdzać wartość tej właściwości w `configure(_:)`, aby wykonywać różną logikę konfiguracji.

```swift
switch app.environment {
case .production:
    app.databases.use(....)
default:
    app.databases.use(...)
}
```

## Zmiana środowiska

Domyślnie Twoja aplikacja będzie działać w środowisku `development`. Możesz to zmienić, przekazując flagę `--env` (`-e`) podczas uruchamiania aplikacji.

```swift
swift run App serve --env production
```

Vapor zawiera następujące środowiska:

|nazwa|skrót|opis|
|-|-|-|
|production|prod|Wdrożone dla Twoich użytkowników.|
|development|dev|Lokalny rozwój.|
|testing|test|Do testów jednostkowych.|

!!! info
    Środowisko `production` domyślnie używa poziomu logowania `notice`, chyba że wskazano inaczej. Wszystkie pozostałe środowiska domyślnie używają `info`.

Do flagi `--env` (`-e`) możesz przekazać zarówno pełną, jak i skróconą nazwę.

```swift
swift run App serve -e prod
```

## Zmienne procesu

`Environment` oferuje proste, oparte na łańcuchach znaków API do dostępu do zmiennych środowiskowych procesu.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

Oprócz `get`, `Environment` oferuje dynamiczne API dostępu do składowych poprzez `process`.

```swift
let foo = Environment.process.FOO
print(foo) // String?
```

Podczas uruchamiania aplikacji w terminalu możesz ustawiać zmienne środowiskowe za pomocą `export`.

```sh
export FOO=BAR
swift run App serve
```

Podczas uruchamiania aplikacji w Xcode możesz ustawiać zmienne środowiskowe, edytując schemat (scheme) `App`.

## .env (dotenv)

Pliki dotenv zawierają listę par klucz-wartość, które są automatycznie wczytywane do środowiska. Pliki te ułatwiają konfigurację zmiennych środowiskowych bez konieczności ustawiania ich ręcznie.

Vapor będzie szukał plików dotenv w bieżącym katalogu roboczym. Jeśli używasz Xcode, upewnij się, że ustawiłeś katalog roboczy, edytując schemat `App`.

Załóżmy następujący plik `.env` umieszczony w głównym folderze Twojego projektu:

```sh
FOO=BAR
```

Gdy aplikacja się uruchomi, będziesz mógł uzyskać dostęp do zawartości tego pliku tak samo jak do innych zmiennych środowiskowych procesu.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

!!! info
    Zmienne określone w plikach `.env` nie nadpiszą zmiennych, które już istnieją w środowisku procesu.

Oprócz `.env`, Vapor spróbuje również wczytać plik dotenv dla bieżącego środowiska. Na przykład w środowisku `development` Vapor wczyta plik `.env.development`. Wartości zawarte w pliku dla konkretnego środowiska mają pierwszeństwo przed ogólnym plikiem `.env`.

Typowym wzorcem jest dołączanie do projektu pliku `.env` jako szablonu z domyślnymi wartościami. Pliki konkretnych środowisk są ignorowane za pomocą następującego wzorca w `.gitignore`:

```gitignore
.env.*
```

Gdy projekt zostanie sklonowany na nowy komputer, plik szablonu `.env` można skopiować i uzupełnić poprawnymi wartościami.

```sh
cp .env .env.development
vim .env.development
```

!!! warning
    Pliki dotenv zawierające wrażliwe informacje, takie jak hasła, nie powinny być zatwierdzane (commitowane) do systemu kontroli wersji.

Jeśli masz trudności z wczytywaniem plików dotenv, spróbuj włączyć logowanie debugowania za pomocą `--log debug`, aby uzyskać więcej informacji.

## Niestandardowe środowiska

Aby zdefiniować niestandardową nazwę środowiska, rozszerz `Environment`.

```swift
extension Environment {
    static var staging: Environment {
        .custom(name: "staging")
    }
}
```

Środowisko aplikacji jest zwykle ustawiane w `entrypoint.swift` za pomocą `Environment.detect()`.

```swift
@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = Application(env)
        defer { app.shutdown() }
        
        try await configure(app)
        try await app.runFromAsyncMainEntrypoint()
    }
}
```

Metoda `detect` wykorzystuje argumenty wiersza poleceń procesu i automatycznie analizuje flagę `--env`. Możesz nadpisać to zachowanie, inicjalizując niestandardową strukturę `Environment`.

```swift
let env = Environment(name: "testing", arguments: ["vapor"])
```

Tablica argumentów musi zawierać co najmniej jeden argument, który reprezentuje nazwę pliku wykonywalnego. Kolejne argumenty mogą zostać dostarczone, aby symulować przekazywanie argumentów za pomocą wiersza poleceń. Jest to szczególnie przydatne do testowania.
