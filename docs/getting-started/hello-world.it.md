# Ciao, mondo

Questa guida vi mostrerà, passo dopo passo, come creare, compilare ed eseguire il vostro primo progetto Vapor.

Se non avete ancora installato Swift o la Toolbox Vapor, seguite la guida di installazione prima di continuare.

- [Installazione &rarr; macOS](../install/macos.md)
- [Installazione &rarr; Linux](../install/linux.md)

## Nuovo Progetto

Il primo passo è creare un nuovo progetto Vapor sul vostro computer. Aprite il terminale e utilizzate il comando `new` della Toolbox. Questo creerà una nuova cartella nella directory corrente contenente il progetto.

```sh
vapor new hello -n
```

!!! tip
    L'opzione `-n` creerà un progetto con il minimo indispensabile, rispondendo automaticamente no a tutte le domande.

!!! tip
    Vapor e il template ora utilizzano `async`/`await` di default.
    Se non potete aggiornare a macOS 12 e/o avete bisogno di continuare ad utilizzare gli `EventLoopFuture`s, 
    utilizzate l'opzione `--branch macos10-15`.

Una volta terminato il comando, entrate nella cartella appena creata:

```sh
cd hello
```

## Compilazione sed Esecuzione

### Xcode

Per prima cosa, aprite il progetto in Xcode:

```sh
open Package.swift
```

Xcode inizierà automaticamente a scaricare le dipendenze di Swift Package Manager. La prima volta che aprite un progetto ci vorrà un po' di tempo. Quando la risoluzione delle dipendenze sarà completata, Xcode popolerà gli schemi disponibili.

Nella parte superiore della finestra, alla destra dei pulsanti Play e Stop, cliccate sul nome del progetto per selezionare lo schema del progetto e selezionate un target di esecuzione appropriato, spesso "My Mac". Cliccate sul pulsante play per compilare ed eseguire il progetto.

Dovreste ora veder apparire la Console nella parte inferiore della finestra di Xcode.

```sh
[ INFO ] Server starting on http://
```

### Linux

Su Linux e altri sistemi operativi (e anche su macOS se non volete utilizzare Xcode) potete modificare il progetto nel vostro editor preferito, come Vim o VSCode. Per maggiori dettagli su come configurare altri IDE, consultate le [Guide di Swift lato Server](https://github.com/swift-server/guides/blob/main/docs/setup-and-ide-alternatives.md)

Per compilare ed eseguire il progetto, nel Terminale eseguite:

```sh
swift run
```

Questo comando compilerà ed eseguirà il progetto. La prima volta che lo eseguite ci vorrà un po' di tempo per scaricare e indicizzare le dipendenze. Una volta avviato, dovrebbe apparire qualcosa del genere nel terminale:

```sh
[ INFO ] Server starting on http://
```

## Visitare Localhost

Ora che il progetto è in esecuzione, aprite il vostro browser e visitate <a href="http://localhost:8080/hello" target="_blank">localhost:8080/hello</a> oppure <a href="http://127.0.0.1:8080" target="_blank">http://127.0.0.1:8080</a>. 

Dovrebbe apparire la seguente pagina:

```html
Hello, world!
```

Congratulazione per aver creato, compilato ed eseguito il vostro primo progetto Vapor! 🎉
