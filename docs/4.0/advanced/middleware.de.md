# Middleware

Middleware ist eine Logikkette zwischen dem Client und einem Vapor-Route-Handler. Es ermöglicht dir, Operationen an eingehenden Requests durchzuführen, bevor sie den Route-Handler erreichen, und an ausgehenden Responses, bevor sie zum Client gesendet werden.

## Konfiguration

Middleware kann global (für jede Route) in `configure(_:)` mit `app.middleware` registriert werden.

```swift
app.middleware.use(MyMiddleware())
```

Middleware kann auch zu individuellen Routen hinzugefügt werden, in dem Route-Gruppen verwendet werden.

```swift
let group = app.grouped(MyMiddleware())
group.get("foo") { req in
	// This request has passed through MyMiddleware.
}
```

### Reihenfolge

Die Reihenfolge, in der Middleware hinzugefügt wird, ist wichtig. Requests, die in die Application eingehen, durchlaufen die Middleware in der Reihenfolge in der sie hinzugefügt werden. Responses, die die Application verlassen, gehen in umgekehrter Reihenfolge durch die Middleware zurück. Route-spezifische Middleware wird immer nach der Application-Middleware ausgeführt. Folgendes Beispiel erklärt den Sachverhalt:

```swift
app.middleware.use(MiddlewareA())
app.middleware.use(MiddlewareB())

app.group(MiddlewareC()) {
	$0.get("hello") { req in
		"Hello, middleware."
	}
}
```

Ein Request an `GET /hello` wird die Middleware in der folgenden Reihenfolge durchlaufen:

```
Request → A → B → C → Handler → C → B → A → Response
```

Middleware kann auch _vorangestellt_ werden, was nützlich ist, wenn du eine Middleware _vor_ der Standard-Middleware hinzufügen möchtest, die Vapor automatisch hinzufügt:

```swift
app.middleware.use(someMiddleware, at: .beginning)
```

## Erstellen einer Middleware

Vapor wird mit einigen nützlichen Middlewares ausgeliefert, aber es kann notwendig sein, eigene Middleware zu erstellen, um die Anforderungen deiner Anwendung zu erfüllen. Beispielsweise könntest du eine Middleware erstellen, die verhindert, dass nicht-administrative Benutzer auf eine Gruppe von Routen zugreifen.

> Wir empfehlen, einen Middleware-Ordner in deinem Sources/App-Verzeichnis zu erstellen, um deinen Code organisiert zu halten.

Middleware sind Typen, die dem Middleware- oder AsyncMiddleware-Protokoll von Vapor entsprechen. Sie werden in die Responder-Kette eingefügt und können auf einen Request zugreifen und diesen manipulieren, bevor er einen Route-Handler erreicht, und auf eine Response zugreifen und diese manipulieren, bevor sie zurückgegeben wird.

Verwende das oben erwähnte Beispiel, um eine Middleware zu erstellen, die den Zugriff für Benutzer blockiert, wenn sie keine Administratoren sind:

```swift
import Vapor

struct EnsureAdminUserMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let user = request.auth.get(User.self), user.role == .admin else {
            return request.eventLoop.future(error: Abort(.unauthorized))
        }
        return next.respond(to: request)
    }
}
```

Wenn du `async`/`await` verwendest, verwende folgendes Beispiel:

```swift
import Vapor

struct EnsureAdminUserMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(User.self), user.role == .admin else {
            throw Abort(.unauthorized)
        }
        return try await next.respond(to: request)
    }
}
```

Wenn du den Response ändern möchtest, beispielsweise um einen benutzerdefinierten Header hinzuzufügen, kannst du auch dafür eine Middleware verwenden. Die Middleware kann warten, bis der Response aus der Responder-Kette empfangen wird, und den Response manipulieren:

```swift
import Vapor

struct AddVersionHeaderMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        next.respond(to: request).map { response in
            response.headers.add(name: "My-App-Version", value: "v2.5.9")
            return response
        }
    }
}
```

Wenn du `async`/`await` verwendest, verwende folgendes Beispiel:

```swift
import Vapor

struct AddVersionHeaderMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let response = try await next.respond(to: request)
        response.headers.add(name: "My-App-Version", value: "v2.5.9")
        return response
    }
}
```

## File Middleware

FileMiddleware ermöglicht das Ausliefern von Assets aus dem Public-Ordner deines Projekts an den Client. Hier könnten statische Dateien wie Stylesheets oder Bitmap-Bilder enthalten sein.

```swift
let file = FileMiddleware(publicDirectory: app.directory.publicDirectory)
app.middleware.use(file)
```

Sobald FileMiddleware registriert ist, kann eine Datei wie `Public/images/logo.png` von einer Leaf-Vorlage aus verlinkt werden als `<img src="/images/logo.png"/>`.

Wenn dein Server in einem Xcode-Projekt enthalten ist, z. B. in einer iOS-App, verwende stattdessen Folgendes:

```swift
let file = try FileMiddleware(bundle: .main, publicDirectory: "Public")
```

Stelle auch sicher, dass du in Xcode Folder-References anstelle von Gruppen verwendest, um die Ordnerstruktur in den Ressourcen nach dem Erstellen der Anwendung beizubehalten.

## CORS Middleware

Cross-Origin Resource Sharing (CORS) ist ein Mechanismus, der es ermöglicht, dass eingeschränkte Ressourcen auf einer Webseite von einer anderen Domain angefordert werden, die nicht diejenige ist, von der die erste Ressource bereitgestellt wurde. REST-APIs, die in Vapor erstellt werden, benötigen eine CORS-Richtlinie, um sicher auf Requests von modernen Webbrowsern zu antworten.

Eine Beispielkonfiguration könnte folgendermaßen aussehen:

```swift
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
)
let cors = CORSMiddleware(configuration: corsConfiguration)
// cors-Middleware sollte vor der Standard-Fehler-Middleware mit `at: .beginning` stehen
app.middleware.use(cors, at: .beginning)
```

Da geworfene Fehler sofort an den Client zurückgegeben werden, muss die `CORSMiddleware` vor der `ErrorMiddleware` aufgeführt werden. Andernfalls wird die HTTP-Fehlerantwort ohne CORS-Header zurückgegeben und kann nicht vom Browser gelesen werden.
