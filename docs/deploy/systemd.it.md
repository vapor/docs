# Systemd

Systemd è il sistema e gestore di servizi predefinito sulla maggior parte delle distribuzioni Linux. Di solito è installato di default, quindi non è necessaria alcuna installazione aggiuntiva sulle distribuzioni Swift supportate.

## Configurazione

Ogni app Vapor sul tuo server dovrebbe avere il proprio file di servizio. Per un progetto di esempio chiamato `Hello`, il file di configurazione si troverebbe in `/etc/systemd/system/hello.service`. Questo file dovrebbe avere il seguente aspetto:

```sh
[Unit]
Description=Hello
Requires=network.target
After=network.target

[Service]
Type=simple
User=vapor
Group=vapor
Restart=always
RestartSec=3
WorkingDirectory=/home/vapor/hello
ExecStart=/home/vapor/hello/.build/release/App serve --env production
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=vapor-hello

[Install]
WantedBy=multi-user.target
```

Come specificato nel file di configurazione, il progetto `Hello` si trova nella cartella home dell'utente `vapor`. Assicurati che `WorkingDirectory` punti alla directory radice del tuo progetto, dove si trova il file `Package.swift`.

Il flag `--env production` disabiliterà il logging verboso.

### Variabili d'Ambiente

Puoi esportare variabili in due modi tramite systemd. O creando un file di ambiente con tutte le variabili al suo interno:

```sh
EnvironmentFile=/path/to/environment/file1
EnvironmentFile=/path/to/environment/file2
```

Oppure puoi aggiungerle direttamente al file di servizio sotto `[service]`:

```sh
Environment="PORT=8123"
Environment="ANOTHERVALUE=/something/else"
```

Le variabili esportate possono essere usate in Vapor con `Environment.get`

```swift
let port = Environment.get("PORT")
```

## Avvio

Ora puoi caricare, abilitare, avviare, arrestare e riavviare la tua app eseguendo i seguenti comandi come root.

```sh
systemctl daemon-reload
systemctl enable hello
systemctl start hello
systemctl stop hello
systemctl restart hello
```
