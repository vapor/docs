# Was ist Heroku

Heroku ist eine beliebte All-in-One-Hosting-Lösung, mehr dazu findest du auf [heroku.com](https://www.heroku.com)

## Registrieren

Du benötigst ein Heroku-Konto. Falls du noch keins hast, registriere dich bitte hier: [https://signup.heroku.com/](https://signup.heroku.com/)

## CLI installieren

Stelle sicher, dass du das Heroku-CLI-Tool installiert hast.

### HomeBrew

```bash
brew tap heroku/brew && brew install heroku
```

### Weitere Installationsmöglichkeiten

Alternative Installationsmöglichkeiten findest du hier: [https://devcenter.heroku.com/articles/heroku-cli#download-and-install](https://devcenter.heroku.com/articles/heroku-cli#download-and-install).

### Anmelden

Sobald du die CLI installiert hast, melde dich mit folgendem Befehl an:

```bash
heroku login
```

Überprüfe, ob mit der richtigen E-Mail-Adresse angemeldet ist:

```bash
heroku auth:whoami
```

### Eine Anwendung erstellen

Besuche dashboard.heroku.com, um auf dein Konto zuzugreifen, und erstelle eine neue Anwendung über das Dropdown-Menü oben rechts. Heroku wird dir einige Fragen stellen, etwa nach der Region und dem Anwendungsnamen. Folge einfach den Anweisungen.

### Git

Heroku verwendet Git, um deine App zu deployen. Du musst dein Projekt also in ein Git-Repository legen, falls es das nicht schon ist.

#### Git initialisieren

Falls du Git zu deinem Projekt hinzufügen musst, gib folgenden Befehl im Terminal ein:

```bash
git init
```

#### Main

Du solltest dich für einen Branch entscheiden und dabei bleiben, um auf Heroku zu deployen, z. B. den **main**- oder **master**-Branch. Stelle sicher, dass alle Änderungen in diesen Branch eingecheckt sind, bevor du pushst.

Überprüfe deinen aktuellen Branch mit:

```bash
git branch
```

Der Stern zeigt den aktuellen Branch an.

```bash
* main
  commander
  other-branches
```

!!! note 
    Wenn du keine Ausgabe siehst und gerade erst `git init` ausgeführt hast, musst du zunächst deinen Code committen. Danach siehst du eine Ausgabe des `git branch`-Befehls.

Falls du dich _nicht_ auf dem richtigen Branch befindest, wechsle dorthin (für **main**):

```bash
git checkout main
```

#### Änderungen committen

Wenn dieser Befehl eine Ausgabe erzeugt, hast du nicht committete Änderungen.

```bash
git status --porcelain
```

Committe sie mit folgendem Befehl

```bash
git add .
git commit -m "a description of the changes I made"
```

#### Mit Heroku verbinden

Verbinde deine App mit Heroku (ersetze dies mit dem Namen deiner App).

```bash
$ heroku git:remote -a your-apps-name-here
```

### Buildpack festlegen

Lege das Buildpack fest, damit Heroku weiß, wie mit Vapor umzugehen ist.

```bash
heroku buildpacks:set vapor/vapor
```

### Swift-Versionsdatei

Das Buildpack, das wir hinzugefügt haben, sucht nach einer **.swift-version**-Datei, um zu wissen, welche Swift-Version verwendet werden soll. (Ersetze 5.8.1 durch die Version, die dein Projekt benötigt.)

```bash
echo "5.8.1" > .swift-version
```

Dies erstellt **.swift-version** mit `5.8.1` als Inhalt.

### Procfile

Heroku verwendet das **Procfile**, um zu wissen, wie deine App ausgeführt werden soll. In unserem Fall muss es folgendermaßen aussehen:

```
web: App serve --env production --hostname 0.0.0.0 --port $PORT
```

Wir können dies mit folgendem Terminal-Befehl erstellen

```bash
echo "web: App serve --env production" \
  "--hostname 0.0.0.0 --port \$PORT" > Procfile
```

### Änderungen committen

Wir haben gerade diese Dateien hinzugefügt, aber sie sind noch nicht committet. Wenn wir pushen, wird Heroku sie nicht finden.

Committe sie mit folgendem Befehl.

```bash
git add .
git commit -m "adding heroku build files"
```

### Auf Heroku deployen

Du bist bereit zum Deployen, führe dies im Terminal aus. Der Build kann eine Weile dauern, das ist normal.

```bash
git push heroku main
```

### Skalieren

Sobald der Build erfolgreich war, musst du mindestens einen Server hinzufügen. Die Preise beginnen bei $5/Monat für den Eco-Plan (siehe [Preise](https://www.heroku.com/pricing#containers)), stelle sicher, dass du eine Zahlungsmethode bei Heroku eingerichtet hast. Dann für einen einzelnen Web-Worker:

```bash
heroku ps:scale web=1
```

### Fortlaufendes Deployment

Wann immer du aktualisieren möchtest, hole einfach die neuesten Änderungen in den main-Branch und pushe sie zu Heroku, dann wird neu deployt.

## Postgres

### PostgreSQL-Datenbank hinzufügen

Besuche deine Anwendung auf dashboard.heroku.com und gehe zum Bereich **Add-ons**.

Gib hier `postgres` ein und du siehst eine Option für `Heroku Postgres`. Wähle sie aus.

Wähle den Essential-0-Plan für $5/Monat (siehe [Preise](https://www.heroku.com/pricing#data-services)) und provisioniere ihn. Heroku erledigt den Rest.

Sobald du fertig bist, erscheint die Datenbank im Tab **Resources**.

### Die Datenbank konfigurieren

Wir müssen unserer App nun mitteilen, wie sie auf die Datenbank zugreifen soll. Führe in deinem App-Verzeichnis Folgendes aus.

```bash
heroku config
```

Dies erzeugt eine Ausgabe etwa wie diese

```none
=== today-i-learned-vapor Config Vars
DATABASE_URL: postgres://cybntsgadydqzm:2d9dc7f6d964f4750da1518ad71hag2ba729cd4527d4a18c70e024b11cfa8f4b@ec2-54-221-192-231.compute-1.amazonaws.com:5432/dfr89mvoo550b4
```

**DATABASE_URL** steht hier für unsere Postgres-Datenbank. Hardcode **NIEMALS** die statische URL daraus, Heroku rotiert sie und das würde deine Anwendung kaputt machen. Es ist außerdem schlechte Praxis. Lies stattdessen die Umgebungsvariable zur Laufzeit aus.

Das Heroku-Postgres-Addon [erfordert](https://devcenter.heroku.com/changelog-items/2035), dass alle Verbindungen verschlüsselt sind. Die von den Postgres-Servern verwendeten Zertifikate sind intern bei Heroku, daher muss eine **unverifizierte** TLS-Verbindung eingerichtet werden.

Das folgende Snippet zeigt, wie man beides erreicht:

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    var tlsConfig: TLSConfiguration = .makeClientConfiguration()
    tlsConfig.certificateVerification = .none
    let nioSSLContext = try NIOSSLContext(configuration: tlsConfig)

    var postgresConfig = try SQLPostgresConfiguration(url: databaseURL)
    postgresConfig.coreConfiguration.tls = .require(nioSSLContext)

    app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
} else {
    // ...
}
```

Vergiss nicht, diese Änderungen zu committen

```bash
git add .
git commit -m "configured heroku database"
```

### Deine Datenbank zurücksetzen

Du kannst deine Datenbank zurücksetzen oder andere Befehle auf Heroku mit dem `run`-Befehl ausführen.

Um deine Datenbank zurückzusetzen:

```bash
heroku run App -- migrate --revert --all --yes --env production
```

Um zu migrieren:

```bash
heroku run App -- migrate --env production
```
