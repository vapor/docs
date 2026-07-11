# Installation unter Linux

Um Vapor zu nutzen, benötigst du Swift 5.9 oder höher. Dies kannst du mit dem CLI-Tool [Swiftly](https://swiftlang.github.io/swiftly/) installieren, das von der Swift Server Workgroup bereitgestellt wird (empfohlen), oder mit den Toolchains, die auf [Swift.org](https://swift.org/download/) verfügbar sind.

## Unterstützte Distributionen und Versionen

Vapor unterstützt dieselben Versionen von Linux-Distributionen, die auch von Swift 5.9 oder neueren Versionen unterstützt werden. Auf der [offiziellen Support-Seite](https://www.swift.org/platform-support/) findest du aktuelle Informationen darüber, welche Betriebssysteme offiziell unterstützt werden.

Nicht offiziell unterstützte Linux-Distributionen können Swift möglicherweise auch durch das Kompilieren des Quellcodes ausführen, allerdings kann Vapor in diesem Fall die Stabilität nicht garantieren. Mehr über das Kompilieren von Swift erfährst du im [Swift-Repo](https://github.com/apple/swift#getting-started).

## Swift installieren

### Automatisierte Installation mit dem Swiftly CLI-Tool (empfohlen)

Auf der [Swiftly-Website](https://swiftlang.github.io/swiftly/) findest du Anleitungen zur Installation von Swiftly und Swift unter Linux. Installiere Swift anschließend mit folgendem Befehl:

#### Grundlegende Verwendung

```sh
$ swiftly install latest

Fetching the latest stable Swift release...
Installing Swift 5.9.1
Downloaded 488.5 MiB of 488.5 MiB
Extracting toolchain...
Swift 5.9.1 installed successfully!

$ swift --version

Swift version 5.9.1 (swift-5.9.1-RELEASE)
Target: x86_64-unknown-linux-gnu
```

### Manuelle Installation mit der Toolchain

Auf Swift.org findest du im Leitfaden [Using Downloads](https://swift.org/download/#using-downloads) Anleitungen zur Installation von Swift unter Linux.

### Fedora

Fedora-Nutzer können Swift ganz einfach mit folgendem Befehl installieren:

```sh
sudo dnf install swift-lang
```

Wenn du Fedora 35 verwendest, musst du EPEL 8 hinzufügen, um Swift 5.9 oder neuere Versionen zu erhalten.

## Docker

Du kannst auch die offiziellen Docker-Images von Swift verwenden, die bereits mit vorinstalliertem Compiler ausgeliefert werden. Mehr dazu erfährst du auf [Swifts Docker Hub](https://hub.docker.com/_/swift).

## Toolbox installieren

Nachdem du nun Swift installiert hast, installiere die [Vapor Toolbox](https://github.com/vapor/toolbox). Dieses CLI-Tool ist nicht erforderlich, um Vapor zu benutzen, hilft dir aber dabei, neue Vapor-Projekte zu erstellen.

### Homebrew

Die Toolbox wird über Homebrew verteilt. Falls du Homebrew noch nicht installiert hast, findest du unter <a href="https://brew.sh" target="_blank">brew.sh</a> eine Installationsanleitung.

```sh
brew install vapor
```

Überprüfe, ob die Installation erfolgreich war, indem du dir die Hilfe ausgeben lässt.

```sh
vapor --help
```

Es sollte dir eine Liste der verfügbaren Befehle angezeigt werden.

### Makefile

Falls du möchtest, kannst du die Toolbox auch aus dem Quellcode selbst bauen. Auf GitHub findest du unter <a href="https://github.com/vapor/toolbox/releases" target="_blank">releases</a> die neueste Version der Toolbox.

```sh
git clone https://github.com/vapor/toolbox.git
cd toolbox
git checkout <desired version>
make install
```

Überprüfe, ob die Installation erfolgreich war, indem du dir die Hilfe ausgeben lässt.

```sh
vapor --help
```

Es sollte dir eine Liste der verfügbaren Befehle angezeigt werden.

## Nächste Schritte

Nachdem du nun Swift und die Vapor Toolbox installiert hast, erstelle deine erste App unter [Erste Schritte &rarr; Hello, world](../getting-started/hello-world.md).
