# Klient

API klienta Vapora pozwala na wykonywanie żądań HTTP do zewnętrznych zasobów. Jest zbudowane na bazie [async-http-client](https://github.com/swift-server/async-http-client) i integruje się z API [content](content.md).

## Przegląd

Dostęp do domyślnego klienta możesz uzyskać poprzez `Application` lub w route handlerze poprzez `Request`.

```swift
app.client // Client

app.get("test") { req in
    req.client // Client
}
```

Klient aplikacji jest przydatny do wykonywania żądań HTTP podczas konfiguracji. Jeśli wykonujesz żądania HTTP w route handlerze, zawsze używaj klienta requestu.

### Metody

Aby wykonać żądanie `GET`, przekaż żądany URL do metody pomocniczej `get`.

```swift
let response = try await req.client.get("https://httpbin.org/status/200")
```

Istnieją metody dla każdego z czasowników HTTP, takich jak `get`, `post` i `delete`. Odpowiedź klienta jest zwracana jako future i zawiera status HTTP, nagłówki oraz ciało.

### Content

API [content](content.md) Vapora jest dostępne do obsługi danych w żądaniach i odpowiedziach klienta. Aby zakodować content, parametry zapytania lub dodać nagłówki do żądania, użyj closure `beforeSend`.

```swift
let response = try await req.client.post("https://httpbin.org/status/200") { req in
    // Zakoduj query string do URL żądania.
    try req.query.encode(["q": "test"])

    // Zakoduj JSON do ciała żądania.
    try req.content.encode(["hello": "world"])
    
    // Dodaj nagłówek auth do żądania
    let auth = BasicAuthorization(username: "something", password: "somethingelse")
    req.headers.basicAuthorization = auth
}
// Obsłuż odpowiedź.
```

W podobny sposób możesz również zdekodować ciało odpowiedzi, używając `Content`:

```swift
let response = try await req.client.get("https://httpbin.org/json")
let json = try response.content.decode(MyJSONResponse.self)
```

Jeśli używasz futures, możesz skorzystać z `flatMapThrowing`:

```swift
return req.client.get("https://httpbin.org/json").flatMapThrowing { res in
    try res.content.decode(MyJSONResponse.self)
}.flatMap { json in
    // Użyj JSON tutaj
}
```

## Konfiguracja

Możesz skonfigurować bazowy klient HTTP poprzez aplikację.

```swift
// Wyłącz automatyczne podążanie za przekierowaniami.
app.http.client.configuration.redirectConfiguration = .disallow
```

Zwróć uwagę, że musisz skonfigurować domyślnego klienta _przed_ jego pierwszym użyciem.

