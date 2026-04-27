# Fly

Fly è una piattaforma di hosting che consente di eseguire applicazioni server e database con un focus sull'edge computing. Consulta [il loro sito](https://fly.io/) per maggiori informazioni.

!!! note "Nota"
    I comandi specificati in questo documento sono soggetti ai [prezzi di Fly](https://fly.io/docs/about/pricing/), assicurati di comprenderli bene prima di continuare.

## Registrazione
Se non hai un account, dovrai [crearne uno](https://fly.io/app/sign-up).

## Installare flyctl
Il modo principale per interagire con Fly è tramite lo strumento CLI dedicato, `flyctl`, che dovrai installare.

### macOS
```bash
brew install flyctl
```

### Linux
```bash
curl -L https://fly.io/install.sh | sh
```

### Altre opzioni di installazione
Per ulteriori opzioni e dettagli, consulta [la documentazione di installazione di `flyctl`](https://fly.io/docs/flyctl/install/).

## Accesso
Per accedere dal tuo terminale, esegui il seguente comando:
```bash
fly auth login
```

## Configurare il tuo progetto Vapor
Prima di fare il deploy su Fly, devi assicurarti di avere un progetto Vapor con un Dockerfile adeguatamente configurato, poiché è richiesto da Fly per compilare la tua app. Nella maggior parte dei casi, questo dovrebbe essere molto semplice poiché i template Vapor predefiniti ne contengono già uno.

### Nuovo progetto Vapor
Il modo più semplice per creare un nuovo progetto è partire da un template. Puoi crearne uno usando i template GitHub o il Vapor toolbox. Se hai bisogno di un database, è consigliato usare Fluent con Postgres; Fly semplifica la creazione di un database Postgres a cui collegare le tue app (consulta la [sezione dedicata](#configurare-postgres) qui sotto).

#### Usando il Vapor toolbox
Prima di tutto, assicurati di aver installato il Vapor toolbox (consulta le istruzioni per [macOS](../install/macos.it.md#install-toolbox) o [Linux](../install/linux.it.md#install-toolbox)).
Crea la tua nuova app con il seguente comando, sostituendo `app-name` con il nome che desideri:
```bash
vapor new app-name
```

Questo comando mostrerà un prompt interattivo che ti permetterà di configurare il tuo progetto Vapor, è qui che puoi selezionare Fluent e Postgres se ne hai bisogno.

#### Usando i template GitHub
Scegli il template più adatto alle tue esigenze dalla seguente lista. Puoi clonarlo localmente usando Git oppure creare un progetto GitHub con il pulsante "Use this template".

- [Template base](https://github.com/vapor/template-bare)
- [Template Fluent/Postgres](https://github.com/vapor/template-fluent-postgres)
- [Template Fluent/Postgres + Leaf](https://github.com/vapor/template-fluent-postgres-leaf)

### Progetto Vapor esistente
Se hai un progetto Vapor esistente, assicurati di avere un `Dockerfile` correttamente configurato nella radice della tua directory; la [documentazione Vapor sull'uso di Docker](../deploy/docker.it.md) e la [documentazione Fly sul deploy di un'app tramite Dockerfile](https://fly.io/docs/languages-and-frameworks/dockerfile/) potrebbero tornare utili.

## Avviare la tua app su Fly
Una volta che il tuo progetto Vapor è pronto, puoi avviarlo su Fly.

Prima di tutto, assicurati che la tua directory corrente sia impostata sulla directory radice della tua applicazione Vapor ed esegui il seguente comando:
```bash
fly launch
```

Questo avvierà un prompt interattivo per configurare le impostazioni della tua applicazione Fly:

- **Nome:** puoi digitarne uno oppure lasciarlo vuoto per ottenere un nome generato automaticamente.
- **Regione:** quella predefinita è la più vicina a te. Puoi scegliere di usarla o qualsiasi altra nell'elenco. È facile cambiarla in seguito.
- **Database:** puoi chiedere a Fly di creare un database da usare con la tua app. Se preferisci, puoi sempre farlo in seguito con i comandi `fly pg create` e `fly pg attach` (consulta la [sezione Configurare Postgres](#configurare-postgres) per maggiori dettagli).

Il comando `fly launch` crea automaticamente un file `fly.toml`. Contiene impostazioni come le mappature delle porte private/pubbliche, i parametri degli health check e molte altre. Se hai appena creato un nuovo progetto da zero usando `vapor new`, il file `fly.toml` predefinito non richiede modifiche. Se hai un progetto esistente, è probabile che `fly.toml` vada bene anche senza o con modifiche minori. Puoi trovare maggiori informazioni nella [documentazione di `fly.toml`](https://fly.io/docs/reference/configuration/).

Nota che se chiedi a Fly di creare un database, dovrai attendere un po' che venga creato e superi gli health check.

Prima di uscire, il comando `fly launch` ti chiederà se desideri fare il deploy della tua app immediatamente. Puoi accettare oppure farlo in seguito usando `fly deploy`.

!!! tip "Suggerimento"
    Quando la tua directory corrente è nella radice della tua app, lo strumento CLI fly rileva automaticamente la presenza di un file `fly.toml` che consente a Fly di sapere quale app stai prendendo di mira con i tuoi comandi. Se vuoi puntare a un'app specifica indipendentemente dalla tua directory corrente, puoi aggiungere `-a nome-della-tua-app` alla maggior parte dei comandi Fly.

## Deploy
Esegui il comando `fly deploy` ogni volta che hai bisogno di fare il deploy di nuove modifiche su Fly.

Fly legge i file `Dockerfile` e `fly.toml` della tua directory per determinare come compilare ed eseguire il tuo progetto Vapor.

Una volta compilato il container, Fly avvia un'istanza dello stesso. Eseguirà vari health check, assicurandosi che la tua applicazione sia in esecuzione correttamente e che il tuo server risponda alle richieste. Il comando `fly deploy` termina con un errore se gli health check falliscono.

Per impostazione predefinita, Fly effettuerà il rollback all'ultima versione funzionante della tua app se gli health check falliscono per la nuova versione che hai tentato di distribuire.

Quando si fa il deploy di un worker in background (con Vapor Queues), non modificare CMD o ENTRYPOINT nel tuo Dockerfile; lascialo invariato in modo che l'applicazione web principale si avvii normalmente. Invece, aggiungi una sezione [processes] nel tuo file fly.toml in questo modo:

```
[processes]
  app = ""
  worker = "queues"
```

Questo dice a Fly.io di eseguire il processo app con l'entrypoint Docker predefinito (il tuo web server), e il processo worker per eseguire la coda dei job usando l'interfaccia a riga di comando di Vapor (cioè, swift run App queues).

## Configurare Postgres

### Creare un database Postgres su Fly
Se non hai creato un database app al primo avvio della tua app, puoi farlo in seguito usando:
```bash
fly pg create
```

Questo comando crea un'app Fly in grado di ospitare database disponibili per le tue altre app su Fly, consulta la [documentazione Fly dedicata](https://fly.io/docs/postgres/) per maggiori dettagli.

Una volta creata la tua app database, vai nella directory radice della tua app Vapor ed esegui:
```bash
fly pg attach nome-della-tua-app-postgres
```
Se non conosci il nome della tua app Postgres, puoi trovarlo con `fly pg list`.

Il comando `fly pg attach` crea un database e un utente destinati alla tua app, e li espone alla tua app tramite la variabile d'ambiente `DATABASE_URL`.

!!! note "Nota"
    La differenza tra `fly pg create` e `fly pg attach` è che il primo alloca e configura un'app Fly in grado di ospitare database Postgres, mentre il secondo crea un database e un utente effettivi destinati all'app di tua scelta. Se soddisfa i tuoi requisiti, una singola app Fly Postgres potrebbe ospitare più database usati da varie app. Quando chiedi a Fly di creare un'app database in `fly launch`, esegue l'equivalente di chiamare sia `fly pg create` che `fly pg attach`.

### Collegare la tua app Vapor al database
Una volta che la tua app è collegata al database, Fly imposta la variabile d'ambiente `DATABASE_URL` all'URL di connessione che contiene le tue credenziali (deve essere trattata come informazione sensibile).

Con la maggior parte delle configurazioni comuni dei progetti Vapor, configuri il tuo database in `configure.swift`. Ecco come potresti farlo:

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    try app.databases.use(.postgres(url: databaseURL), as: .psql)
} else {
    // Gestisci qui il caso di DATABASE_URL mancante...
    //
    // In alternativa, potresti anche impostare una configurazione diversa
    // a seconda che app.environment sia impostato su
    // `.development` o `.production`
}
```

A questo punto, il tuo progetto dovrebbe essere pronto per eseguire le migrazioni e usare il database.

### Eseguire le migrazioni
Con `release_command` di `fly.toml`, puoi chiedere a Fly di eseguire un determinato comando prima di avviare il processo server principale. Aggiungi questo a `fly.toml`:
```toml
[deploy]
 release_command = "migrate -y"
```

!!! note "Nota"
    Il frammento di codice sopra presuppone che tu stia usando il Dockerfile Vapor predefinito che imposta l'`ENTRYPOINT` della tua app su `./App`. In concreto, ciò significa che quando imposti `release_command` su `migrate -y`, Fly chiamerà `./App migrate -y`. Se il tuo `ENTRYPOINT` è impostato su un valore diverso, dovrai adattare il valore di `release_command`.

Fly eseguirà il tuo release command in un'istanza temporanea che ha accesso alla tua rete interna Fly, ai segreti e alle variabili d'ambiente.

Se il tuo release command fallisce, il deploy non continuerà.

### Altri database
Sebbene Fly semplifichi la creazione di un'app database Postgres, è possibile ospitare anche altri tipi di database (ad esempio, consulta ["Use a MySQL database"](https://fly.io/docs/app-guides/mysql-on-fly/) nella documentazione Fly).

## Segreti e variabili d'ambiente
### Segreti
Usa i segreti per impostare eventuali valori sensibili come variabili d'ambiente.
```bash
 fly secrets set MYSECRET=A_SUPER_SECRET_VALUE
```

!!! warning "Attenzione"
    Tieni presente che la maggior parte delle shell mantiene uno storico dei comandi digitati. Fai attenzione a questo quando imposti i segreti in questo modo. Alcune shell possono essere configurate per non ricordare i comandi preceduti da uno spazio. Consulta anche il [comando `fly secrets import`](https://fly.io/docs/flyctl/secrets-import/).

Per ulteriori informazioni, consulta la [documentazione di `fly secrets`](https://fly.io/docs/apps/secrets/).

### Variabili d'ambiente
Puoi impostare altre [variabili d'ambiente non sensibili in `fly.toml`](https://fly.io/docs/reference/configuration/#the-env-variables-section), ad esempio:
```toml
[env]
  MAX_API_RETRY_COUNT = "3"
  SMS_LOG_LEVEL = "error"
```

## Connessione SSH
Puoi connetterti alle istanze di un'app usando:
```bash
fly ssh console -s
```

## Controllare i log
Puoi controllare i log live della tua app usando:
```bash
fly logs
```

## Prossimi passi
Ora che la tua app Vapor è distribuita, c'è molto altro che puoi fare, come scalare le tue app verticalmente e orizzontalmente in più regioni, aggiungere volumi persistenti, configurare il deployment continuo, o persino creare cluster di app distribuiti. Il posto migliore per imparare a fare tutto questo e molto altro è la [documentazione di Fly](https://fly.io/docs/).
