# Docker Deploys

Die Verwendung von Docker zum Deployen deiner Vapor-App bietet mehrere Vorteile: 

1. Deine dockerisierte App kann zuverlässig mit denselben Befehlen auf jeder Plattform mit einem Docker Daemon gestartet werden -- nämlich Linux (CentOS, Debian, Fedora, Ubuntu), macOS und Windows.
2. Du kannst docker-compose oder Kubernetes-Manifeste verwenden, um mehrere Dienste zu orchestrieren, die für ein vollständiges Deployment benötigt werden (z. B. Redis, Postgres, nginx usw.).
3. Es ist einfach, die Fähigkeit deiner App zu testen, horizontal zu skalieren, sogar lokal auf deiner Entwicklungsmaschine.

Diese Anleitung wird nicht erklären, wie du deine dockerisierte App auf einen Server bringst. Das einfachste Deployment würde darin bestehen, Docker auf deinem Server zu installieren und dieselben Befehle auszuführen, die du auf deiner Entwicklungsmaschine ausführen würdest, um deine Anwendung zu starten. 

Umfangreichere und robustere Deployments unterscheiden sich meist je nach deiner Hosting-Lösung; viele beliebte Lösungen wie AWS bieten integrierte Unterstützung für Kubernetes und individuelle Datenbanklösungen, wodurch es schwierig ist, Best Practices so zu formulieren, dass sie auf alle Deployments zutreffen. 

Dennoch ist es sowohl für große als auch für kleine serverseitige Apps äußerst wertvoll, mit Docker deinen gesamten Server-Stack lokal zu Testzwecken zu starten. Außerdem lassen sich die in dieser Anleitung beschriebenen Konzepte im Großen und Ganzen auf alle Docker-Deployments anwenden.

## Einrichtung

Du musst deine Entwicklungsumgebung so einrichten, dass Docker ausgeführt werden kann, und ein grundlegendes Verständnis der Ressourcendateien erlangen, die Docker-Stacks konfigurieren.

### Docker installieren

Du musst Docker für deine Entwicklungsumgebung installieren. Informationen für jede Plattform findest du im Abschnitt [Supported Platforms](https://docs.docker.com/install/#supported-platforms) der Docker Engine Overview. Falls du Mac OS verwendest, kannst du direkt zur Installationsseite [Docker for Mac](https://docs.docker.com/docker-for-mac/install/) springen.

### Vorlage generieren

Wir empfehlen, die Vapor-Vorlage als Ausgangspunkt zu verwenden. Falls du bereits eine App hast, baue die Vorlage wie unten beschrieben in einem neuen Ordner als Referenzpunkt auf, während du deine bestehende App dockerisierst -- du kannst wichtige Ressourcen aus der Vorlage in deine App kopieren und sie leicht anpassen, um damit zu starten.

1. Installiere oder baue die Vapor Toolbox ([macOS](../install/macos.md#install-toolbox), [Linux](../install/linux.md#install-toolbox)).
2. Erstelle eine neue Vapor-App mit `vapor new my-dockerized-app` und gehe die Eingabeaufforderungen durch, um relevante Funktionen zu aktivieren oder zu deaktivieren. Deine Antworten auf diese Eingabeaufforderungen wirken sich darauf aus, wie die Docker-Ressourcendateien generiert werden.

## Docker-Ressourcen

Es lohnt sich, ob jetzt oder in naher Zukunft, dich mit der [Docker Overview](https://docs.docker.com/engine/docker-overview/) vertraut zu machen. Die Übersicht erklärt einige wichtige Begriffe, die in dieser Anleitung verwendet werden. 

Die Vapor-App-Vorlage besitzt zwei wichtige Docker-spezifische Ressourcen: Eine **Dockerfile** und eine **docker-compose**-Datei.

### Dockerfile

Eine Dockerfile teilt Docker mit, wie ein Image deiner dockerisierten App gebaut werden soll. Dieses Image enthält sowohl die ausführbare Datei deiner App als auch alle Abhängigkeiten, die zu ihrer Ausführung benötigt werden. Es lohnt sich, die [vollständige Referenz](https://docs.docker.com/engine/reference/builder/) offen zu halten, während du an der Anpassung deiner Dockerfile arbeitest.

Die für deine Vapor-App generierte Dockerfile besteht aus zwei Stufen. Die erste Stufe baut deine App und richtet einen Zwischenspeicherbereich ein, der das Ergebnis enthält. Die zweite Stufe richtet die Grundlagen einer sicheren Laufzeitumgebung ein, überträgt alles aus dem Zwischenspeicherbereich an den Ort, an dem es im finalen Image liegen wird, und legt einen Standard-Entrypoint und -Befehl fest, der deine App im Produktionsmodus auf dem Standardport (8080) ausführt. Diese Konfiguration kann überschrieben werden, wenn das Image verwendet wird.

### Docker-Compose-Datei

Eine Docker-Compose-Datei definiert, wie Docker mehrere Dienste im Verhältnis zueinander bauen soll. Die Docker-Compose-Datei in der Vapor-App-Vorlage bietet die notwendige Funktionalität, um deine App zu deployen, aber wenn du mehr erfahren möchtest, solltest du die [vollständige Referenz](https://docs.docker.com/compose/compose-file/) konsultieren, die Details zu allen verfügbaren Optionen enthält.

!!! note
    Falls du letztlich planst, Kubernetes zur Orchestrierung deiner App zu verwenden, ist die Docker-Compose-Datei nicht direkt relevant. Kubernetes-Manifestdateien sind jedoch konzeptionell ähnlich, und es gibt sogar Projekte, die darauf abzielen, [Docker-Compose-Dateien](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/) in Kubernetes-Manifeste zu übertragen.

Die Docker-Compose-Datei in deiner neuen Vapor-App definiert Dienste zum Ausführen deiner App, zum Ausführen von Migrationen oder deren Rückgängigmachung sowie zum Ausführen einer Datenbank als Persistenzschicht deiner App. Die genauen Definitionen variieren je nachdem, welche Datenbank du beim Ausführen von `vapor new` gewählt hast.

Beachte, dass deine Docker-Compose-Datei am Anfang einige gemeinsam genutzte Umgebungsvariablen besitzt. (Du hast möglicherweise einen anderen Satz an Standardvariablen, je nachdem, ob du Fluent verwendest und, falls ja, welcher Fluent-Treiber verwendet wird.)

```docker
x-shared_environment: &shared_environment
  LOG_LEVEL: ${LOG_LEVEL:-debug}
  DATABASE_HOST: db
  DATABASE_NAME: vapor_database
  DATABASE_USERNAME: vapor_username
  DATABASE_PASSWORD: vapor_password
```

Du wirst sehen, dass diese unten in mehreren Diensten mit der YAML-Referenzsyntax `<<: *shared_environment` eingebunden werden.

Die Variablen `DATABASE_HOST`, `DATABASE_NAME`, `DATABASE_USERNAME` und `DATABASE_PASSWORD` sind in diesem Beispiel fest codiert, während `LOG_LEVEL` seinen Wert aus der Umgebung erhält, in der der Dienst ausgeführt wird, oder auf `'debug'` zurückfällt, falls diese Variable nicht gesetzt ist.

!!! note
    Das Hardcodieren von Benutzername und Passwort ist für die lokale Entwicklung akzeptabel, aber du solltest diese Variablen für das Produktions-Deployment in einer Secrets-Datei speichern. Eine Möglichkeit, dies in der Produktion zu handhaben, besteht darin, die Secrets-Datei in die Umgebung zu exportieren, die dein Deployment ausführt, und Zeilen wie die folgende in deiner Docker-Compose-Datei zu verwenden: 

    ```
    DATABASE_USERNAME: ${DATABASE_USERNAME}
    ```

    Dies gibt die Umgebungsvariable, wie vom Host definiert, an die Container weiter.

Weitere Dinge, die zu beachten sind:

- Dienstabhängigkeiten werden über `depends_on`-Arrays definiert.
- Dienst-Ports werden dem System, das die Dienste ausführt, über `ports`-Arrays offengelegt (formatiert als `<host_port>:<service_port>`).
- `DATABASE_HOST` ist als `db` definiert. Das bedeutet, deine App greift auf die Datenbank unter `http://db:5432` zu. Das funktioniert, weil Docker ein Netzwerk startet, das von deinen Diensten verwendet wird, und der interne DNS in diesem Netzwerk den Namen `db` zum Dienst namens `'db'` weiterleitet.
- Die Direktive `CMD` in der Dockerfile wird bei einigen Diensten durch das `command`-Array überschrieben. Beachte, dass das, was durch `command` festgelegt wird, gegen den `ENTRYPOINT` in der Dockerfile ausgeführt wird.
- Im Swarm Mode (dazu unten mehr) erhalten Dienste standardmäßig 1 Instanz, aber die Dienste `migrate` und `revert` sind mit `deploy` `replicas: 0` definiert, sodass sie beim Ausführen eines Swarms nicht standardmäßig gestartet werden.

## Bauen

Die Docker-Compose-Datei teilt Docker mit, wie deine App gebaut werden soll (indem die Dockerfile im aktuellen Verzeichnis verwendet wird) und wie das resultierende Image benannt werden soll (`my-dockerized-app:latest`). Letzteres ist tatsächlich die Kombination aus einem Namen (`my-dockerized-app`) und einem Tag (`latest`), wobei Tags zur Versionierung von Docker-Images verwendet werden.

Um ein Docker-Image für deine App zu bauen, führe

```shell
docker compose build
```

aus dem Wurzelverzeichnis des Projekts deiner App aus (dem Ordner, der `docker-compose.yml` enthält).

Du wirst sehen, dass deine App und ihre Abhängigkeiten erneut gebaut werden müssen, selbst wenn du sie zuvor auf deiner Entwicklungsmaschine gebaut hattest. Sie werden in der von Docker verwendeten Linux-Build-Umgebung gebaut, weshalb die Build-Artefakte von deiner Entwicklungsmaschine nicht wiederverwendbar sind.

Wenn der Vorgang abgeschlossen ist, findest du das Image deiner App, indem du

```shell
docker image ls
```

ausführst.

## Ausführen

Dein Stack von Diensten kann direkt aus der Docker-Compose-Datei ausgeführt werden, oder du kannst eine Orchestrierungsschicht wie Swarm Mode oder Kubernetes verwenden.

### Eigenständig

Der einfachste Weg, deine App auszuführen, besteht darin, sie als eigenständigen Container zu starten. Docker verwendet die `depends_on`-Arrays, um sicherzustellen, dass auch alle abhängigen Dienste gestartet werden.

Führe zunächst aus:

```shell
docker compose up app
```

und beachte, dass sowohl der Dienst `app` als auch der Dienst `db` gestartet werden.

Deine App lauscht auf Port 8080 und ist, wie durch die Docker-Compose-Datei definiert, auf deiner Entwicklungsmaschine unter **http://localhost:8080** zugänglich gemacht.

Diese Unterscheidung bei der Port-Zuordnung ist sehr wichtig, denn du kannst eine beliebige Anzahl von Diensten auf denselben Ports ausführen, wenn sie alle in ihren eigenen Containern laufen und jeweils unterschiedliche Ports zur Host-Maschine hin offenlegen.

Besuche `http://localhost:8080` und du wirst `It works!` sehen, aber besuchst du `http://localhost:8080/todos`, erhältst du:

```
{"error":true,"reason":"Something went wrong."}
```

Wirf einen Blick auf die Log-Ausgabe im Terminal, in dem du `docker compose up app` ausgeführt hast, und du wirst sehen:

```
[ ERROR ] relation "todos" does not exist
```

Natürlich! Wir müssen Migrationen auf der Datenbank ausführen. Drücke `Ctrl+C`, um deine App herunterzufahren. Wir starten die App nun erneut, dieses Mal aber mit:

```shell
docker compose up --detach app
```

Jetzt startet deine App "detached" (im Hintergrund). Du kannst dies überprüfen, indem du

```shell
docker container ls
```

ausführst, wo du siehst, dass sowohl die Datenbank als auch deine App in Containern laufen. Du kannst die Logs sogar überprüfen, indem du

```shell
docker logs <container_id>
```

ausführst.

Um Migrationen auszuführen, führe

```shell
docker compose run migrate
```

aus.

Nachdem die Migrationen ausgeführt wurden, kannst du `http://localhost:8080/todos` erneut besuchen und erhältst eine leere Liste von Todos anstelle einer Fehlermeldung.

#### Log-Stufen

Erinnere dich daran, dass die Umgebungsvariable `LOG_LEVEL` in der Docker-Compose-Datei, sofern verfügbar, von der Umgebung übernommen wird, in der der Dienst gestartet wird.

Du kannst deine Dienste starten mit

```shell
LOG_LEVEL=trace docker-compose up app
```

um Protokollierung auf der Stufe `trace` zu erhalten (die detaillierteste). Du kannst diese Umgebungsvariable verwenden, um die Protokollierung auf [jede verfügbare Stufe](../basics/logging.md#level) einzustellen.

#### Alle Dienst-Logs

Wenn du beim Starten der Container deinen Datenbankdienst explizit angibst, siehst du sowohl Logs für deine Datenbank als auch für deine App.

```shell
docker-compose up app db
```

#### Eigenständige Container herunterfahren

Nachdem du nun Container hast, die "detached" von deiner Host-Shell laufen, musst du ihnen irgendwie mitteilen, sich herunterzufahren. Es ist gut zu wissen, dass jeder laufende Container mit

```shell
docker container stop <container_id>
```

zum Herunterfahren aufgefordert werden kann, aber der einfachste Weg, diese speziellen Container herunterzufahren, ist

```shell
docker-compose down
```

#### Die Datenbank löschen

Die Docker-Compose-Datei definiert ein `db_data`-Volume, um deine Datenbank zwischen den Ausführungen persistent zu halten. Es gibt ein paar Möglichkeiten, deine Datenbank zurückzusetzen.

Du kannst das `db_data`-Volume gleichzeitig mit dem Herunterfahren deiner Container entfernen mit

```shell
docker-compose down --volumes
```

Du kannst alle Volumes, die derzeit Daten persistent halten, mit `docker volume ls` einsehen. Beachte, dass der Volume-Name im Allgemeinen ein Präfix von `my-dockerized-app_` oder `test_` hat, je nachdem, ob du im Swarm Mode oder nicht ausgeführt hast. 

Du kannst diese Volumes einzeln entfernen mit z. B.

```shell
docker volume rm my-dockerized-app_db_data
```

Du kannst auch alle Volumes bereinigen mit

```shell
docker volume prune
```

Sei nur vorsichtig, dass du nicht versehentlich ein Volume mit Daten bereinigst, die du behalten wolltest!

Docker lässt dich keine Volumes entfernen, die derzeit von laufenden oder gestoppten Containern verwendet werden. Du kannst eine Liste laufender Container mit `docker container ls` abrufen und auch gestoppte Container mit `docker container ls -a` einsehen.

### Swarm Mode

Swarm Mode ist eine einfache Schnittstelle, die du verwenden kannst, wenn du eine Docker-Compose-Datei zur Hand hast und testen möchtest, wie deine App horizontal skaliert. Du kannst alles über Swarm Mode auf den Seiten nachlesen, die bei der [Übersicht](https://docs.docker.com/engine/swarm/) beginnen.

Das Erste, was wir benötigen, ist ein Manager-Node für unseren Swarm. Führe

```shell
docker swarm init
```

aus.

Als Nächstes verwenden wir unsere Docker-Compose-Datei, um einen Stack namens `'test'` zu starten, der unsere Dienste enthält

```shell
docker stack deploy -c docker-compose.yml test
```

Wir können sehen, wie es unseren Diensten geht, mit

```shell
docker service ls
```

Du solltest `1/1` Replicas für deine Dienste `app` und `db` sowie `0/0` Replicas für deine Dienste `migrate` und `revert` sehen.

Wir müssen einen anderen Befehl verwenden, um Migrationen im Swarm Mode auszuführen.

```shell
docker service scale --detach test_migrate=1
```

!!! note
    Wir haben gerade einen kurzlebigen Dienst gebeten, auf 1 Replica zu skalieren. Er wird erfolgreich hochskalieren, ausgeführt und dann beendet. Das wird ihn jedoch mit `0/1` laufenden Replicas zurücklassen. Das ist kein großes Problem, bis wir die Migrationen erneut ausführen wollen, aber wir können ihm nicht sagen, er solle "auf 1 Replica hochskalieren", wenn er dort bereits steht. Eine Eigenart dieses Setups ist, dass wir das nächste Mal, wenn wir innerhalb derselben Swarm-Laufzeit Migrationen ausführen möchten, den Dienst zuerst auf `0` herunterskalieren und dann wieder auf `1` hochskalieren müssen.

Der Lohn für unsere Mühen im Kontext dieser kurzen Anleitung besteht darin, dass wir unsere App nun auf beliebige Weise skalieren können, um zu testen, wie gut sie mit Datenbank-Contention, Abstürzen und mehr umgeht.

Wenn du 5 Instanzen deiner App gleichzeitig ausführen möchtest, führe

```shell
docker service scale test_app=5
```

aus.

Neben dem Beobachten, wie Docker deine App hochskaliert, kannst du sehen, dass tatsächlich 5 Replicas laufen, indem du erneut `docker service ls` überprüfst.

Du kannst die Logs für deine App einsehen (und ihnen folgen) mit

```shell
docker service logs -f test_app
```

#### Swarm-Dienste herunterfahren

Wenn du deine Dienste im Swarm Mode herunterfahren möchtest, tust du dies, indem du den zuvor erstellten Stack entfernst.

```shell
docker stack rm test
```

## Produktions-Deployments

Wie eingangs erwähnt, wird diese Anleitung nicht im Detail darauf eingehen, deine dockerisierte App in die Produktion zu deployen, da das Thema umfangreich ist und stark je nach Hosting-Dienst (AWS, Azure usw.), Tooling (Terraform, Ansible usw.) und Orchestrierung (Docker Swarm, Kubernetes usw.) variiert.

Die Techniken, die du lernst, um deine dockerisierte App lokal auf deiner Entwicklungsmaschine auszuführen, sind jedoch größtenteils auf Produktionsumgebungen übertragbar. Eine Serverinstanz, die zum Ausführen des Docker Daemon eingerichtet ist, akzeptiert alle dieselben Befehle.

Kopiere deine Projektdateien auf deinen Server, verbinde dich per SSH mit dem Server und führe einen `docker-compose`- oder `docker stack deploy`-Befehl aus, um alles remote zum Laufen zu bringen.

Alternativ kannst du deine lokale Umgebungsvariable `DOCKER_HOST` so setzen, dass sie auf deinen Server verweist, und die `docker`-Befehle lokal auf deiner Maschine ausführen. Wichtig zu beachten ist, dass du bei diesem Ansatz keine deiner Projektdateien auf den Server kopieren musst, _aber_ du musst dein Docker-Image irgendwo hosten, von wo aus dein Server es abrufen kann.
