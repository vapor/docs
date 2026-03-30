# Deploy con Docker

Utilizzare Docker per fare il deploy della tua app Vapor offre diversi vantaggi:

1. La tua app dockerizzata può essere avviata in modo affidabile usando gli stessi comandi su qualsiasi piattaforma con un Docker Daemon -- in particolare Linux (CentOS, Debian, Fedora, Ubuntu), macOS e Windows.
2. Puoi usare docker-compose o i manifest Kubernetes per orchestrare più servizi necessari per un deploy completo (es. Redis, Postgres, nginx, ecc.).
3. È facile testare la capacità della tua app di scalare orizzontalmente, anche in locale sulla tua macchina di sviluppo.

Questa guida non spiega come portare la tua app dockerizzata su un server. Il deploy più semplice consisterebbe nell'installare Docker sul tuo server ed eseguire gli stessi comandi che eseguiresti sulla tua macchina di sviluppo per avviare la tua applicazione.

I deploy più complessi e robusti variano di solito in base alla soluzione di hosting; molte soluzioni popolari come AWS hanno supporto integrato per Kubernetes e soluzioni di database personalizzate, il che rende difficile scrivere best practice applicabili a tutti i deploy.

Ciononostante, usare Docker per avviare l'intero stack del server in locale a scopo di test è estremamente prezioso sia per applicazioni server di grandi che di piccole dimensioni. Inoltre, i concetti descritti in questa guida si applicano in linea di massima a tutti i deploy Docker.

## Configurazione

Dovrai configurare il tuo ambiente di sviluppo per eseguire Docker e acquisire una comprensione di base dei file di risorse che configurano gli stack Docker.

### Installare Docker

Dovrai installare Docker per il tuo ambiente di sviluppo. Puoi trovare informazioni per qualsiasi piattaforma nella sezione [Supported Platforms](https://docs.docker.com/install/#supported-platforms) della panoramica di Docker Engine. Se sei su Mac OS, puoi passare direttamente alla pagina di installazione di [Docker for Mac](https://docs.docker.com/docker-for-mac/install/).

### Generare il Template

Ti suggeriamo di usare il template Vapor come punto di partenza. Se hai già un'app, compila il template come descritto di seguito in una nuova cartella come riferimento mentre dockerizzi la tua app esistente -- puoi copiare le risorse chiave dal template alla tua app e modificarle leggermente come punto di partenza.

1. Installa o compila il Vapor Toolbox ([macOS](../install/macos.it.md#install-toolbox), [Linux](../install/linux.it.md#install-toolbox)).
2. Crea una nuova app Vapor con `vapor new my-dockerized-app` e segui le istruzioni interattive per abilitare o disabilitare le funzionalità rilevanti. Le tue risposte a queste istruzioni influenzeranno la generazione dei file di risorse Docker.

## Risorse Docker

Vale la pena, adesso o in futuro, familiarizzare con la [panoramica di Docker](https://docs.docker.com/engine/docker-overview/). La panoramica spiegherà alcune terminologie chiave utilizzate in questa guida.

Il template dell'app Vapor ha due risorse specifiche per Docker: un **Dockerfile** e un file **docker-compose**.

### Dockerfile

Un Dockerfile dice a Docker come costruire un'immagine della tua app dockerizzata. Quell'immagine contiene sia l'eseguibile della tua app che tutte le dipendenze necessarie per eseguirla. Il [riferimento completo](https://docs.docker.com/engine/reference/builder/) vale la pena tenerlo aperto quando lavori alla personalizzazione del tuo Dockerfile.

Il Dockerfile generato per la tua app Vapor ha due fasi. La prima fase compila la tua app e prepara un'area di holding contenente il risultato. La seconda fase configura le basi di un ambiente di runtime sicuro, trasferisce tutto ciò che si trova nell'area di holding dove vivrà nell'immagine finale, e imposta un entrypoint e un comando predefiniti che eseguiranno la tua app in modalità production sulla porta predefinita (8080). Questa configurazione può essere sovrascritta quando l'immagine viene utilizzata.

### File Docker Compose

Un file Docker Compose definisce il modo in cui Docker deve costruire più servizi in relazione tra loro. Il file Docker Compose nel template dell'app Vapor fornisce le funzionalità necessarie per fare il deploy della tua app, ma se vuoi saperne di più dovresti consultare il [riferimento completo](https://docs.docker.com/compose/compose-file/) che contiene dettagli su tutte le opzioni disponibili.

!!! note "Nota"
    Se hai intenzione di usare Kubernetes per orchestrare la tua app, il file Docker Compose non è direttamente rilevante. Tuttavia, i file manifest di Kubernetes sono concettualmente simili e ci sono anche progetti che mirano a [convertire i file Docker Compose](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/) in manifest Kubernetes.

Il file Docker Compose nella tua nuova app Vapor definirà i servizi per eseguire la tua app, eseguire le migrazioni o annullarle, e avviare un database come layer di persistenza della tua app. Le definizioni esatte varieranno a seconda del database che hai scelto quando hai eseguito `vapor new`.

Nota che il tuo file Docker Compose ha alcune variabili d'ambiente condivise nella parte superiore. (Potresti avere un insieme di variabili predefinite diverso a seconda che tu stia usando Fluent o meno, e quale driver Fluent stai usando se lo usi.)

```docker
x-shared_environment: &shared_environment
  LOG_LEVEL: ${LOG_LEVEL:-debug}
  DATABASE_HOST: db
  DATABASE_NAME: vapor_database
  DATABASE_USERNAME: vapor_username
  DATABASE_PASSWORD: vapor_password
```

Vedrai queste variabili incluse in più servizi in basso con la sintassi di riferimento YAML `<<: *shared_environment`.

Le variabili `DATABASE_HOST`, `DATABASE_NAME`, `DATABASE_USERNAME` e `DATABASE_PASSWORD` sono codificate direttamente in questo esempio, mentre `LOG_LEVEL` prenderà il suo valore dall'ambiente in cui viene avviato il servizio, o utilizzerà `'debug'` come fallback se quella variabile non è impostata.

!!! note "Nota"
    Codificare direttamente username e password è accettabile per lo sviluppo locale, ma dovresti memorizzare queste variabili in un file di segreti per il deploy in production. Un modo per gestire questo in production è esportare il file dei segreti nell'ambiente che esegue il tuo deploy e usare righe come le seguenti nel tuo file Docker Compose:

    ```
    DATABASE_USERNAME: ${DATABASE_USERNAME}
    ```

    Questo passa la variabile d'ambiente ai container così com'è definita dall'host.

Altre cose da notare:

- Le dipendenze tra servizi sono definite dagli array `depends_on`.
- Le porte dei servizi sono esposte al sistema che esegue i servizi con gli array `ports` (formattati come `<host_port>:<service_port>`).
- Il `DATABASE_HOST` è definito come `db`. Ciò significa che la tua app accederà al database all'indirizzo `http://db:5432`. Questo funziona perché Docker creerà una rete usata dai tuoi servizi e il DNS interno di quella rete instraderà il nome `db` al servizio denominato `'db'`.
- La direttiva `CMD` nel Dockerfile viene sovrascritta in alcuni servizi con l'array `command`. Nota che ciò che è specificato da `command` viene eseguito contro l'`ENTRYPOINT` nel Dockerfile.
- In Swarm Mode (vedi sotto) i servizi riceveranno di default 1 istanza, ma i servizi `migrate` e `revert` sono definiti con `deploy` `replicas: 0` in modo che non si avviino di default quando si esegue uno Swarm.

## Compilazione

Il file Docker Compose dice a Docker come compilare la tua app (usando il Dockerfile nella directory corrente) e come nominare l'immagine risultante (`my-dockerized-app:latest`). Quest'ultimo è in realtà la combinazione di un nome (`my-dockerized-app`) e un tag (`latest`) dove i tag sono usati per versionare le immagini Docker.

Per compilare un'immagine Docker per la tua app, esegui

```shell
docker compose build
```

dalla directory radice del progetto della tua app (la cartella che contiene `docker-compose.yml`).

Vedrai che la tua app e le sue dipendenze devono essere compilate nuovamente anche se le avevi già compilate sulla tua macchina di sviluppo. Vengono compilate nell'ambiente di build Linux che Docker sta usando, quindi gli artefatti di build della tua macchina di sviluppo non sono riutilizzabili.

Quando è terminato, troverai l'immagine della tua app eseguendo

```shell
docker image ls
```

## Esecuzione

Il tuo stack di servizi può essere eseguito direttamente dal file Docker Compose oppure puoi usare un layer di orchestrazione come Swarm Mode o Kubernetes.

### Standalone

Il modo più semplice per eseguire la tua app è avviarla come container standalone. Docker userà gli array `depends_on` per assicurarsi che vengano avviati anche tutti i servizi dipendenti.

Per prima cosa, esegui:

```shell
docker compose up app
```

e nota che vengono avviati sia i servizi `app` che `db`.

La tua app è in ascolto sulla porta 8080 e, come definito nel file Docker Compose, è resa accessibile sulla tua macchina di sviluppo all'indirizzo **http://localhost:8080**.

Questa distinzione nel port mapping è molto importante perché puoi eseguire un numero qualsiasi di servizi sulle stesse porte se sono tutti in esecuzione nei propri container ed espongono porte diverse alla macchina host.

Visita `http://localhost:8080` e vedrai `It works!`, ma visita `http://localhost:8080/todos` e otterrai:

```
{"error":true,"reason":"Something went wrong."}
```

Dai un'occhiata all'output dei log nel terminale dove hai eseguito `docker compose up app` e vedrai:

```
[ ERROR ] relation "todos" does not exist
```

Ovviamente! Dobbiamo eseguire le migrazioni sul database. Premi `Ctrl+C` per fermare la tua app. Avvieremo di nuovo l'app, questa volta con:

```shell
docker compose up --detach app
```

Ora la tua app si avvierà in modalità "detached" (in background). Puoi verificarlo eseguendo:

```shell
docker container ls
```

dove vedrai sia il database che la tua app in esecuzione nei container. Puoi anche controllare i log eseguendo:

```shell
docker logs <container_id>
```

Per eseguire le migrazioni, esegui:

```shell
docker compose run migrate
```

Dopo l'esecuzione delle migrazioni, puoi visitare di nuovo `http://localhost:8080/todos` e otterrai una lista vuota di todos invece di un messaggio di errore.

#### Livelli di Log

Come accennato sopra, la variabile d'ambiente `LOG_LEVEL` nel file Docker Compose verrà ereditata dall'ambiente in cui viene avviato il servizio, se disponibile.

Puoi avviare i tuoi servizi con

```shell
LOG_LEVEL=trace docker-compose up app
```

per ottenere il logging di livello `trace` (il più granulare). Puoi usare questa variabile d'ambiente per impostare il logging su [qualsiasi livello disponibile](../basics/logging.it.md#levels).

#### Log di Tutti i Servizi

Se specifichi esplicitamente il tuo servizio database quando avvii i container, vedrai i log sia del database che della tua app.

```shell
docker-compose up app db
```

#### Fermare i Container Standalone

Ora che hai i container in esecuzione "detached" dalla tua shell host, devi dir loro di fermarsi in qualche modo. Vale la pena sapere che qualsiasi container in esecuzione può essere fermato con

```shell
docker container stop <container_id>
```

ma il modo più semplice per fermare questi particolari container è

```shell
docker-compose down
```

#### Azzerare il Database

Il file Docker Compose definisce un volume `db_data` per persistere il tuo database tra le esecuzioni. Ci sono un paio di modi per resettare il database.

Puoi rimuovere il volume `db_data` contemporaneamente all'arresto dei tuoi container con

```shell
docker-compose down --volumes
```

Puoi vedere tutti i volumi che persistono i dati con `docker volume ls`. Nota che il nome del volume avrà generalmente il prefisso `my-dockerized-app_` o `test_` a seconda che tu stessi eseguendo in Swarm Mode o meno.

Puoi rimuovere questi volumi uno alla volta con es.

```shell
docker volume rm my-dockerized-app_db_data
```

Puoi anche pulire tutti i volumi con

```shell
docker volume prune
```

Fai attenzione a non eliminare accidentalmente un volume con dati che volevi conservare!

Docker non ti permetterà di rimuovere i volumi attualmente in uso da container in esecuzione o fermi. Puoi ottenere un elenco dei container in esecuzione con `docker container ls` e puoi vedere anche i container fermi con `docker container ls -a`.

### Swarm Mode

Swarm Mode è un'interfaccia semplice da usare quando hai un file Docker Compose a portata di mano e vuoi testare come la tua app scala orizzontalmente. Puoi leggere tutto su Swarm Mode nelle pagine che partono dalla [panoramica](https://docs.docker.com/engine/swarm/).

Per prima cosa abbiamo bisogno di un nodo manager per il nostro Swarm. Esegui

```shell
docker swarm init
```

Successivamente useremo il nostro file Docker Compose per avviare uno stack chiamato `'test'` contenente i nostri servizi

```shell
docker stack deploy -c docker-compose.yml test
```

Possiamo vedere come stanno andando i nostri servizi con

```shell
docker service ls
```

Dovresti aspettarti di vedere `1/1` repliche per i tuoi servizi `app` e `db` e `0/0` repliche per i tuoi servizi `migrate` e `revert`.

Dobbiamo usare un comando diverso per eseguire le migrazioni in Swarm mode.

```shell
docker service scale --detach test_migrate=1
```

!!! note "Nota"
    Abbiamo appena chiesto a un servizio di breve durata di scalare a 1 replica. Scalerà con successo, verrà eseguito e poi terminerà. Tuttavia, questo lo lascerà con `0/1` repliche in esecuzione. Non è un grosso problema finché non vogliamo eseguire di nuovo le migrazioni, ma non possiamo dirgli di "scalare a 1 replica" se è già lì. Una particolarità di questa configurazione è che la prossima volta che vogliamo eseguire le migrazioni all'interno dello stesso runtime Swarm, dobbiamo prima scalare il servizio a `0` e poi di nuovo a `1`.

Il vantaggio di questo approccio nel contesto di questa breve guida è che ora possiamo scalare la nostra app a qualsiasi livello vogliamo per testare quanto bene gestisce la contesa del database, i crash e altro ancora.

Se vuoi eseguire 5 istanze della tua app contemporaneamente, esegui

```shell
docker service scale test_app=5
```

Oltre a guardare Docker scalare la tua app, puoi verificare che 5 repliche siano effettivamente in esecuzione controllando nuovamente `docker service ls`.

Puoi visualizzare (e seguire) i log della tua app con

```shell
docker service logs -f test_app
```

#### Fermare i Servizi Swarm

Quando vuoi fermare i tuoi servizi in Swarm Mode, lo fai rimuovendo lo stack creato in precedenza.

```shell
docker stack rm test
```

## Deploy in Production

Come indicato all'inizio, questa guida non entrerà nei dettagli del deploy della tua app dockerizzata in production perché l'argomento è vasto e varia notevolmente a seconda del servizio di hosting (AWS, Azure, ecc.), degli strumenti (Terraform, Ansible, ecc.) e dell'orchestrazione (Docker Swarm, Kubernetes, ecc.).

Tuttavia, le tecniche che impari per eseguire la tua app dockerizzata in locale sulla tua macchina di sviluppo sono in gran parte trasferibili agli ambienti di production. Un'istanza server configurata per eseguire il daemon Docker accetterà tutti gli stessi comandi.

Copia i file del tuo progetto sul tuo server, accedi via SSH al server ed esegui un comando `docker-compose` o `docker stack deploy` per avviare tutto in remoto.

In alternativa, imposta la variabile d'ambiente locale `DOCKER_HOST` in modo che punti al tuo server ed esegui i comandi `docker` in locale sulla tua macchina. È importante notare che con questo approccio non è necessario copiare nessuno dei file del tuo progetto sul server, _ma_ è necessario ospitare la tua immagine docker da qualche parte da cui il tuo server possa scaricarne una copia.
