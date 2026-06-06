# Bijdragen tot Vapor

Vapor is een community-gedreven project en bijdragen van community-leden vormen een belangrijk deel van de ontwikkeling van Vapor. Deze gids zal u helpen het bijdrage proces te begrijpen en u helpen uw eerste commits te maken in Vapor!

Elke bijdrage die u levert is nuttig! Zelfs kleine dingen zoals het verbeteren van typefouten maken een groot verschil voor mensen die Vapor gebruiken.

## Code of Conduct

Vapor heeft de Gedragscode van Swift aangenomen die te vinden is op [https://www.swift.org/code-of-conduct/](https://www.swift.org/code-of-conduct/). Van alle bijdragers wordt verwacht dat zij zich aan de gedragscode houden.

## Waar kan ik aan werken

Uitzoeken waar je aan gaat werken kan een groot obstakel zijn als je aan de slag wilt in open source! Meestal zijn de beste dingen om aan te werken problemen die je vindt of functies die je wilt. Vapor heeft echter een aantal handige dingen om u te helpen bijdragen.

### Security Issues

Als je een beveiligingsprobleem ontdekt en dit wilt rapporteren of helpen oplossen, dien dan **geen** issue aan te maken of een pull request aan te maken. We hebben een apart proces voor beveiligingsproblemen om er zeker van te zijn dat we geen kwetsbaarheid blootstellen totdat er een oplossing beschikbaar is. Email security@vapor.codes of [zie hier](https://github.com/vapor/.github/blob/main/SECURITY.md) voor meer details.

### Kleine Issues

Als je een klein probleem, bug of typfout vindt, voel je dan vrij om je gang te gaan en een pull request aan te maken om het op te lossen. Als het een open issue op een van de repos oplost, dan kun je het linken in de pull request in de zijbalk zodat de issue automatisch gesloten wordt wanneer de pull request samengevoegd wordt.

![GitHub Link Issue](../images/github-link-issue.png)

### Nieuwe Functies

Als je grotere veranderingen wilt voorstellen zoals nieuwe functies of bug fixes die significante hoeveelheden code veranderen, open dan eerst een issue of post in het `#development` kanaal in Discord. Dit stelt ons in staat om de wijziging met je te bespreken als er misschien een context is die we moeten toepassen of we kunnen je tips geven. We willen niet dat je tijd verspilt als een functie niet in onze plannen past!

### Vapor's Project Borden

Als je gewoon wilt bijdragen maar geen idee hebt waar je aan moet werken, is dat geweldig! Vapor heeft een aantal forums die kunnen helpen. Vapor heeft ongeveer 40 repositories die actief ontwikkeld worden en ze allemaal doorzoeken om iets te vinden om aan te werken is niet praktisch, dus gebruiken we boards om deze samen te voegen.

Het eerste board is het [good first issue board](https://github.com/orgs/vapor/projects/14). Elk issue in Vapor's GitHub org dat getagged is met `good first issue` zal aan dit board worden toegevoegd zodat u het kunt vinden. Dit zijn problemen waarvan we denken dat ze goed zijn voor mensen die relatief nieuw zijn met Vapor om aan te werken, omdat ze niet veel ervaring met de code vereisen.

Het tweede bord is het [help gezocht bord](https://github.com/orgs/vapor/projects/13). Dit haalt problemen binnen met het label `help wanted`. Dit zijn problemen die goed zouden kunnen zijn om op te lossen, maar het core team heeft op dit moment andere prioriteiten. Deze problemen vereisen meestal een beetje meer kennis als ze niet ook gemarkeerd zijn met `good first issue`, maar het kunnen leuke projecten zijn om aan te werken!

### Vertalingen

Het laatste gebied waar bijdragen zeer waardevol zijn is de documentatie. De docs hebben vertalingen voor meerdere talen, maar niet elke pagina is vertaald en er zijn veel meer talen die we zouden willen ondersteunen! Als je geïnteresseerd bent in het bijdragen van nieuwe talen of updates, zie de [docs README](https://github.com/vapor/docs#translating) of neem contact op in het `#documentation` kanaal op Discord.

## Bijdragend Proces

Als je nog nooit aan een open source project hebt gewerkt, kunnen de stappen om daadwerkelijk bij te dragen verwarrend zijn, maar ze zijn vrij eenvoudig.

Ten eerste, fork Vapor of welke repo je ook in wilt werken. Je kunt dit doen in de GitHub UI en GitHub heeft [een aantal uitstekende docs](https://docs.github.com/en/get-started/quickstart/fork-a-repo) over hoe je dit moet doen.

U kunt dan wijzigingen aanbrengen in uw fork met het gebruikelijke commit en push proces. Zodra je klaar bent om je correctie in te dienen, kun je een PR maken op Vapor's repo. Nogmaals, GitHub heeft [uitstekende docs](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork) over hoe dit te doen.

## Een Pull Request indienen

Bij het indienen van een pull aanvraag zijn er een aantal dingen die je moet controleren:

* Alle testen zijn geslaagd.
* Nieuwe tests toegevoegd voor nieuw gedrag of opgeloste bugs
* Nieuwe publieke API's zijn gedocumenteerd. Wij gebruiken DocC voor onze API documentatie.

Vapor gebruikt automatisering om de hoeveelheid werk die nodig is voor veel taken te verminderen. Voor pull requests gebruiken we de [Vapor Bot](https://github.com/VaporBot) om releases te genereren wanneer een pull request is samengevoegd. De inhoud en titel van de pull request worden gebruikt om de release notes te genereren, dus zorg ervoor dat ze zinvol zijn en beschrijven wat je verwacht te zien in release notes. We hebben meer details in [Vapor's richtlijnen voor bijdragen](https://github.com/vapor/vapor/blob/main/.github/contributing.md#release-title).
