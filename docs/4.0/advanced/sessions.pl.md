# Sesje

Sesje pozwalają na przechowywanie danych użytkownika pomiędzy wieloma żądaniami. Sesje działają poprzez tworzenie i zwracanie unikalnego ciasteczka wraz z odpowiedzią HTTP, gdy inicjowana jest nowa sesja. Przeglądarki automatycznie wykrywają to ciasteczko i dołączają je do przyszłych żądań. Pozwala to Vaporowi na automatyczne przywracanie sesji konkretnego użytkownika w handlerze żądania.

Sesje świetnie sprawdzają się w aplikacjach front-endowych zbudowanych w Vaporze, które serwują HTML bezpośrednio do przeglądarek internetowych. W przypadku API zalecamy korzystanie z bezstanowego [uwierzytelniania opartego na tokenach](../security/authentication.md), aby przechowywać dane użytkownika pomiędzy żądaniami.

## Konfiguracja

Aby korzystać z sesji w trasie, żądanie musi przejść przez `SessionsMiddleware`. Najprostszym sposobem na to jest dodanie tego middleware globalnie. Zaleca się dodanie go po zadeklarowaniu fabryki ciasteczek (cookie factory). Wynika to z faktu, że Sessions jest strukturą, a więc typem wartościowym, a nie referencyjnym. Ponieważ jest to typ wartościowy, musisz ustawić wartość przed użyciem `SessionsMiddleware`.

```swift
app.middleware.use(app.sessions.middleware)
```

Jeśli tylko część twoich tras korzysta z sesji, możesz zamiast tego dodać `SessionsMiddleware` do grupy tras.

```swift
let sessions = app.grouped(app.sessions.middleware)
```

Ciasteczko HTTP generowane przez sesje można skonfigurować za pomocą `app.sessions.configuration`. Możesz zmienić nazwę ciasteczka oraz zadeklarować niestandardową funkcję generującą wartości ciasteczka.

```swift
// Change the cookie name to "foo".
app.sessions.configuration.cookieName = "foo"

// Configures cookie value creation.
app.sessions.configuration.cookieFactory = { sessionID in
    .init(string: sessionID.string, isSecure: true)
}

app.middleware.use(app.sessions.middleware)
```

Domyślnie Vapor używa `vapor_session` jako nazwy ciasteczka.

## Sterowniki

Sterowniki sesji odpowiadają za przechowywanie i pobieranie danych sesji na podstawie identyfikatora. Możesz tworzyć własne sterowniki, dostosowując się do protokołu `SessionDriver`.

!!! warning
    Sterownik sesji powinien zostać skonfigurowany _przed_ dodaniem `app.sessions.middleware` do twojej aplikacji.

### In-Memory

Vapor domyślnie korzysta z sesji przechowywanych w pamięci (in-memory). Sesje in-memory nie wymagają żadnej konfiguracji i nie zachowują się pomiędzy uruchomieniami aplikacji, co czyni je świetnym rozwiązaniem do testowania. Aby ręcznie włączyć sesje in-memory, użyj `.memory`:

```swift
app.sessions.use(.memory)
```

W przypadku zastosowań produkcyjnych warto przyjrzeć się innym sterownikom sesji, które wykorzystują bazy danych do przechowywania i współdzielenia sesji pomiędzy wieloma instancjami twojej aplikacji.

### Fluent

Fluent zawiera wsparcie dla przechowywania danych sesji w bazie danych twojej aplikacji. Ta sekcja zakłada, że masz już [skonfigurowany Fluent](../fluent/overview.md) i możesz połączyć się z bazą danych. Pierwszym krokiem jest włączenie sterownika sesji Fluent.

```swift
import Fluent

app.sessions.use(.fluent)
```

Skonfiguruje to sesje tak, aby korzystały z domyślnej bazy danych aplikacji. Aby wskazać konkretną bazę danych, przekaż jej identyfikator.

```swift
app.sessions.use(.fluent(.sqlite))
```

Na koniec dodaj migrację `SessionRecord` do migracji twojej bazy danych. Przygotuje to twoją bazę danych do przechowywania danych sesji w schemacie `_fluent_sessions`.

```swift
app.migrations.add(SessionRecord.migration)
```

Upewnij się, że po dodaniu nowej migracji uruchomisz migracje swojej aplikacji. Sesje będą teraz przechowywane w bazie danych twojej aplikacji, co pozwoli im zachować się pomiędzy ponownymi uruchomieniami oraz być współdzielone pomiędzy wieloma instancjami twojej aplikacji.

### Redis

Redis zapewnia wsparcie dla przechowywania danych sesji w skonfigurowanej instancji Redis. Ta sekcja zakłada, że masz już [skonfigurowany Redis](../redis/overview.md) i możesz wysyłać polecenia do instancji Redis.

Aby użyć Redis dla sesji, wybierz go podczas konfigurowania swojej aplikacji:

```swift
import Redis

app.sessions.use(.redis)
```

Skonfiguruje to sesje tak, aby korzystały ze sterownika sesji Redis z domyślnym zachowaniem.

!!! seealso
    Zapoznaj się z [Redis &rarr; Sesje](../redis/sessions.md), aby uzyskać bardziej szczegółowe informacje na temat Redis i sesji.

## Dane sesji

Teraz, gdy sesje są skonfigurowane, jesteś gotowy do przechowywania danych pomiędzy żądaniami. Nowe sesje są inicjowane automatycznie, gdy dane zostają dodane do `req.session`. Poniższy przykładowy handler trasy przyjmuje dynamiczny parametr trasy i dodaje jego wartość do `req.session.data`.

```swift
app.get("set", ":value") { req -> HTTPStatus in
    req.session.data["name"] = req.parameters.get("value")
    return .ok
}
```

Użyj poniższego żądania, aby zainicjować sesję z imieniem Vapor.

```http
GET /set/vapor HTTP/1.1
content-length: 0
```

Powinieneś otrzymać odpowiedź podobną do poniższej:

```http
HTTP/1.1 200 OK
content-length: 0
set-cookie: vapor-session=123; Expires=Fri, 10 Apr 2020 21:08:09 GMT; Path=/
```

Zauważ, że nagłówek `set-cookie` został automatycznie dodany do odpowiedzi po dodaniu danych do `req.session`. Dołączenie tego ciasteczka do kolejnych żądań umożliwi dostęp do danych sesji.

Dodaj poniższy handler trasy, aby uzyskać dostęp do wartości imienia z sesji.

```swift
app.get("get") { req -> String in
    req.session.data["name"] ?? "n/a"
}
```

Użyj poniższego żądania, aby uzyskać dostęp do tej trasy, pamiętając o przekazaniu wartości ciasteczka z poprzedniej odpowiedzi.

```http
GET /get HTTP/1.1
cookie: vapor-session=123
```

Powinieneś zobaczyć imię Vapor zwrócone w odpowiedzi. Możesz dodawać lub usuwać dane z sesji według potrzeb. Dane sesji zostaną automatycznie zsynchronizowane ze sterownikiem sesji przed zwróceniem odpowiedzi HTTP.

Aby zakończyć sesję, użyj `req.session.destroy`. Spowoduje to usunięcie danych ze sterownika sesji oraz unieważnienie ciasteczka sesji.

```swift
app.get("del") { req -> HTTPStatus in
    req.session.destroy()
    return .ok
}
```
