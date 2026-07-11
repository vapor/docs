# Umgebung

Vapor's Environment API hilft dir, deine Anwendung dynamisch zu konfigurieren. Standardmäßig verwendet deine Anwendung die Umgebung `development`. Du kannst weitere nützliche Umgebungen wie `production` oder `staging` definieren und festlegen, wie deine Anwendung in jedem Fall konfiguriert wird. Du kannst außerdem Variablen aus der Prozessumgebung oder aus `.env`-Dateien (dotenv) laden, je nach Bedarf.

Um auf die aktuelle Umgebung zuzugreifen, verwende `app.environment`. Du kannst in `configure(_:)` anhand dieser Eigenschaft unterscheiden, um unterschiedliche Konfigurationslogik auszuführen.

```swift
switch app.environment {
case .production:
    app.databases.use(....)
default:
    app.databases.use(...)
}
```

## Wechsel der Umgebung

Standardmäßig läuft deine Anwendung in der Umgebung `development`. Du kannst dies ändern, indem du beim Start der Anwendung das Flag `--env` (`-e`) übergibst.

```swift
swift run App serve --env production
```

Vapor enthält die folgenden Umgebungen:

|name|short|description|
|-|-|-|
|production|prod|Für deine Nutzer bereitgestellt.|
|development|dev|Lokale Entwicklung.|
|testing|test|Für Unit-Tests.|

!!! info
    Die Umgebung `production` verwendet standardmäßig die Protokollstufe `notice`, sofern nicht anders angegeben. Alle anderen Umgebungen verwenden standardmäßig `info`.

Du kannst dem Flag `--env` (`-e`) entweder den vollständigen oder den kurzen Namen übergeben.

```swift
swift run App serve -e prod
```

## Prozessvariablen

`Environment` bietet eine einfache, string-basierte API für den Zugriff auf die Umgebungsvariablen des Prozesses.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

Zusätzlich zu `get` bietet `Environment` eine API für den dynamischen Zugriff auf Member über `process`.

```swift
let foo = Environment.process.FOO
print(foo) // String?
```

Wenn du deine Anwendung im Terminal ausführst, kannst du Umgebungsvariablen mit `export` setzen.

```sh
export FOO=BAR
swift run App serve
```

Wenn du deine Anwendung in Xcode ausführst, kannst du Umgebungsvariablen festlegen, indem du das Schema `App` bearbeitest.

## .env (dotenv)

Dotenv-Dateien enthalten eine Liste von Schlüssel-Wert-Paaren, die automatisch in die Umgebung geladen werden. Diese Dateien erleichtern die Konfiguration von Umgebungsvariablen, ohne sie manuell setzen zu müssen.

Vapor sucht im aktuellen Arbeitsverzeichnis nach Dotenv-Dateien. Wenn du Xcode verwendest, stelle sicher, dass du das Arbeitsverzeichnis über das Schema `App` festlegst.

Angenommen, die folgende `.env`-Datei befindet sich im Stammverzeichnis deines Projekts:

```sh
FOO=BAR
```

Beim Start deiner Anwendung kannst du auf den Inhalt dieser Datei wie auf andere Umgebungsvariablen des Prozesses zugreifen.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

!!! info
    Variablen, die in `.env`-Dateien angegeben sind, überschreiben keine Variablen, die bereits in der Prozessumgebung vorhanden sind.

Neben `.env` versucht Vapor außerdem, eine Dotenv-Datei für die aktuelle Umgebung zu laden. Wenn du dich zum Beispiel in der Umgebung `development` befindest, lädt Vapor `.env.development`. Werte in der spezifischen Umgebungsdatei haben Vorrang vor der allgemeinen `.env`-Datei.

Ein typisches Muster ist, dass Projekte eine `.env`-Datei als Vorlage mit Standardwerten enthalten. Spezifische Umgebungsdateien werden mit folgendem Muster in `.gitignore` ignoriert:

```gitignore
.env.*
```

Wenn das Projekt auf einen neuen Computer geklont wird, kann die `.env`-Vorlagendatei kopiert und mit den richtigen Werten versehen werden.

```sh
cp .env .env.development
vim .env.development
```

!!! warning
    Dotenv-Dateien mit sensiblen Informationen wie Passwörtern sollten nicht in die Versionskontrolle übernommen werden.

Wenn du Schwierigkeiten hast, Dotenv-Dateien zu laden, versuche, das Debug-Logging mit `--log debug` zu aktivieren, um weitere Informationen zu erhalten.

## Benutzerdefinierte Umgebungen

Um einen benutzerdefinierten Umgebungsnamen zu definieren, erweitere `Environment`.

```swift
extension Environment {
    static var staging: Environment {
        .custom(name: "staging")
    }
}
```

Die Umgebung der Anwendung wird üblicherweise in `entrypoint.swift` mit `Environment.detect()` gesetzt.

```swift
@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = Application(env)
        defer { app.shutdown() }
        
        try await configure(app)
        try await app.runFromAsyncMainEntrypoint()
    }
}
```

Die Methode `detect` verwendet die Kommandozeilenargumente des Prozesses und wertet das Flag `--env` automatisch aus. Du kannst dieses Verhalten überschreiben, indem du eine benutzerdefinierte `Environment`-Struktur initialisierst.

```swift
let env = Environment(name: "testing", arguments: ["vapor"])
```

Das Argument-Array muss mindestens ein Argument enthalten, das den Namen der ausführbaren Datei repräsentiert. Weitere Argumente können angegeben werden, um das Übergeben von Argumenten über die Kommandozeile zu simulieren. Dies ist besonders nützlich für Tests.
