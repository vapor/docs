# Fly

Fly ist eine Hosting-Plattform, die das Ausführen von Serveranwendungen und Datenbanken mit Fokus auf Edge Computing ermöglicht. Weitere Informationen findest du auf [ihrer Website](https://fly.io/).

!!! note
    Die in diesem Dokument beschriebenen Befehle unterliegen [Flys Preisgestaltung](https://fly.io/docs/about/pricing/); stelle sicher, dass du diese richtig verstanden hast, bevor du fortfährst.

## Registrieren
Falls du noch kein Konto hast, musst du [eines erstellen](https://fly.io/app/sign-up).

## flyctl installieren
Der Hauptweg, um mit Fly zu interagieren, ist die Verwendung des dedizierten CLI-Tools `flyctl`, das du installieren musst.

### macOS
```bash
brew install flyctl
```

### Linux
```bash
curl -L https://fly.io/install.sh | sh
```

### Weitere Installationsoptionen
Weitere Optionen und Details findest du in der [Installationsdokumentation von `flyctl`](https://fly.io/docs/flyctl/install/).

## Anmelden
Um dich über dein Terminal anzumelden, führe den folgenden Befehl aus:
```bash
fly auth login
```

## Dein Vapor-Projekt konfigurieren
Bevor du auf Fly deployst, musst du sicherstellen, dass du ein Vapor-Projekt mit einem angemessen konfigurierten Dockerfile hast, da Fly dieses zum Bauen deiner App benötigt. In den meisten Fällen sollte das sehr einfach sein, da die Standard-Vapor-Templates bereits eines enthalten.

### Neues Vapor-Projekt
Der einfachste Weg, ein neues Projekt zu erstellen, ist der Start mit einem Template. Du kannst eines mithilfe von GitHub-Templates oder der Vapor Toolbox erstellen. Falls du eine Datenbank benötigst, wird empfohlen, Fluent mit Postgres zu verwenden; Fly macht es einfach, eine Postgres-Datenbank zu erstellen, um deine Apps damit zu verbinden (siehe den [entsprechenden Abschnitt](#postgres-konfigurieren) weiter unten).

#### Verwendung der Vapor Toolbox
Stelle zunächst sicher, dass du die Vapor Toolbox installiert hast (siehe die Installationsanweisungen für [macOS](../install/macos.md#toolbox-installieren) oder [Linux](../install/linux.md#toolbox-installieren)).
Erstelle deine neue App mit folgendem Befehl, wobei du `app-name` durch den gewünschten App-Namen ersetzt:
```bash
vapor new app-name
```

Dieser Befehl zeigt eine interaktive Eingabeaufforderung an, mit der du dein Vapor-Projekt konfigurieren kannst; hier kannst du Fluent und Postgres auswählen, falls du sie benötigst.

#### Verwendung von GitHub-Templates
Wähle das Template, das deinen Bedürfnissen am besten entspricht, aus der folgenden Liste. Du kannst es entweder lokal mit Git klonen oder über die Schaltfläche „Use this template“ ein GitHub-Projekt erstellen.

- [Barebones-Template](https://github.com/vapor/template-bare)
- [Fluent/Postgres-Template](https://github.com/vapor/template-fluent-postgres)
- [Fluent/Postgres + Leaf-Template](https://github.com/vapor/template-fluent-postgres-leaf)

### Bestehendes Vapor-Projekt
Falls du bereits ein Vapor-Projekt hast, stelle sicher, dass ein korrekt konfiguriertes `Dockerfile` im Stammverzeichnis vorhanden ist; die [Vapor-Dokumentation zur Verwendung von Docker](../deploy/docker.md) und die [Fly-Dokumentation zum Deployment einer App per Dockerfile](https://fly.io/docs/languages-and-frameworks/dockerfile/) könnten dabei nützlich sein.

## Deine App auf Fly starten
Sobald dein Vapor-Projekt bereit ist, kannst du es auf Fly starten.

Stelle zunächst sicher, dass dein aktuelles Verzeichnis das Stammverzeichnis deiner Vapor-Anwendung ist, und führe den folgenden Befehl aus:
```bash
fly launch
```

Dies startet eine interaktive Eingabeaufforderung, um die Einstellungen deiner Fly-Anwendung zu konfigurieren:

- **Name:** Du kannst einen eingeben oder das Feld leer lassen, um einen automatisch generierten Namen zu erhalten.
- **Region:** Standardmäßig wird die Region gewählt, die dir am nächsten liegt. Du kannst diese verwenden oder eine andere aus der Liste wählen. Dies lässt sich später leicht ändern.
- **Datenbank:** Du kannst Fly bitten, eine Datenbank für deine App zu erstellen. Falls gewünscht, kannst du dies auch später mit den Befehlen `fly pg create` und `fly pg attach` nachholen (weitere Details im Abschnitt [Postgres konfigurieren](#postgres-konfigurieren)).

Der Befehl `fly launch` erstellt automatisch eine `fly.toml`-Datei. Sie enthält Einstellungen wie private/öffentliche Port-Zuordnungen, Health-Check-Parameter und vieles mehr. Falls du gerade mit `vapor new` ein neues Projekt von Grund auf erstellt hast, benötigt die Standard-`fly.toml`-Datei keine Änderungen. Falls du ein bestehendes Projekt hast, ist es wahrscheinlich, dass auch die `fly.toml` ohne oder mit nur geringfügigen Änderungen funktioniert. Weitere Informationen findest du in der [Dokumentation zu `fly.toml`](https://fly.io/docs/reference/configuration/).

Beachte, dass du, falls du Fly bittest, eine Datenbank zu erstellen, etwas warten musst, bis diese erstellt wurde und die Health-Checks besteht.

Bevor der Vorgang beendet wird, fragt dich der Befehl `fly launch`, ob du deine App sofort deployen möchtest. Du kannst dies annehmen oder es später mit `fly deploy` erledigen.

!!! tip
    Wenn dein aktuelles Verzeichnis das Stammverzeichnis deiner App ist, erkennt das Fly-CLI-Tool automatisch das Vorhandensein einer `fly.toml`-Datei, wodurch Fly weiß, auf welche App sich deine Befehle beziehen. Wenn du unabhängig von deinem aktuellen Verzeichnis eine bestimmte App ansprechen möchtest, kannst du bei den meisten Fly-Befehlen `-a name-deiner-app` anhängen.

## Deployen
Du führst den Befehl `fly deploy` aus, wann immer du neue Änderungen auf Fly deployen musst.

Fly liest die `Dockerfile`- und `fly.toml`-Dateien in deinem Verzeichnis, um zu bestimmen, wie dein Vapor-Projekt gebaut und ausgeführt werden soll.

Sobald dein Container gebaut ist, startet Fly eine Instanz davon. Dabei werden verschiedene Health-Checks durchgeführt, um sicherzustellen, dass deine Anwendung einwandfrei läuft und dein Server auf Anfragen reagiert. Der Befehl `fly deploy` beendet sich mit einem Fehler, falls die Health-Checks fehlschlagen.

Standardmäßig führt Fly ein Rollback auf die zuletzt funktionierende Version deiner App durch, falls die Health-Checks für die neue Version, die du zu deployen versucht hast, fehlschlagen.

Wenn du einen Background Worker (mit Vapor Queues) deployst, ändere nicht `CMD` oder `ENTRYPOINT` in deinem Dockerfile; lasse dies unverändert, damit die Hauptwebanwendung normal startet. Füge stattdessen einen `[processes]`-Abschnitt in deiner `fly.toml`-Datei hinzu, etwa so:

```
[processes]
  app = ""
  worker = "queues"
```

Dies teilt Fly.io mit, den `app`-Prozess mit dem Standard-Docker-Entrypoint (deinem Webserver) auszuführen, und den `worker`-Prozess deine Job Queue mithilfe der Kommandozeilenschnittstelle von Vapor ausführen zu lassen (d. h. `swift run App queues`).

## Postgres konfigurieren

### Eine Postgres-Datenbank auf Fly erstellen
Falls du beim ersten Starten deiner App keine Datenbank-App erstellt hast, kannst du dies später mit folgendem Befehl nachholen:
```bash
fly pg create
```

Dieser Befehl erstellt eine Fly-App, die in der Lage ist, Datenbanken zu hosten, die deinen anderen Apps auf Fly zur Verfügung stehen; weitere Details findest du in der [entsprechenden Fly-Dokumentation](https://fly.io/docs/postgres/).

Sobald deine Datenbank-App erstellt ist, gehe in das Stammverzeichnis deiner Vapor-App und führe Folgendes aus:
```bash
fly pg attach name-deiner-postgres-app
```
Falls du den Namen deiner Postgres-App nicht kennst, kannst du ihn mit `fly pg list` finden.

Der Befehl `fly pg attach` erstellt eine Datenbank und einen Benutzer für deine App und macht diese anschließend über die Umgebungsvariable `DATABASE_URL` für deine App zugänglich.

!!! note
    Der Unterschied zwischen `fly pg create` und `fly pg attach` besteht darin, dass Ersteres eine Fly-App bereitstellt und konfiguriert, die in der Lage ist, Postgres-Datenbanken zu hosten, während Letzteres eine tatsächliche Datenbank und einen Benutzer für die App deiner Wahl erstellt. Sofern es deinen Anforderungen entspricht, könnte eine einzelne Postgres-Fly-App mehrere Datenbanken hosten, die von verschiedenen Apps verwendet werden. Wenn du Fly bittest, in `fly launch` eine Datenbank-App zu erstellen, entspricht das dem gleichzeitigen Aufruf von `fly pg create` und `fly pg attach`.

### Deine Vapor-App mit der Datenbank verbinden
Sobald deine App mit deiner Datenbank verknüpft ist, setzt Fly die Umgebungsvariable `DATABASE_URL` auf die Verbindungs-URL, die deine Zugangsdaten enthält (sie sollte als vertrauliche Information behandelt werden).

Bei den meisten gängigen Vapor-Projektkonfigurationen konfigurierst du deine Datenbank in `configure.swift`. So könntest du dabei vorgehen:

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    try app.databases.use(.postgres(url: databaseURL), as: .psql)
} else {
    // Handle missing DATABASE_URL here...
    //
    // Alternatively, you could also set a different config 
    // depending on wether app.environment is set to to 
    // `.development` or `.production`
}
```

An diesem Punkt sollte dein Projekt bereit sein, Migrationen auszuführen und die Datenbank zu verwenden.

### Migrationen ausführen
Mit dem `release_command` von `fly.toml` kannst du Fly bitten, vor dem Start deines Hauptserverprozesses einen bestimmten Befehl auszuführen. Füge Folgendes zu `fly.toml` hinzu:
```toml
[deploy]
 release_command = "migrate -y"
```

!!! note
    Der obige Codeausschnitt geht davon aus, dass du das Standard-Vapor-Dockerfile verwendest, das den `ENTRYPOINT` deiner App auf `./App` setzt. Konkret bedeutet dies, dass Fly, wenn du `release_command` auf `migrate -y` setzt, `./App migrate -y` aufruft. Falls dein `ENTRYPOINT` auf einen anderen Wert gesetzt ist, musst du den Wert von `release_command` entsprechend anpassen.

Fly führt deinen Release-Befehl in einer temporären Instanz aus, die Zugriff auf dein internes Fly-Netzwerk, deine Secrets und deine Umgebungsvariablen hat.

Falls dein Release-Befehl fehlschlägt, wird das Deployment nicht fortgesetzt.

### Andere Datenbanken
Auch wenn es mit Fly einfach ist, eine Postgres-Datenbank-App zu erstellen, ist es möglich, auch andere Arten von Datenbanken zu hosten (siehe zum Beispiel ["Use a MySQL database"](https://fly.io/docs/app-guides/mysql-on-fly/) in der Fly-Dokumentation).

## Secrets und Umgebungsvariablen
### Secrets
Verwende Secrets, um vertrauliche Werte als Umgebungsvariablen zu setzen.
```bash
 fly secrets set MYSECRET=A_SUPER_SECRET_VALUE
```

!!! warning
    Beachte, dass die meisten Shells eine Historie der eingegebenen Befehle speichern. Sei vorsichtig damit, wenn du Secrets auf diese Weise setzt. Manche Shells können so konfiguriert werden, dass sie sich Befehle, denen ein Leerzeichen vorangestellt ist, nicht merken. Siehe auch den Befehl [`fly secrets import`](https://fly.io/docs/flyctl/secrets-import/).

Weitere Informationen findest du in der [Dokumentation zu `fly secrets`](https://fly.io/docs/apps/secrets/).

### Umgebungsvariablen
Du kannst weitere, nicht vertrauliche [Umgebungsvariablen in `fly.toml`](https://fly.io/docs/reference/configuration/#the-env-variables-section) setzen, zum Beispiel:
```toml
[env]
  MAX_API_RETRY_COUNT = "3"
  SMS_LOG_LEVEL = "error"
```

## SSH-Verbindung
Du kannst dich mit den Instanzen einer App verbinden, indem du Folgendes verwendest:
```bash
fly ssh console -s
```

## Logs überprüfen
Du kannst die Live-Logs deiner App mit folgendem Befehl überprüfen:
```bash
fly logs
```

## Nächste Schritte
Jetzt, da deine Vapor-App deployt ist, gibt es noch viel mehr, was du tun kannst, etwa deine Apps vertikal und horizontal über mehrere Regionen hinweg skalieren, persistente Volumes hinzufügen, Continuous Deployment einrichten oder sogar verteilte App-Cluster erstellen. Der beste Ort, um all dies und mehr zu lernen, ist die [Fly-Dokumentation](https://fly.io/docs/).
