# Hallo, wereld

Deze gids zal je stap voor stap begeleiden in het maken van een nieuw Vapor project, het bouwen ervan, en het draaien van de server.

Als je nog niet Swift hebt geïnstalleerd of de Vapor Toolbox, bekijk de installatie sectie.

- [Installeren &rarr; macOS](../install/macos.md)
- [Installeren &rarr; Linux](../install/linux.md)

## Nieuw Project

De eerste stap bestaat uit een nieuw Vapor project te maken op je computer. Open je terminal en gebruik het nieuw project commando van de Toolbox. Dit zal een nieuwe map aanmaken in je huidige directory met daarin het project.

```sh
vapor new hello -n
```

!!! tip
	De `-n` vlag geeft je een kaal sjabloon door automatisch nee te antwoorden op alle vragen.

!!! tip
    Vapor en het sjabloon gebruiken nu standaard `async`/`await`. Als je niet kunt updaten naar macOS 12 en/of `EventLoopFuture` wilt blijven gebruiken, gebruik dan de vlag `--branch macos10-15`.

Eens het commando voltooid is, navigeer naar de nieuw aangemaakt map:

```sh
cd hello
``` 

## Bouwen en uitvoeren

### Xcode

Om te beginnen, open het project in Xcode:

```sh
open Package.swift
```

Het zal automatisch beginnen met het downloaden van de Swift Package Manager afhankelijkheden. Dit kan enige tijd duren de eerste keer dat u een project opent. Wanneer dependency resolution voltooid is, zal Xcode de beschikbare schema's vullen.

Bovenaan het venster, rechts van de knoppen Afspelen en Stoppen, klikt u op uw projectnaam om het schema van het project te selecteren. Hier selecteert u een geschikt uitvoerdoel, waarschijnlijk "My Mac". Klik op de afspeelknop om uw project te bouwen en uit te voeren.

Je zou de Console moeten zien verschijnen aan de onderkant van het Xcode venster.

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

### Linux

Op Linux en andere besturingssystemen (en zelfs op macOS als je Xcode niet wilt gebruiken) kun je het project bewerken in je favoriete editor naar keuze, zoals Vim of VSCode. Zie de [Swift Server Guides](https://github.com/swift-server/guides/blob/main/docs/setup-and-ide-alternatives.md) voor actuele details over het instellen van andere IDE's.

Om je project te bouwen en uit te voeren, voer je in Terminal uit:

```sh
swift run
```

Dat zal het project bouwen en uitvoeren. De eerste keer dat je dit uitvoert zal het even duren om de afhankelijkheden op te halen en op te lossen. Eenmaal draaiend zou je het volgende in je console moeten zien:

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

## Bezoek Localhost

Open je webbrowser, en bezoek <a href="http://localhost:8080/hello" target="_blank">localhost:8080/hello</a> of <a href="http://127.0.0.1:8080" target="_blank">http://127.0.0.1:8080</a>

Je zou de volgende pagina moeten zien.

```html
Hello, world!
```

Gefeliciteerd met het maken, bouwen en uitvoeren van je eerste Vapor app! 🎉