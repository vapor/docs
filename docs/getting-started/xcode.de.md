# Xcode

Dieser Abschnitt geht auf Tipps und Tricks zur Verwendung von Vapor mit Xcode ein. Solltest eine andere Entwicklungsumgebung verwenden, kannst du gerne den Abschnitt überspringen.

## Custom Working Directory

Xcode greift standartmäßig auf den _DerivedData_-Ordner zu, weshalb Vapor nicht den Ordner _Public_ oder deine Datei mit den Umgebungsvariablen (.env) finden kann. Xcode gibt daraufhin eine Fehlermeldung aus:


```
[ WARNING ] No custom working directory set for this scheme, using /path/to/DerivedData/project-abcdef/Build/
```

Um das Problem zu lösen, musst du Xcode den Pfad zum _Custom working directory_ mitteilen.

Rufe dazu den _Scheme Editor_ über die den Menüpunkte _Products > Scheme > Edit Scheme..._ auf und wähle im Editor das Schema _Run_. Wähle in der rechten Fensterhälfte den Reiter _Options_ aus und gebe den Pfad zu deinem Projekt unter dem Punkt _Working Directory_ mit an.

![Xcode Scheme Options](../images/xcode-scheme-options.png)

Für den Fall, dass du den Pfad zu deinem Projekt nicht kennst, kannst du mit Hilfe des Terminal-Befehls 'pwd' den Pfad ganz einfach herausfinden.

Beispiel:
```
# verify we are in vapor project folder
vapor --version
# get path to this folder
pwd
```

Ausgabe:

```
framework: 4.x.x
toolbox: 18.x.x
/path/to/project
```