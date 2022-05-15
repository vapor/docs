# Hallo Welt!

In diesem Abschnitt erklären wir dir Schritt für Schritt, wie du ein Vapor-Projekt erstellst und ausführst. Sollte dir _Swift_ oder die _Vapor Toolbox_ noch fehlen, werfe zuerst einen Blick in die beiden Abschnitte [Installation &rarr; macOS](../install/macos.md) und [Installation &rarr; Linux](../install/linux.md).


## Projekt erstellen

Starte die Terminal-App auf deinem Mac und führe den Toolbox-Befehl aus. Der Befehl erstellt einen Projektordner mitsamt den Dateien.

```sh
vapor new hello -n
```

Sobald der Befehl durchgelaufen ist, wechsele in den neuen Ordner mit dem Befehl

```sh
cd hello
``` 

## Projekt ausführen

Je nach System oder Entwicklungsumgebung muss das Projekt unterschiedlich ausgeführt werden:

### - mit Xcode

Öffne das Projekt mit dem Befehl

```sh
open Package.swift
```

Xcode öffnet sich und lädt zu Beginn alle notwendigen Paketverweise. Nach dem Laden sollte dir Xcode zur Verfügung stehen. Wähle anschließend in der Mitte eine Schema (oft einfach nur "My Mac") aus. Starte nun das Projekt über die Menüpunkte _Product_ > _Run_. Du solltest nun in der Konsole einen Eintrag wie diesen sehen:

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

### - mit Linux

Für Linux-Distributionen (oder falls du einfach kein Xcode verwendest) kannst du den Editor deiner Wahl nutzen, wie z.B. Vim oder VSCode. Mehr Informationen dazu, findest du im Abschnitt [Swift Server Guides](https://github.com/swift-server/guides/blob/main/docs/setup-and-ide-alternatives.md).

Starte das Projekt mit dem Befehl

```sh
swift run
```

Bei der Erstausführung werden die Paketverweise nachgeladen. Dementsprechend kann die Erstellung ein wenig brauchen. Nach dem Laden solltest einen Eintrag im Terminal sehen

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

## Aufruf im Browser

Rufe die Seite über den Link <a href="http://localhost:8080/hello" target="_blank">localhost:8080/hello</a> oder <a href="http://127.0.0.1:8080" target="_blank">http://127.0.0.1:8080</a> im Browser auf. Als Ergebnis sollte "Hello World" im Browser erscheinen.

Das wars! Geschafft! Gratulation zur ersten Vapor-Anwendung. 🎉
