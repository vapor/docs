# Logowanie 

API logowania Vapora zbudowane jest na bazie [SwiftLog](https://github.com/apple/swift-log). Oznacza to, że Vapor jest kompatybilny ze wszystkimi [implementacjami backendów](https://github.com/apple/swift-log#backends) SwiftLog. 

## Logger

Instancje `Logger` służą do wypisywania komunikatów logów. Vapor udostępnia kilka prostych sposobów na uzyskanie dostępu do loggera.

### Request

Każde przychodzące żądanie `Request` posiada unikalny logger, którego powinieneś używać do wszystkich logów specyficznych dla tego żądania.

```swift
app.get("hello") { req -> String in
    req.logger.info("Hello, logs!")
    return "Hello, world!"
}
```

Logger żądania zawiera unikalny UUID identyfikujący przychodzące żądanie, aby ułatwić śledzenie logów.

```
[ INFO ] Hello, logs! [request-id: C637065A-8CB0-4502-91DC-9B8615C5D315] (App/routes.swift:10)
```

!!! info
    Metadane loggera będą widoczne tylko na poziomie logowania debug lub niższym.

### Application

Dla komunikatów logów podczas uruchamiania i konfiguracji aplikacji, użyj loggera `Application`.

```swift
app.logger.info("Setting up migrations...")
app.migrations.use(...)
```

### Custom Logger

W sytuacjach, gdy nie masz dostępu do `Application` lub `Request`, możesz zainicjować nowy `Logger`. 

```swift
let logger = Logger(label: "dev.logger.my")
logger.info(...)
```

Choć niestandardowe loggery nadal będą wypisywać dane do skonfigurowanego backendu logowania, nie będą miały dołączonych ważnych metadanych, takich jak UUID żądania. Używaj loggerów specyficznych dla żądania lub aplikacji, gdziekolwiek to możliwe. 

## Level

SwiftLog obsługuje kilka różnych poziomów logowania.

|nazwa|opis|
|-|-|
|trace|Odpowiedni dla komunikatów zawierających informacje zazwyczaj przydatne tylko podczas śledzenia wykonania programu.|
|debug|Odpowiedni dla komunikatów zawierających informacje zazwyczaj przydatne tylko podczas debugowania programu.|
|info|Odpowiedni dla komunikatów informacyjnych.|
|notice|Odpowiedni dla warunków, które nie są warunkami błędu, ale mogą wymagać specjalnej obsługi.|
|warning|Odpowiedni dla komunikatów, które nie są warunkami błędu, ale są poważniejsze niż notice.|
|error|Odpowiedni dla warunków błędu.|
|critical|Odpowiedni dla krytycznych warunków błędu, które zazwyczaj wymagają natychmiastowej uwagi.|

Gdy zalogowany zostanie komunikat `critical`, backend logowania może swobodnie wykonywać bardziej kosztowne operacje w celu przechwycenia stanu systemu (takie jak przechwytywanie stack traców), aby ułatwić debugowanie.

Domyślnie Vapor używa logowania na poziomie `info`. Podczas działania w środowisku `production`, używany będzie poziom `notice`, aby poprawić wydajność. 

### Changing Log Level

Niezależnie od trybu środowiska, możesz nadpisać poziom logowania, aby zwiększyć lub zmniejszyć liczbę generowanych logów. 

Pierwszym sposobem jest przekazanie opcjonalnej flagi `--log` podczas uruchamiania aplikacji.

```sh
swift run App serve --log debug
```

Drugim sposobem jest ustawienie zmiennej środowiskowej `LOG_LEVEL`.

```sh
export LOG_LEVEL=debug
swift run App serve
```

Obie te metody można wykonać w Xcode, edytując schemat (scheme) `App`.

## Configuration

SwiftLog jest konfigurowany poprzez bootstrapping `LoggingSystem` raz na proces. Projekty Vapora zazwyczaj robią to w `entrypoint.swift`.

```swift
var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
```

`bootstrap(from:)` to pomocnicza metoda dostarczana przez Vapor, która skonfiguruje domyślny handler logów na podstawie argumentów wiersza poleceń i zmiennych środowiskowych. Domyślny handler logów obsługuje wypisywanie komunikatów do terminala z obsługą kolorów ANSI. 

### Custom Handler

Możesz nadpisać domyślny handler logów Vapora i zarejestrować własny.

```swift
import Logging

LoggingSystem.bootstrap { label in
    StreamLogHandler.standardOutput(label: label)
}
```

Wszystkie obsługiwane backendy SwiftLog będą działać z Vaporem. Jednak zmiana poziomu logowania za pomocą argumentów wiersza poleceń i zmiennych środowiskowych jest kompatybilna tylko z domyślnym handlerem logów Vapora.
