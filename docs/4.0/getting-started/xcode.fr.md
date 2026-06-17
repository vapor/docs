# Xcode

Cette page donne des trucs et astuces pour l'utilisation de Xcode. Si vous utilisez un autre IDE, vous pouvez sauter cette section.

## Custom Working Directory

Par défaut, Xcode exécute vos projets depuis le dossier _DerivedData_. Ce dossier est différent de la racine de votre projet (où se trouve votre fichier _Package.swift_). Cela signifie que Vapor sera incapable de localiser les fichiers et dossiers tels que _.env_ ou _Public_.

Vous pouvez constater ce symptôme lorsque cela se produit : le warning suivant apparaitra dans la console lors de l'exécution de votre application. 

```fish
[ WARNING ] No custom working directory set for this scheme, using /path/to/DerivedData/project-abcdef/Build/
```

Pour corriger cela, vous devez définir un dossier de travail personnalisé dans les réglages Xcode scheme de votre projet. 

Commencez par éditer le scheme associé à votre projet en cliquant sur le sélecteur à côté des boutons start/stop. 

![Zone des schemes de Xcode](../images/xcode-scheme-area.png)

Sélectionnez _Edit Scheme..._ dans la liste déroulante.

![Menu des schemes de Xcode](../images/xcode-scheme-menu.png)

Dans l'éditor de scheme, sélectionnez l'action _App_ et l'onglet _Options_. Cochez _Use custom working directory_ et indiquez le chemin vers le dossier racine de votre projet.

![Options de scheme de Xcode](../images/xcode-scheme-options.png)

Vous pouvez obtenir le chemin complet vers la racine de votre projet en lançant la commande `pwd` depuis un terminal que vous y avez ouvert.

```sh
# Afficher le chemin vers le dossier courrant
pwd
```

Vous devriez obtenir un résultat similaire à celui-ci :

```
/chemin/vers/votre/projet
```
