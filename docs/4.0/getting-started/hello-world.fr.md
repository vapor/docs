# Hello, world

Ce guide vous accompagnera pas à pas dans la création d'un nouveau projet Vapor, de sa conception jusqu'au lancement du serveur.

Si vous n'avez pas encore installé Swift ou la Toolbox Vapor, veuillez suivre les instructions d'installation.

- [Installation → macOS](../install/macos.md)
- [Installation → Linux](../install/linux.md)

!!! Note
    Le modèle utilisé par la Toolbox Vapor nécessite Swift 6.0 ou supérieur.

## Nouveau projet

La première étape consiste à créer un nouveau projet Vapor sur votre ordinateur. Ouvrez un terminal et utilisez la commande `new` de la Toolbox. Cela créera un nouveau dossier dans le répertoire courant qui contiendra le projet (ici, `hello` sera le nom du projet).

```sh
vapor new hello -n
```

!!! Note
    Le drapeau `-n` vous donnera un modèle brut en répondant automatiquement non à toutes les questions de la commande.

!!! Note
    Vous pouvez aussi récupérer le dernier modèle depuis GitHub sans passer par la Toolbox Vapor en clonant le [dépot du modèle](https://github.com/vapor/template-bare)

!!! Note
    Vapor et son dernier modèle utilisent désormais `async`/`await` par défaut.
    Si vous ne pouvez pas mettre à jour vers macOS 12 et/ou avez besoin de continuer à utiliser les `EventLoopFuture`s, 
    utilisez le drapeau `--branch macos10-15`.

Une fois la commande terminée, placez-vous dans le dossier nouvellement créé :

```sh
cd hello
```

## Compiler et exécuter

### Xcode

Tout d'abord, ouvrez le projet dans Xcode:

```sh
open Package.swift
```

Il commencera automatiquement à télécharger les dépendances de Swift Package Manager. Cela peut prendre un certain temps lors de la première ouverture de votre projet. Lorsque la résolution des dépendances est faite, Xcode remplira les différents plans de compilation disponibles.

Tout en haut de la fenêtre, à droite des boutons Start et Stop, cliquez sur le nom de votre projet pour sélectionner son plan de compilation, et choisissez une cible de lancement appropriée — le plus probablement, "Mon Mac". Cliquez sur le bouton Start pour lancer la compilation et l'exécution de votre projet.

Vous devriez vous la Console s'afficher en bas de la fenêtre Xcode.

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

### Linux

Sur Linux et les autres Systèmes d'Exploitation, (et même sous macOS si vous ne souhaitez pas utiliser Xcode) vous pouvez éditer le projet dans votre éditeur de choix, tel que Vim ou VSCode. Voir [Swift Server Guides](https://github.com/swift-server/guides/blob/main/docs/setup-and-ide-alternatives.md) pour des instructions à jour sur la configuration d'autres IDEs.

!!! Note
    Si vous choisissez d'utiliser VSCode, nous vous recommandons d'installer l'extension officielle Vapor : [Vapor for VS Code](https://marketplace.visualstudio.com/items?itemName=Vapor.vapor-vscode).

Pour compiler et exécuter votre projet, tapez dans votre terminal :

```sh
swift run
```

Lors de la première exécution de cette commande, cela prendra un certain temps pour récupérer et résoudre les dépendances. Une fois que le projet s'exécute, vous devriez voir ceci dans votre console :

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

## Voir le site

Ouvrez votre navigateur web, et rendez-vous sur <a href="http://localhost:8080/hello" target="_blank">localhost:8080/hello</a> ou <a href="http://127.0.0.1:8080" target="_blank">http://127.0.0.1:8080</a>

Vous devriez voir la page suivante.

```html
Hello, world!
```

Félicitations, vous venez de créer, compiler, et exécuter votre première application Vapor ! 🎉
