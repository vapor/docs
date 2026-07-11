# Request

Obiekt [`Request`](https://api.vapor.codes/vapor/documentation/vapor/request) jest przekazywany do każdego [route handlera](../basics/routing.md).

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

Jest to główne okno do reszty funkcjonalności Vapora. Zawiera API dla [ciała żądania](../basics/content.md), [parametrów zapytania](../basics/content.md#query), [loggera](../basics/logging.md), [klienta HTTP](../basics/client.md), [Authenticatora](../security/authentication.md) i wielu innych. Dostęp do tej funkcjonalności poprzez request utrzymuje obliczenia na odpowiednim event loopie i pozwala na jej mockowanie na potrzeby testów. Możesz nawet dodać własne [serwisy](../advanced/services.md) do `Request` za pomocą rozszerzeń.

Pełną dokumentację API dla `Request` znajdziesz [tutaj](https://api.vapor.codes/vapor/documentation/vapor/request).

## Application

Właściwość `Request.application` przechowuje referencję do [`Application`](https://api.vapor.codes/vapor/documentation/vapor/application). Obiekt ten zawiera całą konfigurację i podstawową funkcjonalność aplikacji. Większość z nich powinna być ustawiana tylko w `configure.swift`, zanim aplikacja w pełni się uruchomi, a wiele niskopoziomowych API nie będzie potrzebnych w większości aplikacji. Jedną z najbardziej przydatnych właściwości jest `Application.eventLoopGroup`, której można użyć do pobrania `EventLoop` dla procesów potrzebujących nowego poprzez metodę `any()`. Zawiera ona również [`Environment`](../basics/environment.md).

## Body

Jeśli chcesz mieć bezpośredni dostęp do ciała żądania jako `ByteBuffer`, możesz użyć `Request.body.data`. Może to być wykorzystane do strumieniowania danych z ciała żądania do pliku (chociaż powinieneś zamiast tego użyć w tym celu właściwości [`fileio`](../advanced/files.md) na request) lub do innego klienta HTTP.

## Cookies

Chociaż najbardziej przydatnym zastosowaniem cookies są wbudowane [sesje](../advanced/sessions.md#configuration), możesz również uzyskać bezpośredni dostęp do cookies poprzez `Request.cookies`.

```swift
app.get("my-cookie") { req -> String in
    guard let cookie = req.cookies["my-cookie"] else {
        throw Abort(.badRequest)
    }
    if let expiration = cookie.expires, expiration < Date() {
        throw Abort(.badRequest)
    }
    return cookie.string
}
```

## Headers

Obiekt `HTTPHeaders` jest dostępny pod `Request.headers`. Zawiera on wszystkie nagłówki wysłane wraz z żądaniem. Może być użyty na przykład do uzyskania dostępu do nagłówka `Content-Type`.

```swift
app.get("json") { req -> String in
    guard let contentType = req.headers.contentType, contentType == .json else {
        throw Abort(.badRequest)
    }
    return "JSON"
}
```

Dalszą dokumentację dla `HTTPHeaders` znajdziesz [tutaj](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niohttp1/httpheaders). Vapor dodaje również kilka rozszerzeń do `HTTPHeaders`, aby ułatwić pracę z najczęściej używanymi nagłówkami; lista jest dostępna [tutaj](https://api.vapor.codes/vapor/documentation/vapor/niohttp1/httpheaders#instance-properties)

## Adres IP

Obiekt `SocketAddress` reprezentujący klienta jest dostępny poprzez `Request.remoteAddress`, co może być przydatne do logowania lub ograniczania liczby żądań przy użyciu reprezentacji tekstowej `Request.remoteAddress.ipAddress`. Może on niedokładnie reprezentować adres IP klienta, jeśli aplikacja znajduje się za reverse proxy.

```swift
app.get("ip") { req -> String in
    return req.remoteAddress.ipAddress
}
```

Dalszą dokumentację dla `SocketAddress` znajdziesz [tutaj](https://swiftpackageindex.com/apple/swift-nio/2.56.0/documentation/niocore/socketaddress).
