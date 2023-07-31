# Installazione su Linux

Per usare Vapor, avrete bisogno di Swift 5.2 o superiore. Potete installarlo usando le toolchains disponibili su [Swift.org](https://swift.org/download/)

## Distribuzioni e Versioni supportate

Vapor supporta le stesse versioni delle distribuzioni Linux che supportano Swift 5.2 o versioni più recenti.

!!! note
    Le versioni supportate elencate di seguito potrebbero essere obsolete in qualsiasi momento. Potete controllare quali sistemi operativi sono ufficialmente supportati sulla pagina [Swift Releases](https://swift.org/download/#releases).

|Distribuzione|Versione|Versione di Swift|
|-|-|-|
|Ubuntu|16.04, 18.04|>= 5.2|
|Ubuntu|20.04|>= 5.2.4|
|Fedora|>= 30|>= 5.2|
|CentOS|8|>= 5.2.4|
|Amazon Linux|2|>= 5.2.4|

Le distribuzioni Linux non ufficialmente supportate possono comunque eseguire Swift compilando il codice sorgente, ma Vapor non può garantirne la stabilità. Potete saperne di più sulla compilazione di Swift dal [repo di Swift](https://github.com/apple/swift#getting-started).

## Installare Swift

Visitate la guida [Using Downloads](https://swift.org/download/#using-downloads) di Swift.org per le istruzioni su come installare Swift su Linux.

### Fedora

Gli utenti Fedora possono semplicemente usare il seguente comando per installare Swift:

```sh
sudo dnf install swift-lang
```

Se state usando Fedora 30, dovrete aggiungere EPEL 8 per ottenere Swift 5.2 o versioni più recenti.

## Docker

Potete anche usare le immagini Docker ufficiali di Swift che includono il compilatore preinstallato. Potete saperne di più sul [Docker Hub di Swift](https://hub.docker.com/_/swift).

## Installare la Toolbox

Ora che avete installato Swift, potete installare la [Toolbox di Vapor](https://github.com/vapor/toolbox). Questo strumento CLI non è necessario per usare Vapor, ma include degli strumenti utili.

Su Linux, dovrete compilare la toolbox dal codice sorgente. Guardate le <a href="https://github.com/vapor/toolbox/releases" target="_blank"> release </a> della toolbox su GitHub per trovare l'ultima versione.

```sh
git clone https://github.com/vapor/toolbox.git
cd toolbox
git checkout <desired version>
make install
```

Controllate che l'installazione sia andata a buon fine stampando l'aiuto.

```sh
vapor --help
```

Dovreste vedere una lista di comandi disponibili.

## Come continuare

Dopo aver installato Vapor, potete iniziare a creare il vostro primo progetto usando [Inizio &rarr; Ciao, mondo](../getting-started/hello-world.it.md).
