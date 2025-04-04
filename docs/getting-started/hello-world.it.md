# Ciao, mondo

Questa guida ti mostrerà, passo dopo passo, come creare, compilare ed eseguire il tuo primo progetto con Vapor.

Se non hai ancora installato Swift o la Toolbox Vapor, segui la guida di installazione prima di continuare.

- [Installazione &rarr; macOS](../install/macos.md)
- [Installazione &rarr; Linux](../install/linux.md)

## Nuovo Progetto

Il primo passo è creare un nuovo progetto Vapor sul tuo computer. Apri il terminale e utilizza il comando `new` della Toolbox. Questo creerà una nuova cartella nella directory corrente contenente il progetto.

```sh
vapor new hello -n
```

!!! tip
    L'opzione `-n` creerà un progetto con il minimo indispensabile, rispondendo automaticamente no a tutte le domande.

!!! tip
    Vapor e il template ora utilizzano `async`/`await` di default.
    Se non puoi aggiornare a macOS 12 e/o hai bisogno di continuare ad utilizzare gli `EventLoopFuture`, 
    utilizza l'opzione `--branch macos10-15`.

Una volta terminato il comando, entra nella cartella appena creata:

```sh
cd hello
```

## Compilazione ed Esecuzione

### Xcode

Per prima cosa, apri il progetto in Xcode:

```sh
open Package.swift
```

Xcode inizierà automaticamente a scaricare le dipendenze di Swift Package Manager. La prima volta che apri un progetto ci vorrà un po' di tempo. Quando la risoluzione delle dipendenze sarà completata, Xcode popolerà gli schemi disponibili.

Nella parte superiore della finestra, alla destra dei pulsanti Play e Stop, clicca sul nome del progetto per selezionare lo schema del progetto e seleziona un target di esecuzione appropriato, spesso "My Mac". Clicca sul pulsante play per compilare ed eseguire il progetto.

Dovresti ora veder apparire la Console nella parte inferiore della finestra di Xcode.

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

### Linux

Su Linux e altri sistemi operativi (e anche su macOS se non volete utilizzare Xcode) puoi modificare il progetto nel tuo editor preferito, come Vim o VSCode. Per maggiori dettagli su come configurare altri IDE, consulta le [Guide di Swift sul Server](https://github.com/swift-server/guides/blob/main/docs/setup-and-ide-alternatives.md)

!!! tip "Suggerimento"
    Se usi VSCode come editor di testo, raccomandiamo di installare l'estensione ufficiale di Vapor: [Vapor for VS Code](https://marketplace.visualstudio.com/items?itemName=Vapor.vapor-vscode).

Per compilare ed eseguire il progetto, nel Terminale esegui:

```sh
swift run
```

Questo comando compilerà ed eseguirà il progetto. La prima volta che lo esegui ci vorrà un po' di tempo per scaricare e indicizzare le dipendenze. Una volta avviato, dovrebbe apparire il seguente codice nel terminale:

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

## Visitare Localhost

Ora che il progetto è in esecuzione, apri il tuo browser e visita <a href="http://localhost:8080/hello" target="_blank">localhost:8080/hello</a> oppure <a href="http://127.0.0.1:8080" target="_blank">http://127.0.0.1:8080</a>. 

Dovrebbe apparire la seguente pagina:

```html
Hello, world!
```

Congratulazioni per aver creato, compilato ed eseguito il tuo primo progetto Vapor! 🎉
