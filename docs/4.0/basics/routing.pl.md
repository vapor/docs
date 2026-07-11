# Routing

Routing to proces znajdowania odpowiedniego handlera żądania dla przychodzącego żądania. Rdzeniem routingu w Vaporze jest wysokowydajny router oparty na strukturze trie z [RoutingKit](https://github.com/vapor/routing-kit).

## Przegląd

Aby zrozumieć, jak działa routing w Vaporze, warto najpierw poznać kilka podstaw dotyczących żądań HTTP. Spójrzmy na poniższy przykład żądania.

```http
GET /hello/vapor HTTP/1.1
host: vapor.codes
content-length: 0
```

To proste żądanie HTTP typu `GET` do adresu URL `/hello/vapor`. Jest to rodzaj żądania HTTP, jakie wykonałaby twoja przeglądarka, gdybyś skierował ją na następujący adres URL.

```
http://vapor.codes/hello/vapor
```

### Metoda HTTP

Pierwszą częścią żądania jest metoda HTTP. `GET` jest najczęściej używaną metodą HTTP, ale istnieje kilka innych, których będziesz często używać. Te metody HTTP są często kojarzone z semantyką [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete).

|Metoda|CRUD|
|-|-|
|`GET`|Read (odczyt)|
|`POST`|Create (tworzenie)|
|`PUT`|Replace (zastąpienie)|
|`PATCH`|Update (aktualizacja)|
|`DELETE`|Delete (usunięcie)|

### Ścieżka żądania

Zaraz po metodzie HTTP znajduje się URI żądania. Składa się ono ze ścieżki zaczynającej się od `/` oraz opcjonalnego ciągu zapytania po `?`. Metoda HTTP i ścieżka to elementy, których Vapor używa do routingu żądań.

Po URI następuje wersja HTTP, po niej zero lub więcej nagłówków, a na końcu treść (body). Ponieważ jest to żądanie `GET`, nie posiada ono treści.

### Metody routera

Przyjrzyjmy się, jak to żądanie mogłoby zostać obsłużone w Vaporze.

```swift
app.get("hello", "vapor") { req in 
    return "Hello, vapor!"
}
```

Wszystkie popularne metody HTTP są dostępne jako metody na `Application`. Przyjmują one jeden lub więcej argumentów typu string, reprezentujących ścieżkę żądania rozdzieloną znakiem `/`.

Zauważ, że możesz zapisać to również za pomocą `on`, po którym następuje metoda.

```swift
app.on(.GET, "hello", "vapor") { ... }
```

Po zarejestrowaniu tej trasy, powyższe przykładowe żądanie HTTP skutkuje następującą odpowiedzią HTTP.

```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, vapor!
```

### Parametry trasy

Skoro udało nam się już przekierować żądanie na podstawie metody HTTP i ścieżki, spróbujmy uczynić ścieżkę dynamiczną. Zauważ, że nazwa "vapor" jest zaszyta na stałe zarówno w ścieżce, jak i w odpowiedzi. Uczyńmy to dynamicznym, tak aby można było odwiedzić `/hello/<dowolna nazwa>` i otrzymać odpowiedź.

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

Używając komponentu ścieżki z prefiksem `:`, wskazujemy routerowi, że jest to komponent dynamiczny. Każdy ciąg znaków podany w tym miejscu będzie pasował do tej trasy. Możemy następnie użyć `req.parameters`, aby uzyskać dostęp do wartości tego ciągu.

Jeśli ponownie uruchomisz przykładowe żądanie, nadal otrzymasz odpowiedź witającą vapor. Możesz jednak teraz podać dowolną nazwę po `/hello/` i zobaczyć ją zawartą w odpowiedzi. Spróbujmy z `/hello/swift`.

```http
GET /hello/swift HTTP/1.1
content-length: 0
```
```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, swift!
```

Teraz, gdy rozumiesz już podstawy, zapoznaj się z każdą sekcją, aby dowiedzieć się więcej o parametrach, grupach i innych zagadnieniach.

## Trasy

Trasa określa handler żądania dla danej metody HTTP i ścieżki URI. Może również przechowywać dodatkowe metadane.

### Metody

Trasy można rejestrować bezpośrednio w `Application` za pomocą różnych metod pomocniczych dla metod HTTP.

```swift
// odpowiada na GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
    ...
}
```

Handlery tras obsługują zwracanie wszystkiego, co jest `ResponseEncodable`. Obejmuje to `Content`, domknięcie `async` oraz dowolne `EventLoopFuture`, których przyszła wartość jest `ResponseEncodable`.

Możesz określić typ zwracany przez trasę, używając `-> T` przed `in`. Może to być przydatne w sytuacjach, gdy kompilator nie jest w stanie samodzielnie ustalić typu zwracanego.

```swift
app.get("foo") { req -> String in
    return "bar"
}
```

Oto obsługiwane pomocnicze metody tras:

- `get`
- `post`
- `patch`
- `put`
- `delete`

Oprócz pomocniczych metod dla metod HTTP, istnieje funkcja `on`, która przyjmuje metodę HTTP jako parametr wejściowy.

```swift
// odpowiada na OPTIONS /foo/bar/baz
app.on(.OPTIONS, "foo", "bar", "baz") { req in
    ...
}
```

### Komponent ścieżki

Każda metoda rejestrująca trasę przyjmuje wariadyczną listę `PathComponent`. Ten typ jest wyrażalny za pomocą literału łańcuchowego i ma cztery przypadki:

- Stały (`foo`)
- Parametr (`:foo`)
- Dowolny (`*`)
- Catchall (`**`)

#### Stały

Jest to statyczny komponent trasy. Dozwolone są tylko żądania z dokładnie pasującym ciągiem znaków w tej pozycji.

```swift
// odpowiada na GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
    ...
}
```

#### Parametr

Jest to dynamiczny komponent trasy. Dowolny ciąg znaków w tej pozycji jest dozwolony. Komponent ścieżki będący parametrem jest oznaczany prefiksem `:`. Ciąg znaków następujący po `:` będzie użyty jako nazwa parametru. Możesz użyć tej nazwy, aby później pobrać wartość parametru z żądania.

```swift
// odpowiada na GET /foo/bar/baz
// odpowiada na GET /foo/qux/baz
// ...
app.get("foo", ":bar", "baz") { req in
    ...
}
```

#### Dowolny

Jest to bardzo podobne do parametru, z tą różnicą, że wartość jest odrzucana. Ten komponent ścieżki jest oznaczany po prostu jako `*`.

```swift
// odpowiada na GET /foo/bar/baz
// odpowiada na GET /foo/qux/baz
// ...
app.get("foo", "*", "baz") { req in
    ...
}
```

#### Catchall

Jest to dynamiczny komponent trasy, który dopasowuje jeden lub więcej komponentów. Jest oznaczany po prostu jako `**`. Dowolny ciąg znaków w tej lub kolejnych pozycjach zostanie dopasowany w żądaniu.

```swift
// odpowiada na GET /foo/bar
// odpowiada na GET /foo/bar/baz
// ...
app.get("foo", "**") { req in 
    ...
}
```

### Parametry

Gdy używasz komponentu ścieżki będącego parametrem (z prefiksem `:`), wartość URI w tej pozycji zostanie zapisana w `req.parameters`. Możesz użyć nazwy komponentu ścieżki, aby uzyskać dostęp do tej wartości.

```swift
// odpowiada na GET /hello/foo
// odpowiada na GET /hello/bar
// ...
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

!!! tip
    Możemy być pewni, że `req.parameters.get` nigdy nie zwróci tutaj `nil`, ponieważ nasza ścieżka trasy zawiera `:name`. Jeśli jednak korzystasz z parametrów trasy w middleware lub w kodzie wywoływanym przez wiele tras, będziesz musiał obsłużyć możliwość wystąpienia `nil`.

!!! tip
    Jeśli chcesz pobrać parametry zapytania URL, np. `/hello/?name=foo`, musisz użyć API `Content` Vapora, aby obsłużyć dane zakodowane w URL w ciągu zapytania adresu URL. Zobacz [dokumentację `Content`](content.md), aby dowiedzieć się więcej.

`req.parameters.get` obsługuje również automatyczne rzutowanie parametru na typy `LosslessStringConvertible`.

```swift
// odpowiada na GET /number/42
// odpowiada na GET /number/1337
// ...
app.get("number", ":x") { req -> String in 
    guard let int = req.parameters.get("x", as: Int.self) else {
        throw Abort(.badRequest)
    }
    return "\(int) is a great number"
}
```

Wartości URI dopasowane przez Catchall (`**`) zostaną zapisane w `req.parameters` jako `[String]`. Możesz użyć `req.parameters.getCatchall`, aby uzyskać dostęp do tych komponentów.

```swift
// odpowiada na GET /hello/foo
// odpowiada na GET /hello/foo/bar
// ...
app.get("hello", "**") { req -> String in
    let name = req.parameters.getCatchall().joined(separator: " ")
    return "Hello, \(name)!"
}
```

### Strumieniowanie treści żądania

Podczas rejestrowania trasy za pomocą metody `on`, możesz określić, w jaki sposób treść żądania (request body) powinna być obsługiwana. Domyślnie treść żądania jest zbierana do pamięci przed wywołaniem twojego handlera. Jest to przydatne, ponieważ pozwala na synchroniczne dekodowanie zawartości żądania, mimo że twoja aplikacja odczytuje przychodzące żądania asynchronicznie.

Domyślnie Vapor ogranicza rozmiar zbieranej strumieniowo treści do 16KB. Możesz to skonfigurować za pomocą `app.routes`.

```swift
// Zwiększa limit zbierania strumieniowanej treści do 500kb
app.routes.defaultMaxBodySize = "500kb"
```

Jeśli zbierana strumieniowo treść przekroczy skonfigurowany limit, zostanie zgłoszony błąd `413 Payload Too Large`.

Aby skonfigurować strategię zbierania treści żądania dla pojedynczej trasy, użyj parametru `body`.

```swift
// Zbiera strumieniowane treści (do 1mb rozmiaru) przed wywołaniem tej trasy.
app.on(.POST, "listings", body: .collect(maxSize: "1mb")) { req in
    // Obsłuż żądanie. 
}
```

Jeśli do `collect` zostanie przekazane `maxSize`, nadpisze ono domyślną wartość aplikacji dla tej trasy. Aby użyć domyślnej wartości aplikacji, pomiń argument `maxSize`.

W przypadku dużych żądań, takich jak przesyłanie plików, zbieranie treści żądania w buforze może potencjalnie obciążać pamięć systemową. Aby zapobiec zbieraniu treści żądania, użyj strategii `stream`.

```swift
// Treść żądania nie zostanie zebrana w buforze.
app.on(.POST, "upload", body: .stream) { req in
    ...
}
```

Gdy treść żądania jest strumieniowana, `req.body.data` będzie miało wartość `nil`. Musisz użyć `req.body.drain`, aby obsłużyć każdy fragment (chunk) w miarę jego przesyłania do twojej trasy.

### Routing bez rozróżniania wielkości liter

Domyślne zachowanie routingu jest zarówno wrażliwe na wielkość liter, jak i zachowuje wielkość liter. Komponenty ścieżki typu `Constant` mogą alternatywnie być obsługiwane w sposób nierozróżniający wielkości liter, przy jednoczesnym zachowaniu wielkości liter, na potrzeby routingu; aby włączyć to zachowanie, skonfiguruj je przed uruchomieniem aplikacji:
```swift
app.routes.caseInsensitive = true
```
Nie są wprowadzane żadne zmiany do oryginalnego żądania; handlery tras otrzymają komponenty ścieżki żądania bez modyfikacji.


### Przeglądanie tras

Możesz uzyskać dostęp do tras swojej aplikacji, korzystając z usługi `Routes` lub używając `app.routes`.

```swift
print(app.routes.all) // [Route]
```

Vapor zawiera również polecenie `routes`, które wypisuje wszystkie dostępne trasy w postaci tabeli sformatowanej w ASCII.

```sh
$ swift run App routes
+--------+----------------+
| GET    | /              |
+--------+----------------+
| GET    | /hello         |
+--------+----------------+
| GET    | /todos         |
+--------+----------------+
| POST   | /todos         |
+--------+----------------+
| DELETE | /todos/:todoID |
+--------+----------------+
```

### Metadane

Wszystkie metody rejestrujące trasy zwracają utworzony obiekt `Route`. Pozwala to na dodanie metadanych do słownika `userInfo` trasy. Dostępne są pewne domyślne metody, takie jak dodawanie opisu.

```swift
app.get("hello", ":name") { req in
    ...
}.description("says hello")
```

## Grupy tras

Grupowanie tras pozwala na utworzenie zbioru tras z prefiksem ścieżki lub konkretnym middleware. Grupowanie obsługuje zarówno składnię opartą na builderze, jak i na domknięciach (closure).

Wszystkie metody grupujące zwracają `RouteBuilder`, co oznacza, że możesz w dowolny sposób mieszać, dopasowywać i zagnieżdżać swoje grupy z innymi metodami budującymi trasy.

### Prefiks ścieżki

Grupy tras z prefiksem ścieżki pozwalają na dodanie jednego lub więcej komponentów ścieżki przed grupą tras.

```swift
let users = app.grouped("users")
// GET /users
users.get { req in
    ...
}
// POST /users
users.post { req in
    ...
}
// GET /users/:id
users.get(":id") { req in
    let id = req.parameters.get("id")!
    ...
}
```

Każdy komponent ścieżki, który możesz przekazać do metod takich jak `get` czy `post`, może zostać przekazany do `grouped`. Istnieje również alternatywna, oparta na domknięciach składnia.

```swift
app.group("users") { users in
    // GET /users
    users.get { req in
        ...
    }
    // POST /users
    users.post { req in
        ...
    }
    // GET /users/:id
    users.get(":id") { req in
        let id = req.parameters.get("id")!
        ...
    }
}
```

Zagnieżdżanie grup tras z prefiksem ścieżki pozwala na zwięzłe definiowanie API typu CRUD.

```swift
app.group("users") { users in
    // GET /users
    users.get { ... }
    // POST /users
    users.post { ... }

    users.group(":id") { user in
        // GET /users/:id
        user.get { ... }
        // PATCH /users/:id
        user.patch { ... }
        // PUT /users/:id
        user.put { ... }
    }
}
```

### Middleware

Oprócz dodawania prefiksów komponentów ścieżki, możesz również dodawać middleware do grup tras.

```swift
app.get("fast-thing") { req in
    ...
}
app.group(RateLimitMiddleware(requestsPerMinute: 5)) { rateLimited in
    rateLimited.get("slow-thing") { req in
        ...
    }
}
```


Jest to szczególnie przydatne do ochrony podzbiorów twoich tras za pomocą różnych middleware'ów uwierzytelniających.

```swift
app.post("login") { ... }
let auth = app.grouped(AuthMiddleware())
auth.get("dashboard") { ... }
auth.get("logout") { ... }
```

## Przekierowania

Przekierowania są przydatne w wielu scenariuszach, na przykład przy przekierowywaniu starych lokalizacji do nowych ze względu na SEO, przekierowywaniu niezalogowanego użytkownika na stronę logowania, czy zachowaniu zgodności wstecznej z nową wersją twojego API.

Aby przekierować żądanie, użyj:

```swift
req.redirect(to: "/some/new/path")
```

Możesz również określić typ przekierowania, na przykład, aby przekierować stronę na stałe (tak, aby twoje SEO zostało poprawnie zaktualizowane), użyj:

```swift
req.redirect(to: "/some/new/path", redirectType: .permanent)
```

Dostępne rodzaje `Redirect`:

* `.permanent` - zwraca przekierowanie **301 Permanent**
* `.normal` - zwraca przekierowanie **303 see other**. Jest to domyślne zachowanie w Vaporze i informuje klienta, aby podążył za przekierowaniem za pomocą żądania **GET**.
* `.temporary` - zwraca przekierowanie **307 Temporary**. Informuje to klienta, aby zachował metodę HTTP użytą w żądaniu.

> Aby wybrać odpowiedni kod statusu przekierowania, sprawdź [pełną listę](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes#3xx_redirection)
