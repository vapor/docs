# Serwisy

`Application` i `Request` Vapora są zbudowane tak, aby mogły być rozszerzane przez twoją aplikację i pakiety firm trzecich. Nowa funkcjonalność dodawana do tych typów jest często nazywana serwisami.

## Tylko do odczytu

Najprostszym rodzajem serwisu jest serwis tylko do odczytu. Serwisy te składają się z obliczanych zmiennych lub metod dodanych do aplikacji lub żądania.

```swift
import Vapor

struct MyAPI {
    let client: Client

    func foos() async throws -> [String] { ... }
}

extension Request {
    var myAPI: MyAPI {
        .init(client: self.client)
    }
}
```

Serwisy tylko do odczytu mogą zależeć od dowolnych już istniejących serwisów, takich jak `client` w tym przykładzie. Po dodaniu rozszerzenia twój własny serwis może być używany jak każda inna właściwość na request.

```swift
req.myAPI.foos()
```

## Zapisywalne

Serwisy, które wymagają stanu lub konfiguracji, mogą wykorzystywać storage `Application` i `Request` do przechowywania danych. Załóżmy, że chcesz dodać do swojej aplikacji poniższą strukturę `MyConfiguration`.

```swift
struct MyConfiguration {
    var apiKey: String
}
```

Aby użyć storage, musisz zadeklarować `StorageKey`.

```swift
struct MyConfigurationKey: StorageKey {
    typealias Value = MyConfiguration
}
```

Jest to pusta struktura z aliasem typu `Value` określającym, jaki typ jest przechowywany. Używając pustego typu jako klucza, możesz kontrolować, jaki kod ma dostęp do wartości przechowywanej w storage. Jeśli typ jest internal lub private, tylko twój kod będzie mógł modyfikować powiązaną wartość w storage.

Na koniec dodaj rozszerzenie do `Application`, aby uzyskiwać i ustawiać strukturę `MyConfiguration`.

```swift
extension Application {
    var myConfiguration: MyConfiguration? {
        get {
            self.storage[MyConfigurationKey.self]
        }
        set {
            self.storage[MyConfigurationKey.self] = newValue
        }
    }
}
```

Po dodaniu rozszerzenia możesz używać `myConfiguration` jak zwykłej właściwości na `Application`.


```swift
app.myConfiguration = .init(apiKey: ...)
print(app.myConfiguration?.apiKey)
```

## Cykl życia

`Application` Vapora pozwala na rejestrowanie handlerów cyklu życia. Umożliwiają one podłączenie się do zdarzeń takich jak uruchomienie i zamknięcie.

```swift
// Prints hello during boot.
struct Hello: LifecycleHandler {
    // Called before application boots.
    func willBoot(_ app: Application) throws {
        app.logger.info("Hello!")
    }

    // Called after application boots.
    func didBoot(_ app: Application) throws {
        app.logger.info("Server is running")
    }

    // Called before application shutdown.
    func shutdown(_ app: Application) {
        app.logger.info("Goodbye!")
    }
}

// Add lifecycle handler.
app.lifecycle.use(Hello())
```

## Blokady

`Application` Vapora zawiera udogodnienia do synchronizacji kodu przy użyciu blokad (locks). Deklarując `LockKey`, możesz uzyskać unikalną, współdzieloną blokadę do synchronizacji dostępu do twojego kodu.

```swift
struct TestKey: LockKey { }

let test = app.locks.lock(for: TestKey.self)
test.withLock {
    // Do something.
}
```

Każde wywołanie `lock(for:)` z tym samym `LockKey` zwróci tę samą blokadę. Ta metoda jest thread-safe.

Dla blokady obejmującej całą aplikację możesz użyć `app.sync`.

```swift
app.sync.withLock {
    // Do something.
}
```

## Request

Serwisy przeznaczone do użycia w route handlerach powinny być dodawane do `Request`. Serwisy request powinny korzystać z loggera i event loopa żądania. Ważne jest, aby żądanie pozostawało na tym samym event loopie, w przeciwnym razie po zwróceniu odpowiedzi do Vapora zostanie wywołane assertion.

Jeśli serwis musi opuścić event loop żądania, aby wykonać jakąś pracę, powinien upewnić się, że wróci do tego event loopa przed zakończeniem. Można to zrobić za pomocą `hop(to:)` na `EventLoopFuture`.

Serwisy request, które potrzebują dostępu do serwisów aplikacji, takich jak konfiguracje, mogą użyć `req.application`. Zachowaj ostrożność, biorąc pod uwagę bezpieczeństwo wątków (thread-safety) przy dostępie do aplikacji z route handlera. Generalnie z poziomu żądań powinny być wykonywane tylko operacje odczytu. Operacje zapisu muszą być chronione blokadami.
