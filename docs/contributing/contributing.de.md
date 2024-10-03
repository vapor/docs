# An Vapor mitwirken

Vapor ist ein Projekt, das durch die Mitwirkung von Freiwilligen geprägt ist. Die Beiträge von Menschen wie dir machen daher einen erheblichen Anteil an der Entwicklung von Vapor aus. Dieser Leitfaden soll dir helfen den Beitragsprozess besser zu verstehen und dich bei deinem ersten Beitrag unterstützen.

Jeder Beitrag ist nützlich! Selbst kleine Dinge wie die Korrektur von Rechtschreibfehlern können einen großen Unterschied machen. Zum Beispiel dann, wenn sich jemand für oder gegen Vapor entscheiden muss. 

## Code of Conduct

Vapor hat den Code of Conduct von Swift übernommen, der unter [https://www.swift.org/code-of-conduct/](https://www.swift.org/code-of-conduct/) zu finden ist. Es wird von jedem Mitwirkenden erwartet, dass dieser Verhaltenskodex befolgt wird.

## Arten von Beiträgen

Der Start in die Open-Source-Welt ist nicht immer einfach. Besonders dann nicht, wenn du zwar mitwirken willst, aber nicht weißt woran und in welcher Form. Grundsätzlich macht ein Beitrag immer dann Sinn, wenn du ein Problem gefunden hast oder ein neues Feature entwickeln möchtest. Wir machen allerdings auch Vorschläge, woran du arbeiten bzw. beitragen kannst.

### Sicherheitslücken

Bitte **erstelle kein** Issue oder Pull Request, falls du eine Sicherheitslücke gefunden hast und diese melden bzw. bei der Behebung helfen möchtest. Wir haben ein spezielles Ablaufschema für Sicherheitslücken um sicherzustellen, dass keine Schwachstellen veröffentlicht werden, solange diese nicht behoben sind. Bitte sende daher eine E-Mail an security@vapor.codes oder hole dir [hier](https://github.com/vapor/.github/blob/main/SECURITY.md) weitere Informationen zu diesem Thema.

### Probleme und Fehler

Falls du ein Problem oder Fehler/Rechtschreibfehler gefunden hast, kannst du diesen gerne beheben und einen Pull Request erstellen. Sollte dein Pull Request ein offenes Issue adressieren, dann verlinke dieses bitte in der Seitenleiste deines Pull Requests. Dadurch wird das offene Issue automatisch geschlossen, sobald dein Pull Request akzeptiert und gemerged wurde.

![GitHub Issue verlinken](../images/github-link-issue.png)

### Neue Features

Bevor du an größeren Änderungen (z.B. neue Features oder Fehlerbehebungen, die erhebliche Code-Veränderungen notwendig machen) arbeitest, solltest du ein Issue oder einen Beitrag im `#development`-Channel auf Discord erstellen. Dadurch können wir die geplanten Änderungen zunächst mit dir besprechen. Das ist insbesondere dann wichtig, wenn größere Zusammenhänge berücksichtigt werden müssen. Außerdem können wir dir dadurch Tipps bzw. Richtungsweiser geben. Es ist uns sehr wichtig, dass du keine Zeit in etwas investierst, das später nicht übernommen wird, weil es nicht in unsere Zukunftspläne passt.

### Boards von Vapor

Es ist kein Problem, wenn du an Vapor mitwirken möchtest, aber nicht weißt woran und in welcher Form. Genau für diesen Fall gibt es die unterschiedlichen Boards von Vapor, die dir dabei helfen, die richtige Aufgabe zu finden. Vapor besitzt etwa 40 Repositories, die aktiv weiterentwickelt werden. Alle Repositories nach anstehenden Aufgaben zu durchsuchen ist weder sinnvoll noch effizient. Aus diesem Grund nutzen wir die angesprochenen Boards, um alle anstehenden Aufgaben übersichtlich zu sammeln.

Das erste Board ist das [good first issue board](https://github.com/orgs/vapor/projects/14). Jedes Issue innerhalb der GitHub-Organisation von Vapor, das mit `good first issue` getaggt ist, wird automatisch zu diesem Board hinzugefügt. Issues in diesem Board benötigen nicht viel Erfahrung mit Vapor und können deswegen auch von relativ neuen Mitwirkenden bearbeitet werden.

Das zweite Board ist das [help wanted board](https://github.com/orgs/vapor/projects/13). Dieses Board bündelt alle Issues innerhalb der GitHub-Organisation von Vapor, die mit `help wanted` getaggt sind. Issues in diesem Board können beliebig bearbeitet werden, weil das Core-Team dafür aktuell keine Ressourcen zur Verfügung hat. Solche Issues benötigen in der Regel ein bisschen mehr Erfahrung mit Vapor, solange sie nicht ebenfalls mit `good first issue` getaggt sind. Natürlich können solche Issues auch zum spielerischen lernen von Vapor genutzt werden.

### Übersetzungen

Der letzte Bereich, in dem Beiträge von Mitwirkenden essenziell sind, ist die Dokumentation. Vapors Dokumentation enthält Übersetzungen für diverse Sprachen, allerdings ist nicht jede Seite vollständig übersetzt. Außerdem möchten wir unsere Dokumentation noch in viele weitere Sprachen übersetzen. Wenn du daran interessiert bist, weitere Sprachen oder fehlende Übersetzungen bereitzustellen, dann findest du [hier](https://github.com/vapor/docs#translating) weitere Informationen. Alternativ kannst du natürlich auch gerne den `#documentation`-Channel auf Discord nutzen.

## Beitragsprozess

Wenn du noch nie an einem Open-Source-Projekt gearbeitet hast, können die Schritte zum mitwirken etwas verwirrend sein. Aber keine Sorge, die Schritte sind wirklich einfach!

Als erstes musst du Vapor bzw. das zu ändernde Repository forken. Das kannst du über die Benutzeroberfläche von GitHub erledigen, die entsprechende Dokumentation findest du [hier](https://docs.github.com/en/get-started/quickstart/fork-a-repo).

Anschließend kannst du die Änderungen wie gewohnt mit commits und pushs in deinem Fork vornehmen. Sobald du mit deinen Änderungen fertig bist, kannst du einen Pull Request in dem Repository erstellen, von dem du deinen Fork erstellt hast. GitHub hat für diesen typischen Open-Source-Vorgang eine [wunderbare Dokumentation](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork) erstellt. 

## Einen Pull Request einreichen

Du solltest beim Einreichen deines Pull Requests einige Dinge prüfen:

* Alle Tests wurden erfolgreich ausgeführt
* Für jede neue Funktion und Fehlerbehebung wurden neue Tests hinzugefügt
* Neue öffentliche APIs wurden dokumentiert. Wir nutzen DocC für unsere API-Dokumentation.

Vapor nutzt Automatisierungen, um die Arbeitslast für viele Aufgaben zu reduzieren. Bei Pull Requests nutzen wir den [Vapor Bot](https://github.com/VaporBot), der nach dem mergen automatisch ein Release erzeugt. Der Titel und die Beschreibung deines Pull Requests wird für die Beschreibung des Releases verwendet. Bitte stelle daher sicher, dass diese Informationen Sinn ergeben und als Beschreibung für ein Release verwendet werden können. Mehr Informationen dazu gibt es [hier](https://github.com/vapor/vapor/blob/main/.github/contributing.md#release-title).
