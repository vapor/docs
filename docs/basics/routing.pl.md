# Routing

Routing to proces znajdowania odpowiedniej obsługi odpowiedzi dla przychodzącego zapytania. Rdzeniem routingu Vapor jest wysokowydajny, trójwęzłowy router z [RoutingKit](https://github.com/vapor/routing-kit).

## Przegląd

Aby zrozumieć jak działa routing w Vapor, musisz najpierw zrozumieć jak działa podstawowe zapytanie HTTP. Popatrz na to przykładowe zapytanie poniżej.

```http
GET /hello/vapor HTTP/1.1
host: vapor.codes
content-length: 0
```

Jest to proste żądanie HTTP `GET` do adresu URL `/hello/vapor`. Jest to rodzaj żądania HTTP, które wykonałaby przeglądarka, gdybyś wskazał jej następujący adres URL.

```
http://vapor.codes/hello/vapor
```

### Metoda HTTP

Pierwszą częścią żądania jest metoda HTTP. `GET` jest najpopularniejszą metodą HTTP, ale istnieje kilka, z których będziesz często korzystać. Te metody HTTP są często powiązane z semantyką [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete).

|Method|CRUD|
|-|-|
|`GET`|Read|
|`POST`|Create|
|`PUT`|Replace|
|`PATCH`|Update|
|`DELETE`|Delete|

### Ścieżka żądania

Zaraz po metodzie HTTP znajduje się URI żądania. Składa się on ze ścieżki zaczynającej się od `/` i opcjonalnego ciągu zapytania po `?`. Metoda HTTP i ścieżka są tym, czego Vapor używa do kierowania żądań.

Po URI znajduje się wersja HTTP, po której następuje zero lub więcej nagłówków, a na końcu treść. Ponieważ jest to żądanie `GET`, nie ma ono treści.

### Metody routera

Przyjrzyjmy się, jak to żądanie może być obsługiwane w Vapor.

```swift
app.get("hello", "vapor") { req in
    return "Hello, vapor!"
}

```

Wszystkie popularne metody HTTP są dostępne jako metody w `Application`. Akceptują one jeden lub więcej argumentów łańcuchowych, które reprezentują ścieżkę żądania oddzieloną `/`. 

Zauważ, że możesz również napisać to używając `on`, po którym następuje metoda.

```swift
app.on(.GET, "hello", "vapor") { ... }
```

Po zarejestrowaniu tej ścieżki, przykładowe żądanie HTTP z góry spowoduje następującą odpowiedź HTTP.

```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Witaj, vapor!

```

### Parametry ścieżki

Teraz, gdy z powodzeniem przekierowaliśmy żądanie na podstawie metody HTTP i ścieżki, spróbujmy uczynić ścieżkę dynamiczną. Zauważ, że nazwa "vapor" jest zakodowana zarówno w ścieżce, jak i odpowiedzi. Uczyńmy to dynamicznym, aby można było odwiedzić `/hello/<any name>` i uzyskać odpowiedź.

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

Używając komponentu ścieżki z prefiksem `:`, wskazujemy routerowi, że jest to komponent dynamiczny. Każdy ciąg dostarczony tutaj będzie teraz pasował do tej trasy. Możemy następnie użyć `req.parameters`, aby uzyskać dostęp do wartości łańcucha.

Jeśli ponownie uruchomisz przykładowe żądanie, nadal otrzymasz odpowiedź, która mówi "hello to vapor". Można jednak teraz dołączyć dowolną nazwę po `/hello/` i zobaczyć ją w odpowiedzi. Spróbujmy `/hello/swift`.

```http
GET /hello/swift HTTP/1.1
content-length: 0

```

```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Witaj, swift!
```

Teraz, gdy rozumiesz już podstawy, zapoznaj się z każdą sekcją, aby dowiedzieć się więcej o parametrach, grupach i nie tylko.

## Ścieżki (routes)

Ścieżka określa program obsługi żądań dla danej metody HTTP i ścieżki URI. Może również przechowywać dodatkowe metadane.

### Metody

Trasy mogą być rejestrowane bezpośrednio w `Aplikacji` przy użyciu różnych helperów metod HTTP.

```swift
// odpowiada na GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
 ...
}
```

Trasy obsługujące zwracają wszystko, co jest `ResponseEncodable`. Obejmuje to `Content`, zamknięcie `async` i dowolne `EventLoopFuture`, gdzie przyszłą wartością jest `ResponseEncodable`.

Możesz określić typ powrotu trasy używając `-> T` przed `in`. Może to być przydatne w sytuacjach, w których kompilator nie może określić typu zwracanego.

```swift
app.get("foo") { req -> String in
 return "bar"
}
```

Oto obsługiwane metody pomocnicze tras:

- `get`
- `post`
- `patch`
- `put`
- `delete`

Oprócz helperów metod HTTP, istnieje funkcja `on`, która akceptuje metodę HTTP jako parametr wejściowy.

```swift
// odpowiada na OPCJE /foo/bar/baz
app.on(.OPTIONS, "foo", "bar", "baz") { req in
 ...
}
```

### Komponenty ścieżki (path)

Każda metoda rejestracji trasy akceptuje zmienną listę `PathComponent`. Ten typ jest wyrażalny przez literał łańcuchowy i ma cztery przypadki:

- Stała (`foo`)
- Parametr (`:foo`)
- Anything (`*`)
- Catchall (`**`)

#### Stała

Jest to statyczny element trasy. Dozwolone będą tylko żądania z dokładnie pasującym ciągiem znaków w tej pozycji.

```swift
// responds to GET /foo/bar/baz
app.get("foo", "bar", "baz") { req in
 ...
}
```

#### Parametr

Jest to dynamiczny element trasy. Dowolny ciąg znaków na tej pozycji będzie dozwolony. Ścieżka parametru jest określana z prefiksem `:`. Ciąg znaków następujący po `:` będzie używany jako nazwa parametru. Możesz użyć tej nazwy do późniejszego pobrania wartości parametru z żądania.

```swift
// odpowiada na GET /foo/bar/baz
// odpowiada na GET /foo/qux/baz
// ...
app.get("foo", ":bar", "baz") { req in
 ...
}
```

#### Cokolwiek

Jest to bardzo podobne do parametru, z wyjątkiem tego, że wartość jest odrzucana. Ten komponent ścieżki jest określony jako `*`.

```swift
// odpowiada na GET /foo/bar/baz
// odpowiada na GET /foo/qux/baz
// ...
app.get("foo", "*", "baz") { req in
 ...
}
```

#### Złap je wszystkie (catchall)

Jest to dynamiczny komponent trasy, który pasuje do jednego lub więcej komponentów. Jest on określany przy użyciu samego `**`. Dowolny ciąg znaków w tej pozycji lub późniejszych pozycjach zostanie dopasowany w żądaniu.

```swift
// odpowiada na GET /foo/bar
// odpowiada na GET /foo/bar/baz
// ...
app.get("foo", "**") { req in
    ...
}
```

### Parametry

Gdy używany jest komponent ścieżki parametru (poprzedzony `:`), wartość URI na tej pozycji będzie przechowywana w `req.parameters`. Możesz użyć nazwy komponentu ścieżki, aby uzyskać dostęp do wartości.

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
    Możemy być pewni, że `req.parameters.get` nigdy nie zwróci `nil`, ponieważ nasza ścieżka trasy zawiera `:name`. Jeśli jednak uzyskujesz dostęp do parametrów trasy w oprogramowaniu pośredniczącym lub w kodzie uruchamianym przez wiele tras, będziesz chciał obsłużyć możliwość `nil`.

!!! tip
    Jeśli chcesz pobrać parametry zapytania adresu URL, np. `/hello/?name=foo`, musisz użyć interfejsów API treści Vapor do obsługi danych zakodowanych w ciągu zapytania adresu URL. Więcej szczegółów można znaleźć w [`Content` reference](content.md).

`req.parameters.get` obsługuje również automatyczne rzutowanie parametru na typy `LosslessStringConvertible`.

```swift
// odpowiada na GET /numer/42
// odpowiada na GET /number/1337
// ...
app.get("number", ":x") { req -> String in 
 guard let int = req.parameters.get("x", as: Int.self) else {
  throw Abort(.badRequest)
 }
 return "\(int) is a great number"
}
```

The values of the URI matched by Catchall (`**`) will be stored in `req.parameters` as `[String]`. You can use `req.parameters.getCatchall` to access those components.

```swift
// odpowiada na GET /hello/foo
// odpowiada na GET /hello/foo/bar
// ...
app.get("hello", "**") { req -> String in
    let name = req.parameters.getCatchall().joined(separator: " ")
    return "Hello, \(name)!"
}
```

### Body Streaming

Podczas rejestrowania trasy przy użyciu metody `on` można określić sposób obsługi treści żądania. Domyślnie ciała żądań są gromadzone w pamięci przed wywołaniem obsługi. Jest to przydatne, ponieważ pozwala na synchroniczne dekodowanie treści żądań, nawet jeśli aplikacja odczytuje przychodzące żądania asynchronicznie.

Domyślnie Vapor ograniczy zbieranie treści do 16 KB. Można to skonfigurować za pomocą `app.routes`.

```swift
// Zwiększa limit strumieniowego zbierania treści do 500kb
app.routes.defaultMaxBodySize = "500kb"
```

Jeśli zbierane ciało strumieniowe przekroczy skonfigurowany limit, zostanie zgłoszony błąd `413 Payload Too Large`.

Aby skonfigurować strategię zbierania treści żądań dla indywidualnej trasy, należy użyć parametru `body`.

```swift
// Zbiera strumieniowe treści (o rozmiarze do 1mb) przed wywołaniem tej trasy.
app.on(.POST, "listings", body: .collect(maxSize: "1mb")) { req in
    // Obsługa żądania. 
}
```

Jeśli `maxSize` zostanie przekazany do `collect`, zastąpi on domyślną wartość aplikacji dla tej trasy. Aby użyć domyślnej wartości aplikacji, należy pominąć argument `maxSize`.

W przypadku dużych żądań, takich jak przesyłanie plików, gromadzenie treści żądania w buforze może potencjalnie obciążyć pamięć systemową. Aby zapobiec gromadzeniu treści żądania, należy użyć strategii `stream`.

```swift
// Treść żądania nie będzie gromadzona w buforze.
app.on(.POST, "upload", body: .stream) { req in
    ...
}
```

Gdy treść żądania jest przesyłana strumieniowo, `req.body.data` będzie `nil`. Musisz użyć `req.body.drain`, aby obsłużyć każdy fragment wysyłany do trasy.

### Routing niewrażliwy na wielkość liter

Domyślnym zachowaniem routingu jest rozróżnianie i zachowywanie wielkości liter. Komponenty ścieżki `Constant` mogą być alternatywnie obsługiwane w sposób niewrażliwy na wielkość liter i zachowujący wielkość liter dla celów routingu; aby włączyć to zachowanie, należy skonfigurować je przed uruchomieniem aplikacji:

``swift
app.routes.caseInsensitive = true
```

Żadne zmiany nie są wprowadzane do żądania źródłowego; programy obsługi tras otrzymają komponenty ścieżki żądania bez modyfikacji.

### Podglądanie tras

Dostęp do tras aplikacji można uzyskać, tworząc usługę `Routes` lub używając `app.routes`.

```swift
print(app.routes.all) // [Trasa]
```

Vapor jest również dostarczany z komendą `routes`, która drukuje wszystkie dostępne trasy w tabeli w formacie ASCII.

```sh
$ swift run App routes
+--------+----------------+
| GET | / |
+--------+----------------+
| GET | /hello |
+--------+----------------+
| GET | /todos |
+--------+----------------+
| POST | /todos |
+--------+----------------+
| DELETE | /todos/:todoID |
+--------+----------------+
```

### Metadane

Wszystkie metody rejestracji trasy zwracają utworzoną `Route`. Pozwala to na dodanie metadanych do słownika `userInfo` trasy. Dostępne są pewne domyślne metody, takie jak dodawanie opisu.

``swift
app.get("hello", ":name") { req in
 ...
}.description("says hello")
```

## Grupy tras

Grupowanie tras umożliwia tworzenie zestawu tras z prefiksem ścieżki lub określonym oprogramowaniem pośredniczącym. Grupowanie obsługuje składnię opartą na konstruktorze i zamknięciu.

Wszystkie metody grupowania zwracają `RouteBuilder`, co oznacza, że można w nieskończoność mieszać, dopasowywać i zagnieżdżać swoje grupy z innymi metodami tworzenia tras.

### Prefiks ścieżki

Grupy tras z prefiksem ścieżki pozwalają na dodanie jednego lub więcej komponentów ścieżki do grupy tras.

``swift
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

Każdy komponent ścieżki, który można przekazać do metod takich jak `get` lub `post` może zostać przekazany do `grouped`. Istnieje również alternatywna składnia oparta na zamknięciach.

``swift
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

Zagnieżdżanie grup tras z prefiksami ścieżek pozwala na zwięzłe definiowanie interfejsów API CRUD.

``swift
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

### Oprogramowanie pośredniczące

Oprócz prefiksowania komponentów ścieżek, można również dodawać oprogramowanie pośredniczące do grup tras.

``swift
app.get("fast-thing") { req in
    ...
}
app.group(RateLimitMiddleware(requestsPerMinute: 5)) { rateLimited in
    rateLimited.get("slow-thing") { req in
        ...
    }
}
```

Jest to szczególnie przydatne do ochrony podzbiorów tras z różnym oprogramowaniem pośredniczącym uwierzytelniania.

``swift
app.post("login") { ... }
let auth = app.grouped(AuthMiddleware())
auth.get("dashboard") { ... }
auth.get("logout") { ... }
```

## Przekierowania

Przekierowania są przydatne w wielu scenariuszach, takich jak przekierowanie starych lokalizacji do nowych dla SEO, przekierowanie nieuwierzytelnionego użytkownika na stronę logowania lub zachowanie wstecznej kompatybilności z nową wersją interfejsu API.

Aby przekierować żądanie, użyj:

``swift
req.redirect(to: "/some/new/path")
```

Możesz także określić typ przekierowania, na przykład, aby przekierować stronę na stałe (tak, aby Twoje SEO zostało poprawnie zaktualizowane) użyj:

``swift
req.redirect(to: "/some/new/path", type: .permanent)
```

Różne `RedirectType` to:

- `.permanent` - zwraca przekierowanie **301 Permanent**
- `.normal` - zwraca **303 zobacz inne** przekierowanie. Jest to domyślne ustawienie Vapor i mówi klientowi, aby podążał za przekierowaniem z żądaniem **GET**.
- `.temporary` - zwraca **307 tymczasowe** przekierowanie. Mówi to klientowi, aby zachował metodę HTTP użytą w żądaniu.

> Aby wybrać odpowiedni kod statusu przekierowania, sprawdź [pełną listę] (https://en.wikipedia.org/wiki/List_of_HTTP_status_codes#3xx_redirection).