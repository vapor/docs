# Uwierzytelnianie

Uwierzytelnianie to proces weryfikacji tożsamości użytkownika. Odbywa się to poprzez weryfikację poświadczeń, takich jak nazwa użytkownika i hasło lub unikalny token. Uwierzytelnianie (czasami nazywane auth/c) różni się od autoryzacji (auth/z), która polega na weryfikacji uprawnień wcześniej uwierzytelnionego użytkownika do wykonywania określonych zadań.

## Wprowadzenie

API Authentication Vapora zapewnia wsparcie dla uwierzytelniania użytkownika za pomocą nagłówka `Authorization`, wykorzystując [Basic](https://tools.ietf.org/html/rfc7617) oraz [Bearer](https://tools.ietf.org/html/rfc6750). Wspiera również uwierzytelnianie użytkownika na podstawie danych zdekodowanych z API [Content](../basics/content.md).

Uwierzytelnianie jest zaimplementowane poprzez utworzenie `Authenticator`, który zawiera logikę weryfikacji. Authenticator może być użyty do ochrony poszczególnych grup tras lub całej aplikacji. Wraz z Vaporem dostarczane są następujące pomocnicze authenticatory:

|Protokół|Opis|
|-|-|
|`RequestAuthenticator`/`AsyncRequestAuthenticator`|Bazowy authenticator zdolny do tworzenia middleware.|
|[`BasicAuthenticator`/`AsyncBasicAuthenticator`](#basic)|Uwierzytelnia nagłówek autoryzacji Basic.|
|[`BearerAuthenticator`/`AsyncBearerAuthenticator`](#bearer)|Uwierzytelnia nagłówek autoryzacji Bearer.|
|`CredentialsAuthenticator`/`AsyncCredentialsAuthenticator`|Uwierzytelnia treść zawierającą poświadczenia z ciała żądania.|

Jeśli uwierzytelnianie zakończy się powodzeniem, authenticator dodaje zweryfikowanego użytkownika do `req.auth`. Ten użytkownik może być następnie pobrany za pomocą `req.auth.get(_:)` w trasach chronionych przez authenticator. Jeśli uwierzytelnianie się nie powiedzie, użytkownik nie zostanie dodany do `req.auth`, a wszelkie próby uzyskania do niego dostępu zakończą się niepowodzeniem.

## Authenticatable

Aby skorzystać z API Authentication, potrzebujesz najpierw typu użytkownika zgodnego z `Authenticatable`. Może to być `struct`, `class`, a nawet `Model` z Fluent. Poniższe przykłady zakładają prostą strukturę `User` z jedną właściwością: `name`.

```swift
import Vapor

struct User: Authenticatable {
    var name: String
}
```

Każdy z poniższych przykładów będzie korzystał z instancji utworzonego przez nas authenticatora. W tych przykładach nazwaliśmy go `UserAuthenticator`.

### Trasa

Authenticatory są middleware i mogą być używane do ochrony tras.

```swift
let protected = app.grouped(UserAuthenticator())
protected.get("me") { req -> String in
    try req.auth.require(User.self).name
}
```

`req.auth.require` jest używane do pobrania uwierzytelnionego `User`. Jeśli uwierzytelnianie się nie powiodło, ta metoda rzuci błąd, chroniąc trasę.

### Guard Middleware

Możesz również użyć `GuardMiddleware` w grupie tras, aby upewnić się, że użytkownik został uwierzytelniony, zanim dotrze do handlera trasy.

```swift
let protected = app.grouped(UserAuthenticator())
    .grouped(User.guardMiddleware())
```

Wymaganie uwierzytelnienia nie jest realizowane przez middleware authenticatora, aby umożliwić kompozycję authenticatorów. Przeczytaj więcej o [kompozycji](#composition) poniżej.

## Basic

Uwierzytelnianie Basic wysyła nazwę użytkownika i hasło w nagłówku `Authorization`. Nazwa użytkownika i hasło są łączone dwukropkiem (np. `test:secret`), kodowane w base-64 i poprzedzane prefiksem `"Basic "`. Poniższy przykładowy request koduje nazwę użytkownika `test` z hasłem `secret`.

```http
GET /me HTTP/1.1
Authorization: Basic dGVzdDpzZWNyZXQ=
``` 

Uwierzytelnianie Basic jest zwykle używane jednorazowo do zalogowania użytkownika i wygenerowania tokenu. Minimalizuje to częstotliwość, z jaką musi być wysyłane wrażliwe hasło użytkownika. Nigdy nie powinieneś wysyłać autoryzacji Basic przez połączenie w postaci zwykłego tekstu (plaintext) lub niezweryfikowane połączenie TLS.

Aby zaimplementować uwierzytelnianie Basic w swojej aplikacji, utwórz nowy authenticator zgodny z `BasicAuthenticator`. Poniżej znajduje się przykładowy authenticator z zaszytymi na stałe wartościami weryfikującymi żądanie z powyższego przykładu.


```swift
import Vapor

struct UserAuthenticator: BasicAuthenticator {
    typealias User = App.User

    func authenticate(
        basic: BasicAuthorization,
        for request: Request
    ) -> EventLoopFuture<Void> {
        if basic.username == "test" && basic.password == "secret" {
            request.auth.login(User(name: "Vapor"))
        }
        return request.eventLoop.makeSucceededFuture(())
   }
}
```

Jeśli korzystasz z `async`/`await`, możesz zamiast tego użyć `AsyncBasicAuthenticator`:

```swift
import Vapor

struct UserAuthenticator: AsyncBasicAuthenticator {
    typealias User = App.User

    func authenticate(
        basic: BasicAuthorization,
        for request: Request
    ) async throws {
        if basic.username == "test" && basic.password == "secret" {
            request.auth.login(User(name: "Vapor"))
        }
   }
}
```

Ten protokół wymaga zaimplementowania `authenticate(basic:for:)`, które zostanie wywołane, gdy przychodzące żądanie zawiera nagłówek `Authorization: Basic ...`. Do metody przekazywana jest struktura `BasicAuthorization` zawierająca nazwę użytkownika i hasło.

W tym testowym authenticatorze nazwa użytkownika i hasło są porównywane z zaszytymi na stałe wartościami. W prawdziwym authenticatorze mógłbyś sprawdzać dane względem bazy danych lub zewnętrznego API. Dlatego właśnie metoda `authenticate` pozwala na zwrócenie future.

!!! tip
    Hasła nigdy nie powinny być przechowywane w bazie danych jako zwykły tekst (plaintext). Zawsze używaj hashy haseł do porównania.

Jeśli parametry uwierzytelniania są poprawne, w tym przypadku pasują do zaszytych na stałe wartości, `User` o nazwie Vapor zostaje zalogowany. Jeśli parametry uwierzytelniania nie pasują, żaden użytkownik nie zostaje zalogowany, co oznacza niepowodzenie uwierzytelnienia.

Jeśli dodasz ten authenticator do swojej aplikacji i przetestujesz trasę zdefiniowaną powyżej, powinieneś zobaczyć zwróconą nazwę `"Vapor"` przy udanym logowaniu. Jeśli poświadczenia są nieprawidłowe, powinieneś zobaczyć błąd `401 Unauthorized`.

## Bearer

Uwierzytelnianie Bearer wysyła token w nagłówku `Authorization`. Token jest poprzedzany prefiksem `"Bearer "`. Poniższy przykładowy request wysyła token `foo`.

```http
GET /me HTTP/1.1
Authorization: Bearer foo
``` 

Uwierzytelnianie Bearer jest powszechnie używane do uwierzytelniania endpointów API. Użytkownik zazwyczaj żąda tokenu Bearer, wysyłając poświadczenia, takie jak nazwa użytkownika i hasło, do endpointu logowania. Ten token może być ważny przez minuty lub dni, w zależności od potrzeb aplikacji.

Dopóki token jest ważny, użytkownik może go używać zamiast swoich poświadczeń, aby uwierzytelnić się względem API. Jeśli token straci ważność, nowy może zostać wygenerowany za pomocą endpointu logowania.

Aby zaimplementować uwierzytelnianie Bearer w swojej aplikacji, utwórz nowy authenticator zgodny z `BearerAuthenticator`. Poniżej znajduje się przykładowy authenticator z zaszytymi na stałe wartościami weryfikującymi żądanie z powyższego przykładu.

```swift
import Vapor

struct UserAuthenticator: BearerAuthenticator {
    typealias User = App.User

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) -> EventLoopFuture<Void> {
       if bearer.token == "foo" {
           request.auth.login(User(name: "Vapor"))
       }
       return request.eventLoop.makeSucceededFuture(())
   }
}
```

Jeśli korzystasz z `async`/`await`, możesz zamiast tego użyć `AsyncBearerAuthenticator`:

```swift
import Vapor

struct UserAuthenticator: AsyncBearerAuthenticator {
    typealias User = App.User

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) async throws {
       if bearer.token == "foo" {
           request.auth.login(User(name: "Vapor"))
       }
   }
}
```

Ten protokół wymaga zaimplementowania `authenticate(bearer:for:)`, które zostanie wywołane, gdy przychodzące żądanie zawiera nagłówek `Authorization: Bearer ...`. Do metody przekazywana jest struktura `BearerAuthorization` zawierająca token.

W tym testowym authenticatorze token jest porównywany z zaszytą na stałe wartością. W prawdziwym authenticatorze mógłbyś weryfikować token, sprawdzając go względem bazy danych lub używając środków kryptograficznych, tak jak to się robi w przypadku JWT. Dlatego właśnie metoda `authenticate` pozwala na zwrócenie future.

!!! tip
    Podczas implementowania weryfikacji tokenów ważne jest, aby uwzględnić skalowalność horyzontalną. Jeśli twoja aplikacja musi obsługiwać wielu użytkowników jednocześnie, uwierzytelnianie może stanowić potencjalne wąskie gardło. Zastanów się, jak twój projekt będzie się skalował w wielu instancjach twojej aplikacji działających jednocześnie.

Jeśli parametry uwierzytelniania są poprawne, w tym przypadku pasują do zaszytej na stałe wartości, `User` o nazwie Vapor zostaje zalogowany. Jeśli parametry uwierzytelniania nie pasują, żaden użytkownik nie zostaje zalogowany, co oznacza niepowodzenie uwierzytelnienia.

Jeśli dodasz ten authenticator do swojej aplikacji i przetestujesz trasę zdefiniowaną powyżej, powinieneś zobaczyć zwróconą nazwę `"Vapor"` przy udanym logowaniu. Jeśli poświadczenia są nieprawidłowe, powinieneś zobaczyć błąd `401 Unauthorized`.

## Composition

Wiele authenticatorów może zostać skomponowanych (połączonych razem), aby stworzyć bardziej złożone uwierzytelnianie endpointu. Ponieważ middleware authenticatora nie odrzuca żądania, jeśli uwierzytelnianie się nie powiedzie, więcej niż jeden z tych middleware może zostać połączonych w łańcuch. Authenticatory mogą być komponowane na dwa kluczowe sposoby.

### Komponowanie metod


Pierwszą metodą kompozycji uwierzytelniania jest łączenie w łańcuch więcej niż jednego authenticatora dla tego samego typu użytkownika. Weźmy poniższy przykład:

```swift
app.grouped(UserPasswordAuthenticator())
    .grouped(UserTokenAuthenticator())
    .grouped(User.guardMiddleware())
    .post("login") 
{ req in
    let user = try req.auth.require(User.self)
    // Do something with user.
}
```

Ten przykład zakłada dwa authenticatory, `UserPasswordAuthenticator` i `UserTokenAuthenticator`, które oba uwierzytelniają `User`. Oba te authenticatory są dodane do grupy tras. Na końcu dodawany jest `GuardMiddleware`, aby wymagać, żeby `User` został pomyślnie uwierzytelniony.

Taka kompozycja authenticatorów skutkuje trasą, do której można uzyskać dostęp albo za pomocą hasła, albo tokenu. Taka trasa mogłaby pozwolić użytkownikowi zalogować się i wygenerować token, a następnie kontynuować używanie tego tokenu do generowania nowych tokenów.

### Komponowanie użytkowników

Drugą metodą kompozycji uwierzytelniania jest łączenie w łańcuch authenticatorów dla różnych typów użytkowników. Weźmy poniższy przykład:

```swift
app.grouped(AdminAuthenticator())
    .grouped(UserAuthenticator())
    .get("secure") 
{ req in
    guard req.auth.has(Admin.self) || req.auth.has(User.self) else {
        throw Abort(.unauthorized)
    }
    // Do something.
}
```

Ten przykład zakłada dwa authenticatory, `AdminAuthenticator` i `UserAuthenticator`, które uwierzytelniają odpowiednio `Admin` i `User`. Oba te authenticatory są dodane do grupy tras. Zamiast użycia `GuardMiddleware`, w handlerze trasy dodawane jest sprawdzenie, czy `Admin` lub `User` zostały uwierzytelnione. Jeśli nie, rzucany jest błąd.

Taka kompozycja authenticatorów skutkuje trasą, do której dostęp mogą uzyskać dwa różne typy użytkowników, potencjalnie z różnymi metodami uwierzytelniania. Taka trasa mogłaby pozwolić na standardowe uwierzytelnianie użytkownika, jednocześnie dając dostęp super-użytkownikowi.

## Ręczne uwierzytelnianie

Możesz również obsłużyć uwierzytelnianie ręcznie, korzystając z `req.auth`. Jest to szczególnie przydatne przy testowaniu.

Aby ręcznie zalogować użytkownika, użyj `req.auth.login(_:)`. Do tej metody można przekazać dowolnego użytkownika zgodnego z `Authenticatable`.

```swift
req.auth.login(User(name: "Vapor"))
```

Aby uzyskać uwierzytelnionego użytkownika, użyj `req.auth.require(_:)`

```swift
let user: User = try req.auth.require(User.self)
print(user.name) // String
```

Możesz również użyć `req.auth.get(_:)`, jeśli nie chcesz, aby błąd był automatycznie rzucany w przypadku niepowodzenia uwierzytelnienia.

```swift
let user = req.auth.get(User.self)
print(user?.name) // String?
```

Aby wylogować użytkownika, przekaż typ użytkownika do `req.auth.logout(_:)`. 

```swift
req.auth.logout(User.self)
```

## Fluent

[Fluent](../fluent/overview.md) definiuje dwa protokoły, `ModelAuthenticatable` i `ModelTokenAuthenticatable`, które można dodać do istniejących modeli. Dostosowanie modeli do tych protokołów umożliwia tworzenie authenticatorów chroniących endpointy.

`ModelTokenAuthenticatable` uwierzytelnia za pomocą tokenu Bearer. Tego używa się do ochrony większości endpointów. `ModelAuthenticatable` uwierzytelnia za pomocą nazwy użytkownika i hasła i jest używane przez pojedynczy endpoint do generowania tokenów.

Ten przewodnik zakłada, że znasz Fluent i masz pomyślnie skonfigurowaną aplikację do korzystania z bazy danych. Jeśli dopiero zaczynasz z Fluent, zacznij od [przeglądu](../fluent/overview.md).

### Użytkownik

Na początek potrzebny będzie model reprezentujący użytkownika, który będzie uwierzytelniany. W tym przewodniku będziemy korzystać z poniższego modelu, ale możesz swobodnie użyć już istniejącego modelu.

```swift
import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    init() { }

    init(id: UUID? = nil, name: String, email: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
    }
}
```

Model musi być w stanie przechowywać nazwę użytkownika, w tym przypadku e-mail, oraz hash hasła. Ustawiamy również `email` jako unikalne pole, aby uniknąć duplikatów użytkowników. Odpowiednia migracja dla tego przykładowego modelu wygląda tak:

```swift
import Fluent
import Vapor

extension User {
    struct Migration: AsyncMigration {
        var name: String { "CreateUser" }

        func prepare(on database: Database) async throws {
            try await database.schema("users")
                .id()
                .field("name", .string, .required)
                .field("email", .string, .required)
                .field("password_hash", .string, .required)
                .unique(on: "email")
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema("users").delete()
        }
    }
}
```

Nie zapomnij dodać migracji do `app.migrations`.

```swift
app.migrations.add(User.Migration())
``` 

!!! tip
     Ponieważ adresy e-mail nie rozróżniają wielkości liter, możesz chcieć dodać [`Middleware`](../fluent/model.md#lifecycle), który zamienia adres e-mail na małe litery przed zapisaniem go w bazie danych. Miej jednak na uwadze, że `ModelAuthenticatable` używa porównania rozróżniającego wielkość liter, więc jeśli to zrobisz, upewnij się, że dane wejściowe użytkownika są zawsze pisane małymi literami, albo poprzez wymuszenie tego po stronie klienta, albo za pomocą niestandardowego authenticatora.

Pierwszą rzeczą, jakiej będziesz potrzebować, jest endpoint do tworzenia nowych użytkowników. Skorzystajmy z `POST /users`. Utwórz strukturę [Content](../basics/content.md) reprezentującą dane, jakich oczekuje ten endpoint.

```swift
import Vapor

extension User {
    struct Create: Content {
        var name: String
        var email: String
        var password: String
        var confirmPassword: String
    }
}
```

Jeśli chcesz, możesz dostosować tę strukturę do [Validatable](../basics/validation.md), aby dodać wymagania walidacji.

```swift
import Vapor

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}
```

Teraz możesz utworzyć endpoint `POST /users`. 

```swift
app.post("users") { req async throws -> User in
    try User.Create.validate(content: req)
    let create = try req.content.decode(User.Create.self)
    guard create.password == create.confirmPassword else {
        throw Abort(.badRequest, reason: "Passwords did not match")
    }
    let user = try User(
        name: create.name,
        email: create.email,
        passwordHash: Bcrypt.hash(create.password)
    )
    try await user.save(on: req.db)
    return user
}
```

Ten endpoint waliduje przychodzące żądanie, dekoduje strukturę `User.Create` i sprawdza, czy hasła się zgadzają. Następnie wykorzystuje zdekodowane dane do utworzenia nowego `User` i zapisuje go w bazie danych. Hasło w postaci zwykłego tekstu jest hashowane za pomocą `Bcrypt` przed zapisaniem w bazie danych.

Zbuduj i uruchom projekt, upewniając się, że najpierw zmigrowałeś bazę danych, a następnie użyj poniższego żądania, aby utworzyć nowego użytkownika. 

```http
POST /users HTTP/1.1
Content-Length: 97
Content-Type: application/json

{
    "name": "Vapor",
    "email": "test@vapor.codes",
    "password": "secret42",
    "confirmPassword": "secret42"
}
```

#### Model Authenticatable

Teraz, gdy masz model użytkownika i endpoint do tworzenia nowych użytkowników, dostosujmy model do `ModelAuthenticatable`. Pozwoli to na uwierzytelnianie modelu za pomocą nazwy użytkownika i hasła.

```swift
import Fluent
import Vapor

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}
```

To rozszerzenie dodaje zgodność z `ModelAuthenticatable` do `User`. Pierwsze dwie właściwości określają, które pola mają być używane odpowiednio do przechowywania nazwy użytkownika i hasha hasła. Notacja `\` tworzy key path do pól, z których może korzystać Fluent.

Ostatnim wymaganiem jest metoda do weryfikacji haseł w postaci zwykłego tekstu, wysyłanych w nagłówku uwierzytelniania Basic. Ponieważ podczas rejestracji używamy Bcrypt do hashowania hasła, użyjemy Bcrypt do zweryfikowania, czy podane hasło pasuje do przechowywanego hasha hasła.

Teraz, gdy `User` jest zgodny z `ModelAuthenticatable`, możemy utworzyć authenticator chroniący trasę logowania.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req -> User in
    try req.auth.require(User.self)
}
```

`ModelAuthenticatable` dodaje statyczną metodę `authenticator` do tworzenia authenticatora.

Sprawdź, czy ta trasa działa, wysyłając poniższe żądanie.

```http
POST /login HTTP/1.1
Authorization: Basic dGVzdEB2YXBvci5jb2RlczpzZWNyZXQ0Mg==
```

To żądanie przekazuje nazwę użytkownika `test@vapor.codes` i hasło `secret42` za pomocą nagłówka uwierzytelniania Basic. Powinieneś zobaczyć zwróconego wcześniej utworzonego użytkownika.

Choć teoretycznie mógłbyś użyć uwierzytelniania Basic do ochrony wszystkich swoich endpointów, zaleca się zamiast tego użycie osobnego tokenu. Minimalizuje to częstotliwość, z jaką musisz wysyłać wrażliwe hasło użytkownika przez internet. Sprawia to również, że uwierzytelnianie jest znacznie szybsze, ponieważ hashowanie hasła musisz wykonać tylko podczas logowania.

### Token użytkownika

Utwórz nowy model reprezentujący tokeny użytkownika.

```swift
import Fluent
import Vapor

final class UserToken: Model, Content {
    static let schema = "user_tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "value")
    var value: String

    @Parent(key: "user_id")
    var user: User

    init() { }

    init(id: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
}
```

Ten model musi mieć pole `value` do przechowywania unikalnego stringa tokenu. Musi też mieć [relację nadrzędną (parent-relation)](../fluent/overview.md#parent) do modelu użytkownika. Możesz dodać dodatkowe właściwości do tego tokenu według uznania, np. datę wygaśnięcia.

Następnie utwórz migrację dla tego modelu.

```swift
import Fluent

extension UserToken {
    struct Migration: AsyncMigration {
        var name: String { "CreateUserToken" }
        
        func prepare(on database: Database) async throws {
            try await database.schema("user_tokens")
                .id()
                .field("value", .string, .required)
                .field("user_id", .uuid, .required, .references("users", "id"))
                .unique(on: "value")
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema("user_tokens").delete()
        }
    }
}
```

Zwróć uwagę, że ta migracja sprawia, że pole `value` jest unikalne. Tworzy również odniesienie klucza obcego pomiędzy polem `user_id` a tabelą użytkowników.

Nie zapomnij dodać migracji do `app.migrations`.

```swift
app.migrations.add(UserToken.Migration())
``` 

Na koniec dodaj do `User` metodę generującą nowy token. Ta metoda będzie używana podczas logowania.

```swift
extension User {
    func generateToken() throws -> UserToken {
        try .init(
            value: [UInt8].random(count: 16).base64, 
            userID: self.requireID()
        )
    }
}
```

Tutaj korzystamy z `[UInt8].random(count:)`, aby wygenerować losową wartość tokenu. W tym przykładzie wykorzystywane jest 16 bajtów, czyli 128 bitów, losowych danych. Możesz dostosować tę liczbę według uznania. Losowe dane są następnie kodowane w base-64, aby ułatwić ich przesyłanie w nagłówkach HTTP.

Teraz, gdy możesz generować tokeny użytkownika, zaktualizuj trasę `POST /login`, aby tworzyła i zwracała token.

```swift
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req async throws -> UserToken in
    let user = try req.auth.require(User.self)
    let token = try user.generateToken()
    try await token.save(on: req.db)
    return token
}
```

Sprawdź, czy ta trasa działa, korzystając z tego samego żądania logowania co powyżej. Powinieneś teraz otrzymać po zalogowaniu token wyglądający mniej więcej tak:

```
8gtg300Jwdhc/Ffw784EXA==
```

Zachowaj otrzymany token, ponieważ wkrótce go użyjemy.

#### Model Token Authenticatable

Dostosuj `UserToken` do `ModelTokenAuthenticatable`. Umożliwi to tokenom uwierzytelnianie twojego modelu `User`.

```swift
import Vapor
import Fluent

extension UserToken: ModelTokenAuthenticatable {
    static var valueKey: KeyPath<UserToken, Field<String>> { \.$value }
    static var userKey: KeyPath<UserToken, Parent<User>> { \.$user }

    var isValid: Bool {
        true
    }
}
```

Pierwsze wymaganie protokołu określa, które pole przechowuje unikalną wartość tokenu. To ta wartość będzie wysyłana w nagłówku uwierzytelniania Bearer. Drugie wymaganie określa relację nadrzędną do modelu `User`. W ten sposób Fluent wyszuka uwierzytelnionego użytkownika.

Ostatnim wymaganiem jest wartość logiczna `isValid`. Jeśli jest `false`, token zostanie usunięty z bazy danych, a użytkownik nie zostanie uwierzytelniony. Dla uproszczenia sprawimy, że tokeny będą wieczne, zaszywając na stałe wartość `true`.

Teraz, gdy token jest zgodny z `ModelTokenAuthenticatable`, możesz utworzyć authenticator chroniący trasy.

Utwórz nowy endpoint `GET /me` do pobierania aktualnie uwierzytelnionego użytkownika.

```swift
let tokenProtected = app.grouped(UserToken.authenticator())
tokenProtected.get("me") { req -> User in
    try req.auth.require(User.self)
}
```

Podobnie jak `User`, `UserToken` ma teraz statyczną metodę `authenticator()`, która może generować authenticator. Authenticator spróbuje znaleźć pasujący `UserToken`, korzystając z wartości podanej w nagłówku uwierzytelniania Bearer. Jeśli znajdzie dopasowanie, pobierze powiązanego `User` i go uwierzytelni.

Sprawdź, czy ta trasa działa, wysyłając poniższe żądanie HTTP, gdzie token to wartość, którą zapisałeś z żądania `POST /login`. 

```http
GET /me HTTP/1.1
Authorization: Bearer <token>
```

Powinieneś zobaczyć zwróconego uwierzytelnionego `User`. 

## Sesja

[API Session](../advanced/sessions.md) Vapora może być używane do automatycznego utrzymywania uwierzytelnienia użytkownika pomiędzy żądaniami. Działa to poprzez przechowywanie unikalnego identyfikatora użytkownika w danych sesji żądania po pomyślnym zalogowaniu. Przy kolejnych żądaniach identyfikator użytkownika jest pobierany z sesji i używany do uwierzytelnienia użytkownika przed wywołaniem handlera twojej trasy.

Sesje świetnie sprawdzają się w aplikacjach front-endowych zbudowanych w Vaporze, które serwują HTML bezpośrednio do przeglądarek internetowych. W przypadku API zalecamy korzystanie z bezstanowego uwierzytelniania opartego na tokenach, aby przechowywać dane użytkownika pomiędzy żądaniami.

### Session Authenticatable

Aby skorzystać z uwierzytelniania opartego na sesji, potrzebny będzie typ zgodny z `SessionAuthenticatable`. W tym przykładzie użyjemy prostej struktury.

```swift
import Vapor

struct User {
    var email: String
}
```

Aby dostosować się do `SessionAuthenticatable`, musisz określić `sessionID`. Jest to wartość, która będzie przechowywana w danych sesji i musi jednoznacznie identyfikować użytkownika. 

```swift
extension User: SessionAuthenticatable {
    var sessionID: String {
        self.email
    }
}
```

Dla naszego prostego typu `User` użyjemy adresu e-mail jako unikalnego identyfikatora sesji.

### Session Authenticator

Następnie potrzebujemy `SessionAuthenticator` do obsługi rozwiązywania instancji naszego User na podstawie zachowanego identyfikatora sesji.


```swift
struct UserSessionAuthenticator: SessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: String, for request: Request) -> EventLoopFuture<Void> {
        let user = User(email: sessionID)
        request.auth.login(user)
        return request.eventLoop.makeSucceededFuture(())
    }
}
```

Jeśli korzystasz z `async`/`await`, możesz użyć `AsyncSessionAuthenticator`:

```swift
struct UserSessionAuthenticator: AsyncSessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: String, for request: Request) async throws {
        let user = User(email: sessionID)
        request.auth.login(user)
    }
}
```

Ponieważ wszystkie informacje potrzebne do zainicjowania naszego przykładowego `User` są zawarte w identyfikatorze sesji, możemy stworzyć i zalogować użytkownika synchronicznie. W rzeczywistej aplikacji prawdopodobnie użyłbyś identyfikatora sesji do wykonania zapytania do bazy danych lub żądania API, aby pobrać resztę danych użytkownika przed uwierzytelnieniem. 

Następnie stwórzmy prosty authenticator bearer do wykonania początkowego uwierzytelnienia.

```swift
struct UserBearerAuthenticator: AsyncBearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        if bearer.token == "test" {
            let user = User(email: "hello@vapor.codes")
            request.auth.login(user)
        }
    }
}
```

Ten authenticator uwierzytelni użytkownika o adresie e-mail `hello@vapor.codes`, gdy zostanie wysłany token bearer `test`.

Na koniec połączmy wszystkie te elementy razem w twojej aplikacji.

```swift
// Create protected route group which requires user auth.
let protected = app.routes.grouped([
    app.sessions.middleware,
    UserSessionAuthenticator(),
    UserBearerAuthenticator(),
    User.guardMiddleware(),
])

// Add GET /me route for reading user's email.
protected.get("me") { req -> String in
    try req.auth.require(User.self).email
}
```

`SessionsMiddleware` jest dodawane jako pierwsze, aby włączyć wsparcie sesji w aplikacji. Więcej informacji na temat konfigurowania sesji znajdziesz w sekcji [API Session](../advanced/sessions.md).

Następnie dodawany jest `SessionAuthenticator`. Obsługuje on uwierzytelnianie użytkownika, jeśli sesja jest aktywna. 

Jeśli uwierzytelnienie nie zostało jeszcze zachowane w sesji, żądanie zostanie przekazane do następnego authenticatora. `UserBearerAuthenticator` sprawdzi token bearer i uwierzytelni użytkownika, jeśli jest on równy `"test"`.

Na koniec `User.guardMiddleware()` upewni się, że `User` został uwierzytelniony przez jeden z poprzednich middleware. Jeśli użytkownik nie został uwierzytelniony, zostanie rzucony błąd. 

Aby przetestować tę trasę, najpierw wyślij poniższe żądanie:

```http
GET /me HTTP/1.1
authorization: Bearer test
```

To spowoduje, że `UserBearerAuthenticator` uwierzytelni użytkownika. Po uwierzytelnieniu `UserSessionAuthenticator` zachowa identyfikator użytkownika w pamięci sesji i wygeneruje ciasteczko. Użyj ciasteczka z odpowiedzi w drugim żądaniu do tej trasy.

```http
GET /me HTTP/1.1
cookie: vapor_session=123
```

Tym razem `UserSessionAuthenticator` uwierzytelni użytkownika i ponownie powinieneś zobaczyć zwrócony adres e-mail użytkownika.

### Model Session Authenticatable

Modele Fluent mogą generować `SessionAuthenticator`, dostosowując się do `ModelSessionAuthenticatable`. Będzie to wykorzystywać unikalny identyfikator modelu jako identyfikator sesji i automatycznie wykonywać zapytanie do bazy danych, aby przywrócić model z sesji. 

```swift
import Fluent

final class User: Model { ... }

// Allow this model to be persisted in sessions.
extension User: ModelSessionAuthenticatable { }
```

Możesz dodać `ModelSessionAuthenticatable` do dowolnego istniejącego modelu jako pustą zgodność. Po dodaniu dostępna będzie nowa statyczna metoda do tworzenia `SessionAuthenticator` dla tego modelu. 

```swift
User.sessionAuthenticator()
```

Będzie to korzystać z domyślnej bazy danych aplikacji do rozwiązywania użytkownika. Aby określić bazę danych, przekaż identyfikator.

```swift
User.sessionAuthenticator(.sqlite)
```

## Uwierzytelnianie witryny

Witryny są szczególnym przypadkiem uwierzytelniania, ponieważ użycie przeglądarki ogranicza sposób, w jaki możesz dołączyć poświadczenia do przeglądarki. Prowadzi to do dwóch różnych scenariuszy uwierzytelniania:

* początkowe logowanie za pomocą formularza
* kolejne wywołania uwierzytelniane za pomocą ciasteczka sesji

Vapor i Fluent dostarczają kilka pomocników, aby uczynić to płynnym.

### Uwierzytelnianie sesji

Uwierzytelnianie sesji działa tak, jak opisano powyżej. Musisz zastosować middleware sesji oraz authenticator sesji do wszystkich tras, do których będzie miał dostęp twój użytkownik. Obejmuje to wszystkie chronione trasy, wszystkie trasy, które są publiczne, ale mimo to chcesz mieć dostęp do użytkownika, jeśli jest zalogowany (na przykład, aby wyświetlić przycisk konta), **oraz** trasy logowania.

Możesz włączyć to globalnie w swojej aplikacji w **configure.swift** w następujący sposób:

```swift
app.middleware.use(app.sessions.middleware)
app.middleware.use(User.sessionAuthenticator())
```

Te middleware wykonują następujące czynności:

* middleware sesji pobiera ciasteczko sesji przekazane w żądaniu i przekształca je w sesję
* authenticator sesji pobiera sesję i sprawdza, czy istnieje uwierzytelniony użytkownik dla tej sesji. Jeśli tak, middleware uwierzytelnia żądanie. W odpowiedzi authenticator sesji sprawdza, czy żądanie ma uwierzytelnionego użytkownika i zapisuje go w sesji, aby był uwierzytelniony w następnym żądaniu.

!!! note
    Ciasteczko sesji domyślnie nie jest ustawione jako `secure` i `httpOnly`. Sprawdź [API Session](../advanced/sessions.md#konfiguracja) Vapora, aby dowiedzieć się więcej o konfigurowaniu ciasteczek.

### Ochrona tras

Podczas ochrony tras dla API tradycyjnie zwraca się odpowiedź HTTP z kodem statusu takim jak **401 Unauthorized**, jeśli żądanie nie jest uwierzytelnione. Nie jest to jednak najlepsze doświadczenie dla kogoś korzystającego z przeglądarki. Vapor dostarcza `RedirectMiddleware` dla dowolnego typu `Authenticatable` do użycia w takim scenariuszu:

```swift
let protectedRoutes = app.grouped(User.redirectMiddleware(path: "/login?loginRequired=true"))
```

Obiekt `RedirectMiddleware` obsługuje również przekazanie domknięcia (closure), które zwraca ścieżkę przekierowania jako `String` podczas tworzenia, do zaawansowanej obsługi adresów URL. Na przykład dołączenie ścieżki, z której nastąpiło przekierowanie, jako parametru zapytania do celu przekierowania, do zarządzania stanem.

```swift
let redirectMiddleware = User.redirectMiddleware { req -> String in
  return "/login?authRequired=true&next=\(req.url.path)"
}
```

Działa to podobnie do `GuardMiddleware`. Wszystkie żądania do tras zarejestrowanych w `protectedRoutes`, które nie są uwierzytelnione, zostaną przekierowane pod podaną ścieżkę. Pozwala to poinformować użytkowników, aby się zalogowali, zamiast po prostu zwracać **401 Unauthorized**.

Upewnij się, że dodałeś Session Authenticator przed `RedirectMiddleware`, aby zapewnić, że uwierzytelniony użytkownik zostanie załadowany przed przejściem przez `RedirectMiddleware`.

```swift
let protectedRoutes = app.grouped([User.sessionAuthenticator(), redirectMiddleware])
```

### Logowanie formularzem

Aby uwierzytelnić użytkownika i przyszłe żądania za pomocą sesji, musisz zalogować użytkownika. Vapor dostarcza protokół `ModelCredentialsAuthenticatable`, do którego można się dostosować. Obsługuje on logowanie za pomocą formularza. Najpierw dostosuj swojego `User` do tego protokołu:

```swift
extension User: ModelCredentialsAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
```

Jest to identyczne z `ModelAuthenticatable` i jeśli już jesteś z nim zgodny, nie musisz robić nic więcej. Następnie zastosuj ten middleware `ModelCredentialsAuthenticator` do żądania POST twojego formularza logowania:

```swift
let credentialsProtectedRoute = sessionRoutes.grouped(User.credentialsAuthenticator())
credentialsProtectedRoute.post("login", use: loginPostHandler)
```

Korzysta to z domyślnego authenticatora poświadczeń do ochrony trasy logowania. Musisz wysłać `username` i `password` w żądaniu POST. Możesz skonfigurować swój formularz w następujący sposób:

```html
 <form method="POST" action="/login">
    <label for="username">Username</label>
    <input type="text" id="username" placeholder="Username" name="username" autocomplete="username" required autofocus>
    <label for="password">Password</label>
    <input type="password" id="password" placeholder="Password" name="password" autocomplete="current-password" required>
    <input type="submit" value="Sign In">    
</form>
```

`CredentialsAuthenticator` wyodrębnia `username` i `password` z ciała żądania, znajduje użytkownika na podstawie nazwy użytkownika i weryfikuje hasło. Jeśli hasło jest poprawne, middleware uwierzytelnia żądanie. `SessionAuthenticator` następnie uwierzytelnia sesję dla kolejnych żądań.

## JWT

[JWT](jwt.md) dostarcza `JWTAuthenticator`, który może być używany do uwierzytelniania JSON Web Tokenów w przychodzących żądaniach. Jeśli dopiero zaczynasz z JWT, sprawdź [przegląd](jwt.md).

Najpierw utwórz typ reprezentujący ładunek (payload) JWT.

```swift
// Example JWT payload.
struct SessionToken: Content, Authenticatable, JWTPayload {

    // Constants
    let expirationTime: TimeInterval = 60 * 15
    
    // Token Data
    var expiration: ExpirationClaim
    var userId: UUID
    
    init(userId: UUID) {
        self.userId = userId
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
    }
    
    init(with user: User) throws {
        self.userId = try user.requireID()
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
    }

    func verify(using algorithm: some JWTAlgorithm) throws {
        try expiration.verifyNotExpired()
    }
}
```

Następnie możemy zdefiniować reprezentację danych zawartych w odpowiedzi po pomyślnym zalogowaniu. Na razie odpowiedź będzie miała tylko jedną właściwość, która jest stringiem reprezentującym podpisany JWT.

```swift
struct ClientTokenResponse: Content {
    var token: String
}
```

Korzystając z naszego modelu tokenu JWT i odpowiedzi, możemy użyć trasy logowania chronionej hasłem, która zwraca `ClientTokenResponse` i zawiera podpisany `SessionToken`.

```swift
let passwordProtected = app.grouped(User.authenticator(), User.guardMiddleware())
passwordProtected.post("login") { req async throws -> ClientTokenResponse in
    let user = try req.auth.require(User.self)
    let payload = try SessionToken(with: user)
    return ClientTokenResponse(token: try await req.jwt.sign(payload))
}
```

Alternatywnie, jeśli nie chcesz korzystać z authenticatora, możesz zrobić coś, co wygląda podobnie do poniższego.
```swift
app.post("login") { req async throws -> ClientTokenResponse in
    // Validate provided credential for user
    // Get userId for provided user
    let payload = try SessionToken(userId: userId)
    return ClientTokenResponse(token: try await req.jwt.sign(payload))
}
```

Dostosowując payload do `Authenticatable` i `JWTPayload`, możesz wygenerować authenticator trasy za pomocą metody `authenticator()`. Dodaj go do grupy tras, aby automatycznie pobierać i weryfikować JWT przed wywołaniem twojej trasy. 

```swift
// Create a route group that requires the SessionToken JWT.
let secure = app.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())
```

Dodanie opcjonalnego [guard middleware](#guard-middleware) będzie wymagać, aby autoryzacja się powiodła.

Wewnątrz chronionych tras możesz uzyskać dostęp do uwierzytelnionego payloadu JWT za pomocą `req.auth`. 

```swift
// Return ok reponse if the user-provided token is valid.
secure.post("validateLoggedInUser") { req -> HTTPStatus in
    let sessionToken = try req.auth.require(SessionToken.self)
    print(sessionToken.userId)
    return .ok
}
```
