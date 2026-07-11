# Asynchroniczność

## Async Await

Swift 5.5 wprowadził do języka współbieżność (concurrency) w formie `async`/`await`. Zapewnia to pełnoprawny sposób obsługi kodu asynchronicznego w aplikacjach Swift i Vapor.

Vapor jest zbudowany na bazie [SwiftNIO](https://github.com/apple/swift-nio.git), które dostarcza podstawowe typy do niskopoziomowego programowania asynchronicznego. Były one (i nadal są) używane w całym Vaporze, zanim pojawiło się `async`/`await`. Jednak większość kodu aplikacji może być teraz napisana z użyciem `async`/`await` zamiast `EventLoopFuture`. Uprości to Twój kod i znacznie ułatwi rozumowanie o nim.

Większość API Vapora oferuje teraz zarówno wersję opartą na `EventLoopFuture`, jak i na `async`/`await`, dzięki czemu możesz wybrać, która jest dla Ciebie lepsza. Ogólnie rzecz biorąc, powinieneś używać tylko jednego modelu programowania na handler trasy i nie mieszać ich w swoim kodzie. W przypadku aplikacji, które wymagają jawnej kontroli nad event loopami, lub aplikacji o bardzo wysokiej wydajności, powinieneś nadal używać `EventLoopFuture`, dopóki nie zostaną zaimplementowane niestandardowe executory. Dla wszystkich pozostałych zaleca się używanie `async`/`await`, ponieważ korzyści w postaci czytelności i łatwości utrzymania znacznie przewyższają niewielki spadek wydajności.

### Migracja do async/await

Aby zmigrować się do async/await, konieczne jest wykonanie kilku kroków. Na początek, jeśli używasz macOS, musisz mieć macOS 12 Monterey lub nowszy oraz Xcode 13.1 lub nowszy. Na innych platformach musisz używać Swift 5.5 lub nowszego. Następnie upewnij się, że zaktualizowałeś wszystkie swoje zależności.

W pliku Package.swift ustaw wersję narzędzi na 5.5 na górze pliku:

```swift
// swift-tools-version:5.5
import PackageDescription

// ...
```

Następnie ustaw wersję platformy na macOS 12:

```swift
    platforms: [
       .macOS(.v12)
    ],
```

Na koniec zaktualizuj target `Run`, aby oznaczyć go jako target wykonywalny:

```swift
.executableTarget(name: "Run", dependencies: [.target(name: "App")]),
```

Uwaga: jeśli wdrażasz aplikację na Linuksie, upewnij się, że zaktualizowałeś tam również wersję Swift, np. na Heroku lub w swoim Dockerfile. Na przykład Twój Dockerfile powinien zmienić się na:

```diff
-FROM swift:5.2-focal as build
+FROM swift:5.5-focal as build
...
-FROM swift:5.2-focal-slim
+FROM swift:5.5-focal-slim
```

Teraz możesz zmigrować istniejący kod. Generalnie funkcje, które zwracają `EventLoopFuture`, są teraz `async`. Na przykład:

```swift
routes.get("firstUser") { req -> EventLoopFuture<String> in
    User.query(on: req.db).first().unwrap(or: Abort(.notFound)).flatMap { user in
        user.lastAccessed = Date()
        return user.update(on: req.db).map {
            return user.name
        }
    }
}
```

Teraz staje się:

```swift
routes.get("firstUser") { req async throws -> String in
    guard let user = try await User.query(on: req.db).first() else {
        throw Abort(.notFound)
    }
    user.lastAccessed = Date()
    try await user.update(on: req.db)
    return user.name
}
```

### Praca ze starymi i nowymi API

Jeśli napotkasz API, które nie oferuje jeszcze wersji `async`/`await`, możesz wywołać `.get()` na funkcji zwracającej `EventLoopFuture`, aby ją przekonwertować.

Np.

```swift
return someMethodCallThatReturnsAFuture().flatMap { futureResult in
    // use futureResult
}
```

Może stać się

```swift
let futureResult = try await someMethodThatReturnsAFuture().get()
```

Jeśli musisz pójść w drugą stronę, możesz przekonwertować

```swift
let myString = try await someAsyncFunctionThatGetsAString()
```

na

```swift
let promise = request.eventLoop.makePromise(of: String.self)
promise.completeWithTask {
    try await someAsyncFunctionThatGetsAString()
}
let futureString: EventLoopFuture<String> = promise.futureResult
```

## `EventLoopFuture`

Być może zauważyłeś, że niektóre API w Vaporze oczekują lub zwracają generyczny typ `EventLoopFuture`. Jeśli to Twój pierwszy kontakt z futures, mogą się one wydawać na początku nieco mylące. Nie martw się jednak, ten przewodnik pokaże Ci, jak wykorzystać ich potężne API.

Promises i futures są powiązanymi, ale odrębnymi typami. Promises są używane do _tworzenia_ futures. Przez większość czasu będziesz pracować z futures zwracanymi przez API Vapora i nie będziesz musiał martwić się o tworzenie promises.

|typ|opis|mutowalność|
|-|-|-|
|`EventLoopFuture`|Referencja do wartości, która może nie być jeszcze dostępna.|tylko do odczytu|
|`EventLoopPromise`|Obietnica dostarczenia pewnej wartości asynchronicznie.|do odczytu/zapisu|

Futures są alternatywą dla API asynchronicznych opartych na callbackach. Futures mogą być łańcuchowane i transformowane w sposób, w jaki nie da się tego zrobić za pomocą prostych closures.

## Transformacje

Podobnie jak wartości opcjonalne i tablice w Swifcie, futures mogą być mapowane i flat-mapowane. Są to najczęstsze operacje, jakie będziesz wykonywać na futures.

|metoda|argument|opis|
|-|-|-|
|[`map`](#map)|`(T) -> U`|Mapuje wartość future na inną wartość.|
|[`flatMapThrowing`](#flatmapthrowing)|`(T) throws -> U`|Mapuje wartość future na inną wartość lub błąd.|
|[`flatMap`](#flatmap)|`(T) -> EventLoopFuture<U>`|Mapuje wartość future na inną wartość _future_.|
|[`transform`](#transform)|`U`|Mapuje future na już dostępną wartość.|

Jeśli spojrzysz na sygnatury metod `map` i `flatMap` na `Optional<T>` i `Array<T>`, zauważysz, że są one bardzo podobne do metod dostępnych na `EventLoopFuture<T>`.

### map

Metoda `map` pozwala przekształcić wartość future na inną wartość. Ponieważ wartość future może nie być jeszcze dostępna (może być wynikiem zadania asynchronicznego), musimy dostarczyć closure, który przyjmie tę wartość.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Map the future string to an integer
let futureInt = futureString.map { string in
    print(string) // The actual String
    return Int(string) ?? 0
}

/// We now have a future integer
print(futureInt) // EventLoopFuture<Int>
```

### flatMapThrowing

Metoda `flatMapThrowing` pozwala przekształcić wartość future na inną wartość _lub_ rzucić błąd.

!!! info
    Ponieważ rzucenie błędu musi wewnętrznie utworzyć nowy future, ta metoda ma przedrostek `flatMap`, mimo że closure nie zwraca future.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Map the future string to an integer
let futureInt = futureString.flatMapThrowing { string in
    print(string) // The actual String
    // Convert the string to an integer or throw an error
    guard let int = Int(string) else {
        throw Abort(...)
    }
    return int
}

/// We now have a future integer
print(futureInt) // EventLoopFuture<Int>
```

### flatMap

Metoda `flatMap` pozwala przekształcić wartość future na inną wartość future. Nosi nazwę „flat” map, ponieważ pozwala uniknąć tworzenia zagnieżdżonych futures (np. `EventLoopFuture<EventLoopFuture<T>>`). Innymi słowy, pomaga utrzymać Twoje generyki płaskimi.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Assume we have created an HTTP client
let client: Client = ... 

/// flatMap the future string to a future response
let futureResponse = futureString.flatMap { string in
    client.get(string) // EventLoopFuture<ClientResponse>
}

/// We now have a future response
print(futureResponse) // EventLoopFuture<ClientResponse>
```

!!! info
    Gdybyśmy zamiast tego użyli `map` w powyższym przykładzie, otrzymalibyśmy: `EventLoopFuture<EventLoopFuture<ClientResponse>>`.

Aby wywołać rzucającą metodę wewnątrz `flatMap`, użyj słów kluczowych `do` / `catch` w Swifcie i utwórz [ukończony future](#makefuture).

```swift
/// Assume future string and client from previous example.
let futureResponse = futureString.flatMap { string in
    let url: URL
    do {
        // Some synchronous throwing method.
        url = try convertToURL(string)
    } catch {
        // Use event loop to make pre-completed future.
        return eventLoop.makeFailedFuture(error)
    }
    return client.get(url) // EventLoopFuture<ClientResponse>
}
```
    
### transform

Metoda `transform` pozwala zmodyfikować wartość future, ignorując istniejącą wartość. Jest to szczególnie przydatne do transformowania wyników `EventLoopFuture<Void>`, gdzie rzeczywista wartość future nie ma znaczenia.

!!! tip
    `EventLoopFuture<Void>`, czasami nazywany sygnałem, to future, którego jedynym celem jest powiadomienie Cię o zakończeniu lub niepowodzeniu jakiejś operacji asynchronicznej.

```swift
/// Assume we get a void future back from some API
let userDidSave: EventLoopFuture<Void> = ...

/// Transform the void future to an HTTP status
let futureStatus = userDidSave.transform(to: HTTPStatus.ok)
print(futureStatus) // EventLoopFuture<HTTPStatus>
```   

Mimo że dostarczyliśmy do `transform` wartość, która jest już dostępna, nadal jest to _transformacja_. Future nie zakończy się, dopóki wszystkie poprzednie futures się nie zakończą (lub nie zawiodą).

### Łańcuchowanie

Świetną cechą transformacji na futures jest to, że mogą być łańcuchowane. Pozwala to w łatwy sposób wyrazić wiele konwersji i podzadań.

Zmodyfikujmy powyższe przykłady, aby zobaczyć, jak możemy wykorzystać łańcuchowanie.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Assume we have created an HTTP client
let client: Client = ... 

/// Transform the string to a url, then to a response
let futureResponse = futureString.flatMapThrowing { string in
    guard let url = URL(string: string) else {
        throw Abort(.badRequest, reason: "Invalid URL string: \(string)")
    }
    return url
}.flatMap { url in
    client.get(url)
}

print(futureResponse) // EventLoopFuture<ClientResponse>
```

Po pierwszym wywołaniu map tworzony jest tymczasowy `EventLoopFuture<URL>`. Ten future jest następnie natychmiast flat-mapowany na `EventLoopFuture<Response>`.
    
## Future

Przyjrzyjmy się innym metodom służącym do pracy z `EventLoopFuture<T>`.

### makeFuture

Możesz użyć event loopa, aby utworzyć wcześniej ukończony future z wartością lub błędem.

```swift
// Create a pre-succeeded future.
let futureString: EventLoopFuture<String> = eventLoop.makeSucceededFuture("hello")

// Create a pre-failed future.
let futureString: EventLoopFuture<String> = eventLoop.makeFailedFuture(error)
```

### whenComplete

Możesz użyć `whenComplete`, aby dodać callback, który zostanie wykonany, gdy future zakończy się sukcesem lub niepowodzeniem.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

futureString.whenComplete { result in
    switch result {
    case .success(let string):
        print(string) // The actual String
    case .failure(let error):
        print(error) // A Swift Error
    }
}
```

!!! note
    Możesz dodać do future tyle callbacków, ile chcesz.

### Get

Jeśli nie ma alternatywy opartej na współbieżności dla danego API, możesz oczekiwać na wartość future za pomocą `try await future.get()`.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Wait for the string to be ready
let string: String = try await futureString.get()
print(string) /// String
```
    
### Wait

!!! warning
    Funkcja `wait()` jest przestarzała, zobacz [`Get`](#get), aby poznać zalecane podejście.

Możesz użyć `.wait()`, aby synchronicznie poczekać na ukończenie future. Ponieważ future może się nie powieść, to wywołanie jest rzucające.

```swift
/// Assume we get a future string back from some API
let futureString: EventLoopFuture<String> = ...

/// Block until the string is ready
let string = try futureString.wait()
print(string) /// String
```

`wait()` może być używane tylko w wątku tła lub w wątku głównym, tj. w `configure.swift`. _Nie_ może być używane w wątku event loopa, tj. w closures tras.

!!! warning
    Próba wywołania `wait()` w wątku event loopa spowoduje błąd asercji (assertion failure).
    
## Promise

Przez większość czasu będziesz transformować futures zwracane przez wywołania API Vapora. Jednak w pewnym momencie możesz potrzebować stworzyć własny promise.

Aby utworzyć promise, potrzebujesz dostępu do `EventLoop`. Możesz uzyskać dostęp do event loopa z `Application` lub `Request`, w zależności od kontekstu.

```swift
let eventLoop: EventLoop 

// Create a new promise for some string.
let promiseString = eventLoop.makePromise(of: String.self)
print(promiseString) // EventLoopPromise<String>
print(promiseString.futureResult) // EventLoopFuture<String>

// Completes the associated future.
promiseString.succeed("Hello")

// Fails the associated future.
promiseString.fail(...)
```

!!! info
    Promise może zostać ukończony tylko raz. Wszelkie kolejne próby ukończenia zostaną zignorowane.

Promises mogą zostać ukończone (`succeed` / `fail`) z dowolnego wątku. Dlatego właśnie promises wymagają event loopa do inicjalizacji. Promises zapewniają, że akcja ukończenia zostanie zwrócona do jego event loopa w celu wykonania.

## Event Loop

Kiedy Twoja aplikacja się uruchamia, zwykle tworzy jeden event loop dla każdego rdzenia procesora, na którym działa. Każdy event loop ma dokładnie jeden wątek. Jeśli znasz event loopy z Node.js, te w Vaporze są do nich podobne. Główna różnica polega na tym, że Vapor może uruchamiać wiele event loopów w jednym procesie, ponieważ Swift wspiera wielowątkowość.

Za każdym razem, gdy klient łączy się z Twoim serwerem, zostanie przypisany do jednego z event loopów. Od tego momentu cała komunikacja między serwerem a tym klientem będzie odbywać się na tym samym event loopie (a co za tym idzie, na wątku tego event loopa).

Event loop jest odpowiedzialny za śledzenie stanu każdego podłączonego klienta. Jeśli istnieje żądanie od klienta czekające na odczytanie, event loop wywołuje powiadomienie o odczycie, powodując odczytanie danych. Gdy całe żądanie zostanie odczytane, wszystkie futures oczekujące na dane tego żądania zostaną ukończone.

W closures tras możesz uzyskać dostęp do bieżącego event loopa poprzez `Request`.

```swift
req.eventLoop.makePromise(of: ...)
```

!!! warning
    Vapor oczekuje, że closures tras pozostaną na `req.eventLoop`. Jeśli zmieniasz wątki, musisz zapewnić, że dostęp do `Request` oraz ostateczny future odpowiedzi odbywają się na event loopie żądania.

Poza closures tras możesz uzyskać jeden z dostępnych event loopów poprzez `Application`.

```swift
app.eventLoopGroup.next().makePromise(of: ...)
```

### hop

Możesz zmienić event loop future za pomocą `hop`.

```swift
futureString.hop(to: otherEventLoop)
```

## Blokowanie

Wywoływanie blokującego kodu na wątku event loopa może uniemożliwić Twojej aplikacji odpowiadanie na przychodzące żądania w odpowiednim czasie. Przykładem blokującego wywołania może być coś w rodzaju `libc.sleep(_:)`.

```swift
app.get("hello") { req in
    /// Puts the event loop's thread to sleep.
    sleep(5)
    
    /// Returns a simple string once the thread re-awakens.
    return "Hello, world!"
}
```

`sleep(_:)` to polecenie, które blokuje bieżący wątek na podaną liczbę sekund. Jeśli wykonujesz tego rodzaju blokującą pracę bezpośrednio na event loopie, event loop nie będzie w stanie odpowiadać żadnemu innemu klientowi przypisanemu do niego przez czas trwania blokującej pracy. Innymi słowy, jeśli wykonasz `sleep(5)` na event loopie, wszyscy inni klienci podłączeni do tego event loopa (być może setki lub tysiące) zostaną opóźnieni o co najmniej 5 sekund.

Upewnij się, że wszelka blokująca praca jest wykonywana w tle. Użyj promises, aby powiadomić event loop, kiedy ta praca zostanie ukończona w sposób nieblokujący.

```swift
app.get("hello") { req -> EventLoopFuture<String> in
    /// Dispatch some work to happen on a background thread
    return req.application.threadPool.runIfActive(eventLoop: req.eventLoop) {
        /// Puts the background thread to sleep
        /// This will not affect any of the event loops
        sleep(5)
        
        /// When the "blocking work" has completed,
        /// return the result.
        return "Hello world!"
    }
}
```

Nie wszystkie blokujące wywołania będą tak oczywiste jak `sleep(_:)`. Jeśli podejrzewasz, że używane przez Ciebie wywołanie może być blokujące, poszukaj informacji na temat tej metody lub kogoś zapytaj. Poniższe sekcje omawiają bardziej szczegółowo, w jaki sposób metody mogą blokować.

### Ograniczenie przez I/O

Blokowanie ograniczone przez I/O oznacza oczekiwanie na wolny zasób, taki jak sieć lub dysk twardy, który może być o rzędy wielkości wolniejszy niż CPU. Blokowanie CPU podczas oczekiwania na te zasoby skutkuje zmarnowanym czasem.

!!! danger
    Nigdy nie wykonuj blokujących wywołań ograniczonych przez I/O bezpośrednio na event loopie.

Wszystkie pakiety Vapora są zbudowane na SwiftNIO i używają nieblokującego I/O. Istnieje jednak wiele pakietów Swift i bibliotek C, które używają blokującego I/O. Jest szansa, że jeśli funkcja wykonuje operacje dyskowe lub sieciowe i używa synchronicznego API (bez callbacków czy futures), jest blokująca.
    
### Ograniczenie przez CPU

Przez większość czasu podczas obsługi żądania oczekuje się na zewnętrzne zasoby, takie jak zapytania do bazy danych i żądania sieciowe, do załadowania. Ponieważ Vapor i SwiftNIO są nieblokujące, ten czas przestoju może zostać wykorzystany do obsłużenia innych przychodzących żądań. Jednak niektóre trasy w Twojej aplikacji mogą wymagać intensywnej pracy obciążającej CPU w wyniku żądania.

Podczas gdy event loop przetwarza pracę obciążającą CPU, nie będzie w stanie odpowiadać na inne przychodzące żądania. Zwykle nie stanowi to problemu, ponieważ procesory są szybkie, a większość pracy obciążającej CPU wykonywanej przez aplikacje webowe jest lekka. Może to jednak stać się problemem, jeśli trasy z długo trwającą pracą obciążającą CPU uniemożliwiają szybkie odpowiadanie na żądania do szybszych tras.

Zidentyfikowanie długo trwającej pracy obciążającej CPU w Twojej aplikacji i przeniesienie jej do wątków w tle może pomóc poprawić niezawodność i responsywność Twojego serwisu. Praca obciążająca CPU jest bardziej niejednoznacznym obszarem niż praca ograniczona przez I/O i ostatecznie to od Ciebie zależy, gdzie chcesz wyznaczyć granicę.

Częstym przykładem intensywnej pracy obciążającej CPU jest hashowanie Bcrypt podczas rejestracji i logowania użytkownika. Bcrypt jest celowo bardzo wolny i intensywnie obciąża CPU ze względów bezpieczeństwa. Może to być najbardziej intensywna pod względem obciążenia CPU praca, jaką faktycznie wykonuje prosta aplikacja webowa. Przeniesienie hashowania do wątku w tle może pozwolić CPU przeplatać pracę event loopa podczas obliczania hashy, co skutkuje wyższą współbieżnością.
