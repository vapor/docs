# Cos'è Heroku

Heroku è una popolare soluzione di hosting all-in-one, puoi trovare maggiori informazioni su [heroku.com](https://www.heroku.com)

## Registrazione

Avrai bisogno di un account Heroku; se non ne hai uno, registrati qui: [https://signup.heroku.com/](https://signup.heroku.com/)

## Installare la CLI

Assicurati di aver installato lo strumento CLI di heroku.

### HomeBrew

```bash
brew tap heroku/brew && brew install heroku
```

### Altre Opzioni di Installazione

Consulta le opzioni di installazione alternative qui: [https://devcenter.heroku.com/articles/heroku-cli#download-and-install](https://devcenter.heroku.com/articles/heroku-cli#download-and-install).

### Accesso

Una volta installata la CLI, effettua l'accesso con il seguente comando:

```bash
heroku login
```

Verifica che l'email corretta abbia effettuato l'accesso con:

```bash
heroku auth:whoami
```

### Creare un'applicazione

Visita dashboard.heroku.com per accedere al tuo account e crea una nuova applicazione dal menu a tendina in alto a destra. Heroku farà alcune domande come la regione e il nome dell'applicazione, segui semplicemente le istruzioni.

### Git

Heroku usa Git per fare il deploy della tua app, quindi dovrai mettere il tuo progetto in un repository Git, se non lo è già.

#### Inizializzare Git

Se hai bisogno di aggiungere Git al tuo progetto, inserisci il seguente comando nel Terminale:

```bash
git init
```

#### Main

Dovresti scegliere un solo branch e usare quello per fare il deploy su Heroku, come il branch **main** o **master**. Assicurati che tutte le modifiche siano confermate su questo branch prima del push.

Controlla il tuo branch corrente con:

```bash
git branch
```

L'asterisco indica il branch corrente.

```bash
* main
  commander
  other-branches
```

!!! note "Nota"
    Se non vedi alcun output e hai appena eseguito `git init`, dovrai prima fare il commit del tuo codice, poi vedrai l'output del comando `git branch`.

Se _non_ sei attualmente sul branch corretto, passa ad esso inserendo (per **main**):

```bash
git checkout main
```

#### Commit delle modifiche

Se questo comando produce output, allora hai modifiche non committate.

```bash
git status --porcelain
```

Committale con il seguente comando

```bash
git add .
git commit -m "a description of the changes I made"
```

#### Connettere con Heroku

Connetti la tua app con heroku (sostituisci con il nome della tua app).

```bash
$ heroku git:remote -a your-apps-name-here
```

### Impostare il Buildpack

Imposta il buildpack per insegnare a heroku come gestire vapor.

```bash
heroku buildpacks:set vapor/vapor
```

### File della versione Swift

Il buildpack che abbiamo aggiunto cerca un file **.swift-version** per sapere quale versione di Swift usare. (Sostituisci 5.8.1 con qualsiasi versione richiesta dal tuo progetto.)

```bash
echo "5.8.1" > .swift-version
```

Questo crea **.swift-version** con `5.8.1` come contenuto.

### Procfile

Heroku usa il **Procfile** per sapere come eseguire la tua app; nel nostro caso deve avere questo aspetto:

```
web: App serve --env production --hostname 0.0.0.0 --port $PORT
```

Possiamo crearlo con il seguente comando nel terminale

```bash
echo "web: App serve --env production" \
  "--hostname 0.0.0.0 --port \$PORT" > Procfile
```

### Commit delle modifiche

Abbiamo appena aggiunto questi file, ma non sono ancora stati committati. Se facciamo il push, heroku non li troverà.

Committali con il seguente comando.

```bash
git add .
git commit -m "adding heroku build files"
```

### Deploy su Heroku

Sei pronto per fare il deploy, esegui questo comando dal terminale. Potrebbe volerci un po' per la compilazione, è normale.

```bash
git push heroku main
```

### Scalare

Una volta che la compilazione ha avuto successo, devi aggiungere almeno un server. I prezzi partono da $5/mese per il piano Eco (vedi [pricing](https://www.heroku.com/pricing#containers)), assicurati di avere il pagamento configurato su Heroku. Poi per un singolo web worker:

```bash
heroku ps:scale web=1
```

### Deployment Continuato

Ogni volta che vuoi aggiornare, porta semplicemente le ultime modifiche nel branch main e fai il push su heroku, che ridistribuirà l'app.

## Postgres

### Aggiungere il database PostgreSQL

Visita la tua applicazione su dashboard.heroku.com e vai alla sezione **Add-ons**.

Da qui inserisci `postgres` e vedrai un'opzione per `Heroku Postgres`. Selezionala.

Scegli il piano Essential 0 a $5/mese (vedi [pricing](https://www.heroku.com/pricing#data-services)) e effettua il provisioning. Heroku farà il resto.

Una volta terminato, vedrai il database apparire nella scheda **Resources**.

### Configurare il database

Dobbiamo ora dire alla nostra app come accedere al database. Nella directory della nostra app, eseguiamo:

```bash
heroku config
```

Questo produrrà un output simile a questo

```none
=== today-i-learned-vapor Config Vars
DATABASE_URL: postgres://cybntsgadydqzm:2d9dc7f6d964f4750da1518ad71hag2ba729cd4527d4a18c70e024b11cfa8f4b@ec2-54-221-192-231.compute-1.amazonaws.com:5432/dfr89mvoo550b4
```

**DATABASE_URL** qui rappresenta il nostro database postgres. **NON** codificare mai staticamente l'URL da qui, heroku lo cambierà periodicamente e la tua applicazione smettrebbe di funzionare. È anche una cattiva pratica. Invece, leggi la variabile d'ambiente a runtime.

Il componente aggiuntivo Heroku Postgres [richiede](https://devcenter.heroku.com/changelog-items/2035) che tutte le connessioni siano cifrate. I certificati usati dai server Postgres sono interni a Heroku, quindi è necessario configurare una connessione TLS **non verificata**.

Il seguente frammento mostra come ottenere entrambi:

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    var tlsConfig: TLSConfiguration = .makeClientConfiguration()
    tlsConfig.certificateVerification = .none
    let nioSSLContext = try NIOSSLContext(configuration: tlsConfig)

    var postgresConfig = try SQLPostgresConfiguration(url: databaseURL)
    postgresConfig.coreConfiguration.tls = .require(nioSSLContext)

    app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
} else {
    // ...
}
```

Non dimenticare di committare queste modifiche

```bash
git add .
git commit -m "configured heroku database"
```

### Annullare le migrazioni del database

Puoi annullare le migrazioni o eseguire altri comandi su heroku con il comando `run`.

Per annullare le migrazioni del database:

```bash
heroku run App -- migrate --revert --all --yes --env production
```

Per eseguire le migrazioni:

```bash
heroku run App -- migrate --env production
```
