# Installation unter macOS

Die Mindestvoraussetzung für Vapor unter macOS ist Swift 5.9 (oder aktueller).

## Xcode

Xcode ist Apple`s eigene Entwicklungsumgebung. Du findest die App im [AppStore](https://itunes.apple.com/us/app/xcode/id497799835?mt=12). Mit der Installation von Xcode wird auch gleich Swift mitinstalliert.

![Xcode in Mac App Store](../images/xcode-mac-app-store.png)

Sobald du die App heruntergeladen hast, führe die Installation aus. Starte nach der Installation Xcode um die Installation komplett abzuschließen. Mit dem Termin-Befehl `swift --version` kannst du überprüfen, ob die Installation von Swift erfolgreich verlief und welche Version genau installiert wurde.

```sh
swift --version

swift-driver version: 1.75.2 Apple Swift version 5.8 (swiftlang-5.8.0.124.2 clang-1403.0.22.11.100)
Target: arm64-apple-macosx13.0
```

## Toolbox

Neben Swift kannst du auch die Vapor-Toolbox installieren. Die Toolbox ist zwar für Vapor nicht zwingend notwendig, aber beinhaltet Befehle, die dich bei der Arbeit mit Vapor unterstützen.

Du kannst die Toolbox mittels [Homebrew](https://brew.sh) installieren:

```sh
brew install vapor
```

Nach den Installationen kannst du mit der Erstellung deiner ersten Vapor-Anwendung beginnen. Folge dazu den Anweisungen im Abschnitt [Erste Schritte → Hello, world](../getting-started/hello-world.md).
