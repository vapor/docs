# Supervisor

[Supervisor](http://supervisord.org) è un sistema di controllo dei processi che semplifica l'avvio, l'arresto e il riavvio della tua app Vapor.

## Installazione

Supervisor può essere installato tramite i package manager su Linux.

### Ubuntu

```sh
sudo apt-get update
sudo apt-get install supervisor
```

### CentOS e Amazon Linux

```sh
sudo yum install supervisor
```

### Fedora

```sh
sudo dnf install supervisor
```

## Configurazione

Ogni app Vapor sul tuo server dovrebbe avere il proprio file di configurazione. Per un progetto di esempio chiamato `Hello`, il file di configurazione si troverebbe in `/etc/supervisor/conf.d/hello.conf`

```sh
[program:hello]
command=/home/vapor/hello/.build/release/App serve --env production
directory=/home/vapor/hello/
user=vapor
stdout_logfile=/var/log/supervisor/%(program_name)s-stdout.log
stderr_logfile=/var/log/supervisor/%(program_name)s-stderr.log
```

Come specificato nel file di configurazione, il progetto `Hello` si trova nella cartella home dell'utente `vapor`. Assicurati che `directory` punti alla directory radice del tuo progetto, dove si trova il file `Package.swift`.

Il flag `--env production` disabiliterà il logging verboso.

### Variabili d'Ambiente

Puoi esportare variabili verso la tua app Vapor tramite Supervisor. Per esportare più valori d'ambiente, inseriscili tutti su una sola riga. Come indicato nella [documentazione di Supervisor](http://supervisord.org/configuration.html#program-x-section-values):

> I valori contenenti caratteri non alfanumerici devono essere racchiusi tra virgolette (es. KEY="val:123",KEY2="val,456"). Negli altri casi le virgolette sono opzionali ma consigliate.

```sh
environment=PORT=8123,ANOTHERVALUE="/something/else"
```

Le variabili esportate possono essere usate in Vapor con `Environment.get`

```swift
let port = Environment.get("PORT")
```

## Avvio

Ora puoi caricare e avviare la tua app.

```sh
supervisorctl reread
supervisorctl add hello
supervisorctl start hello
```

!!! note "Nota"
	Il comando `add` potrebbe aver già avviato la tua app.
