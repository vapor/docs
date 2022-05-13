# Umgebung

In Vapor gibt es mehrere Umgebungen mit denen du Einstellungen individuell vordefinieren kannst. Mit dem Wechsel der Umgebung ändert sich dann das Verhalten deiner Anwendung. Du kannst aber auch Werte direkt aus dem aktuellen Prozess abrufen oder aus einer .env-Datei laden.

| Umgebung              | Kurzform   | Beschreibung                                |
|-----------------------|------------|---------------------------------------------|
| production            | prod       | Umgebung bei Veröffentlichung.              |
| development (default) | dev        | Umgebung für Entwicklung.                   |
| testing               | test       | Umgebung zum Testen.                        |
| Vapor nutzt standardmäßig die Umgebung _Development_.                            |

## Eigenschaft

Du kannst über die Eigenschaft _Environment_ auf die laufenden Umgebung zugreifen oder zwischen den Umgebungen wechseln.

```swift
/// [configure.swift]

switch app.environment {
case .production:
    app.databases.use(....)
default:
    app.databases.use(...)
}
```

## Wechsel

```swift
vapor run serve --env production
```

## Umgebungsvariable

### Prozess

#### - Abrufen

Die Klasse _Environment_ bietet die Methode *get(_: String)* an um einen Wert abzurufen.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

Zusätzlich kannst du den Wert aber auch dynamisch über die Eigenschaft _process_ abrufen.

```swift
let foo = Environment.process.FOO
print(foo) // String?
```

#### - Definieren

In Xcode kannst du die eine Prozessvariable über das Schema _Run_ festlegen. Im Terminal benutze den Befehl _export_.

```sh
export FOO=BAR
vapor run serve
```

### .env (dotenv)

Eine .env-Datei beinhaltet Schlüssel-Wert-Paare, welche entsprechend der Umgebung geladen werden. Auf dieser Art müssen die Umgebungsvariablen nicht manuell angelegt werden. Vapor lädt die Datei aus dem Arbeitsverzeichnis.

```sh
# Key=Value
FOO=BAR
```

When your application boots, you will be able to access the contents of this file like other process environment variables.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

!!! info
    Variables specified in `.env` files will not overwrite variables that already exist in the process environment. 

Alongside `.env`, Vapor will also attempt to load a dotenv file for the current environment. For example, when in the `development` environment, Vapor will load `.env.development`. Any values in the specific environment file will take precedence over the general `.env` file.

A typical pattern is for projects to include a `.env` file as a template with default values. Specific environment files are ignored with the following pattern in `.gitignore`:

```gitignore
.env.*
```

When the project is cloned to a new computer, the template `.env` file can be copied and have the correct values inserted. 

```sh
cp .env .env.development
vim .env.development
```

!!! warning
    Dotenv files with sensitive information such as passwords should not be committed to version control.

If you're having difficulty getting dotenv files to load, try enabling debug logging with `--log debug` for more information. 

## Custom Environments

To define a custom environment name, extend `Environment`.

```swift
extension Environment {
    static var staging: Environment {
        .custom(name: "staging")
    }
}
```

The application's environment is usually set in `main.swift` using `Environment.detect()`.

```swift
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)

let app = Application(env)
defer { app.shutdown() }
```

The `detect` method uses the process's command line arguments and parses the `--env` flag automatically. You can override this behavior by initializing a custom `Environment` struct.

```swift
let env = Environment(name: "testing", arguments: ["vapor"])
```

The arguments array must contain at least one argument which represents the executable name. Further arguments can be supplied to simulate passing arguments via the command line. This is especially useful for testing.