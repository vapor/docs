# Installation sur Linux

Pour utiliser Vapor, vous aurez besoin de Swift 5.9 ou plus. Vous pouvez l'installer avec l'outil CLI [Swiftly](https://swiftlang.github.io/swiftly/) fourni par le Groupe de Travail Swift pour le Server (recommandé), ou utiliser les toolchains disponibles sur [Swift.org](https://swift.org/download/).

## Distributions et Versions supportées

Vapor supporte les mêmes versions de distribution Linux supportées par Swift 5.9 ou supérieur. Veuillez vous référer à la [page de support officielle](https://www.swift.org/platform-support/) pour trouver les informations à jour concernant les systèmes d'exploitation officiellement supportés.

Les distributions Linux non officiellement supportées peuvent aussi faire tourner Swift en compilant le code source, mais Vapor ne peut garantir une quelconque stabilité. Plus d'informations sur comment compiler Swift sur [le dépot Swift](https://github.com/apple/swift#getting-started).

## Installer Swift

### Installation automatisée via l'outil CLI Swiftly (recommandé)

Rendez-vous sur [le site de Swiflty](https://swiftlang.github.io/swiftly/) pour les instructions d'installation de Swiftly ainsi que de Swift sur Linux. Après quoi, installer Swift avec la commande suivante :

#### Usage de base

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

### Installation manuelle avec la toolchain

Se rendre sur le guide de Swift.org [Using Downloads](https://swift.org/download/#using-downloads) pour avoir les instructions d'installation de Swift sur Linux.

### Fedora

Les utilisateurs de Fedora peuvent simplement installer Swift avec cette commande :

```sh
sudo dnf install swift-lang
```

Si vous utilisez Fedora 35, vous devrez ajouter EPEL 8 pour obtenir Swift 5.9 ou une version plus récente. 

## Docker

Vous pouvez également utiliser les images Docker officielles de Swift qui embarquent le compilateur pré-installé. Voir plus d'informations sur le [Docker Hub Swift](https://hub.docker.com/_/swift).

## Installer la Toolbox

Maintenant que Swift est installé, installons la [Toolbox Vapor](https://github.com/vapor/toolbox). Cet outil en lignes de commandes n'est pas nécessaire pour utiliser Vapor, mais il aide à créer de nouveaux projets.

### Homebrew

La Toolbox est distribuée via Homebrew. Si vous n'avez pas encore Homebrew, rendez-vous sur <a href="https://brew.sh" target="_blank">brew.sh</a> pour suivre les instructions d'installation.

```sh
brew install vapor
```

Vérifiez que l'installation a bien été réalisée en affichant l'aide.

```sh
vapor --help
```

Vous devriez voir la liste des commandes disponibles.

### Makefile

Si vous le souhaitez, vous pouvez également compiler la Toolbox à partir des sources. Voir les <a href="https://github.com/vapor/toolbox/releases" target="_blank">livraisons</a> de la Toolbox sur GitHub pour trouver la dernière version.

```sh
git clone https://github.com/vapor/toolbox.git
cd toolbox
git checkout <desired version>
make install
```

Vérifiez que l'installation a bien été réalisée en affichant l'aide.

```sh
vapor --help
```

Vous devriez voir la liste des commandes disponibles.

## Ensuite

Maintenant que Swift et la Toolbox Vapor sont installés, créez votre première application dans le chapitre [Débuter → Hello, world](../getting-started/hello-world.md).
