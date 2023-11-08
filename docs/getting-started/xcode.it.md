# Xcode

Questa pagina contiene alcuni consigli e trucchi per l'utilizzo di Xcode. Puoi saltarla se preferisci usare un ambiente di sviluppo diverso.

## Directory di lavoro personalizzata

Di default Xcode eseguirà il progetto dalla cartella _DerivedData_. Questa cartella non è la stessa della cartella principale del progetto (dove si trova il file _Package.swift_). Questo significa che Vapor non sarà in grado di trovare file e cartelle come _.env_ o _Public_.

Si capisce se questo sta accadendo se si vede il seguente avviso quando si esegue il progetto.

```fish
[ WARNING ] No custom working directory set for this scheme, using /path/to/DerivedData/project-abcdef/Build/
```

Per risolvere questo problema bisogna impostare una directory di lavoro personalizzata nello schema Xcode del progetto.

Per prima cosa, modificare lo schema del progetto cliccando sul selettore dello schema vicino ai pulsanti play e stop.

![Xcode Scheme Area](../images/xcode-scheme-area.png)

Selezionare _Edit Scheme..._ dal menu a tendina.

![Xcode Scheme Menu](../images/xcode-scheme-menu.png)

Nell'editor dello schema, scegliere l'azione _App_ e la scheda _Options_. Selezionare _Use custom working directory_ e inserire il percorso alla cartella principale del progetto.

![Xcode Scheme Options](../images/xcode-scheme-options.png)

Si può ottenere il percorso completo alla cartella principale del progetto eseguendo `pwd` da una finestra del terminale aperta lì.

```fish
# verificare di essere nella cartella del progetto vapor
vapor --version
# ottenere il percorso di questa cartella
pwd
```

Si dovrebbe vedere un output simile al seguente.

```
framework: 4.x.x
toolbox: 18.x.x
/percorso/al/progetto
```
