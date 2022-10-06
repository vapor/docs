# Installation unter macOS

Die Mindestvoraussetzung für Vapor unter macOS ist Swift 5.2 (oder aktueller).

## Xcode

Xcode ist Apple`s eigene Entwicklungsumgebung. Du findest die App im [AppStore](https://itunes.apple.com/us/app/xcode/id497799835?mt=12). Mit der Installation von Xcode wird auch gleich Swift mitinstalliert.

![Xcode in Mac App Store](../images/xcode-mac-app-store.png)

Sobald du die App heruntergeladen hast, führe die Installation aus. Starte nach der Installation Xcode um die Installation komplett abzuschließen. Mit dem Termin-Befehl `swift --version` kannst du überprüfen, ob die Installation von Swift erfolgreich verlief und welche Version genau installiert wurde.

```sh
swift --version

Apple Swift version 5.2 (swiftlang-1100.0.270.13 clang-1100.0.33.7)
Target: x86_64-apple-darwin19.0.0
```

## Toolbox

Neben Swift kannst du auch die Vapor-Toolbox installieren. Die Toolbox ist zwar für Vapor nicht zwingend notwendig, aber beinhaltet Befehle, die dich bei der Arbeit mit Vapor unterstützen.

Du kannst die Toolbox mittels [Homebrew](https://brew.sh) installieren:

```sh
brew install vapor
```

Nach den Installationen kannst du mit der Erstellung deiner ersten Vapor-Anwendung beginnen. Folge dazu den Anweisungen im Abschnitt [Erste Schritte → Hello, world](../getting-started/hello-world.de.md).
