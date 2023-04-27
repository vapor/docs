# Umgebung

In Vapor gibt es mehrere Umgebungen mit denen wir Standardwerte individuell für die Umgebung vordefinieren können. Mit dem Wechsel der Umgebung ändert sich automatisch das Verhalten der Anwendung. Wir können aber auch Werte direkt aus dem aktuellen Prozess abrufen oder aus einer sogenannten Umgebungsdatei (*.env) laden.

| Umgebung              | Kurzform   | Beschreibung                                |
|-----------------------|------------|---------------------------------------------|
| production            | prod       | Umgebung bei Veröffentlichung.              |
| development (default) | dev        | Umgebung für die Entwicklung.               |
| testing               | test       | Umgebung zum Testen.                        |
| Vapor nutzt standardmäßig die Umgebung _Development_.                            |

## Eigenschaft

Wir können über die Eigenschaft _Environment_ auf die laufenden Umgebung zugreifen oder zwischen den Umgebungen wechseln.

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

Zusätzlich können wir den Wert auch dynamisch über die Eigenschaft _process_ abrufen.

```swift
let foo = Environment.process.FOO
print(foo) // String?
```

#### - Bestimmen

In Xcode können wir eine Prozessvariable über das Schema _App_ festlegen. 

Im Terminal gibt es hierzu den Befehl _export_:

```sh
export FOO=BAR
vapor run serve
```

### Umgebungsdatei

Eine Umgebungsdatei besteht aus Schlüssel-Wert-Paare, welche entsprechend der Umgebung geladen werden. Auf dieser Weise müssen die Umgebungsvariablen nicht manuell angelegt werden. Vapor lädt die Datei beim Starten aus dem Arbeitsverzeichnis.

```sh
# Key=Value
FOO=BAR
```

Nach dem Starten können wir auf die angegeben Umgebungsvariablen zugreifen. Bestehende Umgebungsvariablen werden nicht durch Variablen aus der Umgebungsdatei überschrieben.

Neben der allgemeinen Umgebungsdatei _.env_, versucht Vapor zusätzlich die Umgebungsdatei für die aktuelle Umgebung zu laden. Wenn sich die Anwendung zum Beispiel in der Umgebung _Entwicklung_ befindet, wird Vapor versuchen die Datei _.env.development_ zu laden. Umgebungsvariablen aus der Umgebungsdatei _.env.development_ werden von Vapor höher als die Variablen der allgemeinen Umgebungsdatei eingestuft.

##  Benutzerdefinierte Umgebungen

In Vapor können wir eigene Umgebungen anlegen. Hierzu müssen wir nur die Klasse _Environment_  entsprechend erweitern:

```swift
extension Environment {
    static var staging: Environment {
        .custom(name: "staging")
    }
}
```

Die laufende Umgebung wird standardmäßig in der Datei _main_ über die Methode _detect()_ erkannt und gesetzt:

```swift
// [main.swift]

import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)

let app = Application(env)
defer { app.shutdown() }
```

Die Methode greift auf die Argumente der Befehlzeile zu und zieht sich den entsprechenden Wert für das Argument _--env_. 

Wir können das Standardverhalten überschreiben, indem wir die Methode durch eine neue Umgebungsdefinition ersetzen:

```swift
let env = Environment(name: "testing", arguments: ["vapor"])
```

Das Array für die Argumente muss mindestens den Wert _vapor_ behinalten.