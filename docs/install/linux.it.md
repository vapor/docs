# Installazione su Linux

Per usare Vapor, avrai bisogno di Swift 5.9 o superiore. Puoi installarlo usando lo strumento con interfaccia a riga di comanddo [Swiftly](https://swiftlang.github.io/swiftly/) fornito dal Swift Server Workgroup (raccomandato), oppure usando le toolchain disponibili su [Swift.org](https://swift.org/download/)

## Distribuzioni e Versioni supportate

Vapor supporta le stesse versioni delle distribuzioni Linux che supportano Swift 5.9 o versioni più recenti. Fai riferimento alla [pagina ufficiale di supporto](https://www.swift.org/platform-support/) per trovare informazioni aggiornate su quali sistemi operativi sono supportati ufficialmente.

Le distribuzioni Linux non ufficialmente supportate possono comunque eseguire Swift compilando il codice sorgente, ma Vapor non può garantirne la stabilità. Puoi saperne di più sulla compilazione di Swift dal [repo di Swift](https://github.com/apple/swift#getting-started).

## Installare Swift

### Installazione automatizzata usando lo strumento CLI Swiftly (raccomandato)

Visita il [sito di Swiflty](https://swiftlang.github.io/swiftly/) per istruzioni su come installare Swiftly e Swift su Linux. Dopo di che, installa Swift con il seguente comando:

#### Utilizzo di base

```sh
$ swiftly install latest

Fetching the latest stable Swift release...
Installing Swift 5.9.1
Downloaded 488.5 MiB of 488.5 MiB
Extracting toolchain...
Swift 5.9.1 installed successfully!

$ swift --version

Swift version 5.9.1 (swift-5.9.1-RELEASE)
Target: x86_64-unknown-linux-gnu
```

### Installazione manuale con la toolchain

Visita la guida [Using Downloads](https://swift.org/download/#using-downloads) di Swift.org per le istruzioni su come installare Swift su Linux.

### Fedora

Gli utenti Fedora possono semplicemente usare il seguente comando per installare Swift:

```sh
sudo dnf install swift-lang
```

Se stai usando Fedora 35, dovrai aggiungere EPEL 8 per ottenere Swift 5.9 o versioni più recenti.

## Docker

Puoi anche usare le immagini Docker ufficiali di Swift che includono il compilatore preinstallato. Puoi saperne di più sul [Docker Hub di Swift](https://hub.docker.com/_/swift).

## Installare la Toolbox

Ora che hai installato Swift, puoi installare la [Vapor Toolbox](https://github.com/vapor/toolbox). Questo strumento da linea di comando non è necessario per usare Vapor, ma aiuta nella creazione dei progetti Vapor.

### Homebrew

La Toolbox è distribuita tramite Homebrew. Se non hai ancora Homebrew, visita <a href="https://brew.sh" target="_blank">brew.sh</a> per le istruzioni di installazione.

```sh
brew install vapor
```

Controlla che l'installazione sia andata a buon fine stampando l'aiuto.

```sh
vapor --help
```

Dovresti vedere una lista di comandi disponibili.

### Makefile

Se vuoi, puoi compilare la Toolbox dal codice sorgente. Guarda le <a href="https://github.com/vapor/toolbox/releases" target="_blank"> release </a> della Toolbox su GitHub per trovare l'ultima versione.

```sh
git clone https://github.com/vapor/toolbox.git
cd toolbox
git checkout <desired version>
make install
```

Controlla che l'installazione sia andata a buon fine stampando l'aiuto.

```sh
vapor --help
```

Dovresti vedere una lista di comandi disponibili.

## Come continuare

Dopo aver installato Swift e la Vapor Toolbox, puoi iniziare a creare il tuo primo progetto usando [Inizio &rarr; Ciao, mondo](../getting-started/hello-world.it.md).
