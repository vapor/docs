# Xcode

 Dieser Abschnitt geht auf Tipps und Tricks zur Verwendung von Vapor in Xcode ein. Solltest du eine andere Entwicklungsumgebung verwenden, kannst du natürlich den Abschnitt überspringen.

 ## Arbeitsverzeichnis

 Xcode greift standardmäßig auf den _Derived Data_-Ordner zu. Der Ordner ist fälschlicherweise jedoch nicht das Arbeitsverzeichnis deines Projektes, weshalb Vapor beispielweise den _Public_-Ordner oder die Datei mit Umgebungsvariablen nicht vorfinden kann. Xcode gibt daraufhin eine Fehlermeldung aus:

 ```
 [ WARNING ] No custom working directory set for this scheme, using /path/to/DerivedData/project-abcdef/Build/
 ```

 Um das Problem zu lösen, musst du den Pfad zu deinem Projekt in Schemen-Editor hinterlegen. Rufe über die den Menüpunkte _Products > Scheme > Edit Scheme..._  den Editor auf und wähle das Schema _App_ aus.
 
 Klicke in der rechten Fensterhälfte auf den Reiter _Options_ und gebe unter dem Punkt _Working Directory_ den Pfad zu deinem Projekt mit an.

 ![Xcode Scheme Options](../images/xcode-scheme-options.png)

 Für den Fall, dass du den Pfad zu deinem Projekt nicht kennst, kannst du mit Hilfe des Terminal-Befehls 'pwd' den Pfad ganz einfach herausfinden.

 ```sh
 # get path to this folder
 pwd
 ```

 ```
 /path/to/project
 ```