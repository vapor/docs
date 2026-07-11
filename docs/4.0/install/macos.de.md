# Installation unter macOS

Um Vapor unter macOS zu benutzen, benötigst du Swift 5.9 oder neuer. Swift und alle seine Abhängigkeiten werden zusammen mit Xcode installiert.

## Xcode installieren

Installiere [Xcode](https://itunes.apple.com/us/app/xcode/id497799835?mt=12) aus dem Mac App Store.

![Xcode in Mac App Store](../images/xcode-mac-app-store.png)

Nachdem Xcode heruntergeladen wurde, musst du es öffnen, um die Installation abzuschließen. Das kann eine Weile dauern.

Überprüfe, ob die Installation erfolgreich war, indem du das Terminal öffnest und dir die Version von Swift ausgeben lässt.

```sh
swift --version
```

Es sollten dir die Versionsinformationen von Swift angezeigt werden.

```sh
swift-driver version: 1.75.2 Apple Swift version 5.8 (swiftlang-5.8.0.124.2 clang-1403.0.22.11.100)
Target: arm64-apple-macosx13.0
```

Vapor 4 benötigt Swift 5.9 oder neuer.

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
