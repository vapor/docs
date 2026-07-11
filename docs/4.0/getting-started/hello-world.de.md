# Hallo Welt!

In diesem Abschnitt erklären wir dir Schritt für Schritt, wie du ein neues Vapor-Projekt erstellst, baust und den Server ausführst.

Falls du _Swift_ oder die _Vapor Toolbox_ noch nicht installiert hast, wirf zuerst einen Blick in die Installationsabschnitte.

- [Installation &rarr; macOS](../install/macos.md)
- [Installation &rarr; Linux](../install/linux.md)

!!! tip
    Die Vorlage der Vapor Toolbox benötigt Swift 6.0 oder neuer.

## Neues Projekt

Der erste Schritt besteht darin, ein neues Vapor-Projekt auf deinem Computer zu erstellen. Öffne dein Terminal und nutze den Toolbox-Befehl für ein neues Projekt. Dadurch wird im aktuellen Verzeichnis ein neuer Ordner mit dem Projekt erstellt.

```sh
vapor new hello -n
```

!!! tip
    Das Flag `-n` erstellt dir eine einfache Vorlage, indem alle Fragen automatisch mit "Nein" beantwortet werden.

!!! tip
    Du kannst die neueste Vorlage auch ohne die Vapor Toolbox von GitHub erhalten, indem du das [Vorlagen-Repository](https://github.com/vapor/template-bare) klonst.

!!! tip
    Vapor und die Vorlage verwenden inzwischen standardmäßig `async`/`await`.
    Falls du nicht auf macOS 12 aktualisieren kannst und/oder weiterhin `EventLoopFuture`s verwenden musst,
    nutze das Flag `--branch macos10-15`.

Sobald der Befehl durchgelaufen ist, wechsele in den neu erstellten Ordner:


```sh
cd hello
```

## Bauen & Ausführen

### Xcode

Öffne zunächst das Projekt in Xcode:

```sh
open Package.swift
```

Xcode beginnt automatisch damit, die Abhängigkeiten des Swift Package Managers herunterzuladen. Das kann beim ersten Öffnen eines Projekts einige Zeit in Anspruch nehmen. Sobald die Abhängigkeiten aufgelöst sind, füllt Xcode die verfügbaren Schemes.

Klicke oben im Fenster, rechts neben den Play- und Stop-Buttons, auf deinen Projektnamen, um das Scheme des Projekts auszuwählen, und wähle ein passendes Run-Target aus — meist "My Mac". Klicke auf den Play-Button, um dein Projekt zu bauen und auszuführen.

Du solltest nun unten im Xcode-Fenster die Konsole sehen.

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

### Linux

Unter Linux und anderen Betriebssystemen (und auch unter macOS, falls du Xcode nicht verwenden möchtest) kannst du das Projekt in deinem bevorzugten Editor bearbeiten, wie z. B. Vim oder VSCode. Aktuelle Informationen zur Einrichtung anderer IDEs findest du in den [Swift Server Guides](https://github.com/swift-server/guides/blob/main/docs/setup-and-ide-alternatives.md).

!!! tip
    Falls du VSCode als Code-Editor verwendest, empfehlen wir die Installation der offiziellen Vapor-Erweiterung: [Vapor for VS Code](https://marketplace.visualstudio.com/items?itemName=Vapor.vapor-vscode).

Um dein Projekt zu bauen und auszuführen, führe im Terminal Folgendes aus:

```sh
swift run
```

Das baut und startet das Projekt. Beim ersten Ausführen kann das Abrufen und Auflösen der Abhängigkeiten etwas Zeit in Anspruch nehmen. Sobald es läuft, solltest du Folgendes in deiner Konsole sehen:

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

## Lokalen Server aufrufen

Öffne deinen Webbrowser und besuche <a href="http://localhost:8080/hello" target="_blank">localhost:8080/hello</a> oder <a href="http://127.0.0.1:8080" target="_blank">http://127.0.0.1:8080</a>.

Du solltest die folgende Seite sehen.

```html
Hello, world!
```

Herzlichen Glückwunsch zum Erstellen, Bauen und Ausführen deiner ersten Vapor-App! 🎉
