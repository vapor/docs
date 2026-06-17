# Swift Package Manager

Le [Swift Package Manager](https://swift.org/package-manager/) (SPM) est utilisé pour compiler le code source et les dépendances de votre projet. Puisque Vapor s'appuie grandement sur SPM, c'est une bonne idée de comprendre les bases de son fonctionnement.

SPM est semblable à Cocoapods, Ruby gems, et NPM. Vous pouvez utiliser SPM depuis les lignes de commandes avec des commandes telles que `swift build` et `swift test` ou via des IDE compatibles. Cependant, contrairement à d'autres gestionnaires de dépendances, il n'existe pas d'index central de recensement des packets pour SPM. Au lieu de ça, SPM tire parti des URLs de dépots Git et gère les dépendances de versions en utilisant les [tags Git](https://git-scm.com/book/en/v2/Git-Basics-Tagging). 

## Manifeste du package

Le premier endroit qui intéresse SPM dans votre projet est le manifeste SPM. Il devrait toujours se situer dans le dossier racine de votre projet et être nommé `Package.swift`.

Regardez cet exemple de fichier manifeste.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
```

Chaque partie du manifeste est détaillée dans les sections suivantes.

### Tools Version

La toute première ligne du manifeste indique la version requise de Swift tools. Cela spécifie la version minimale de Swift que le package supporte. L'API de description Package() pourrait aussi évoluer avec les versions de Swift, donc cette ligne assure que Swift saura comment interpréter votre manifeste. 

### Package Name

Le premier argument passé à `Package()` est le nom de celui-ci. Si le package est publique, vous devriez utiliser le dernier segment de l'URL du dépot Git pour ce nom.

### Platforms

Le tableau `platforms` spécifie quelles plateformes sont supportées par ce package. En spécifiant `.macOS(.v12)` ce package nécessite macOS 12 ou plus récent. Lorsque Xcode charge ce projet, il définira automatiquement la version minimum de déploiement à macOS 12 pour que vous puissiez utiliser toutes les API disponibles.

### Dependencies

Les dépendances sont d'autres packages SPM sur lesquels le votre s'appuie. Toutes les applications Vapor s'appuient sur le package Vapor, mais vous pouvez ajouter autant de dépendances que vous le souhaitez.

Dans l'exemple ci-dessus, vous pouvez voir que [vapor/vapor](https://github.com/vapor/vapor) version 4.76.0 ou plus récent est une dépendance de ce package. Lorsque vous ajoutez une dépendance à votre package, vous devez ensuite indiquer quelles [Targets](#targets) dépendent des modules nouvellement rendus disponibles.

### Targets

Les Targets sont tous les modules, exécutables, et tests que contient votre package. La plupart des applications Vapor auront deux Targets, bien que vous puissiez en ajouter autant que vous le souhaitez pour organiser votre code. Chaque Target déclare les modules dont elle dépend. Vous devez ajouter les noms de modules ici afin de pouvoir les importer dans votre code. Une Target peut dépendre d'autres Targets de votre projet ou de tout module exposé par les packages que vous avez ajoutés au tableau des [dépendances principales](#dependencies).

## Structure des dossiers

Ci-dessous est une représentation typique de la structure de fichiers d'un package SPM.

```
.
├── Sources
│   └── App
│       └── (code source)
├── Tests
│   └── AppTests
└── Package.swift
```

Chaque `.target` ou `.executableTarget` correspond à un dossier contenu dans le dossier `Sources`. 
Chaque `.testTarget` correspond à un dossier contenu dans le dossier `Tests`.

## Package.resolved

La première fois que vous compilez votre projet, SPM créera un fichier `Package.resolved` qui stoquera les versions de chaque dépendance utilisée. Lors des compilations suivantes, ces mêmes versions seront réutilisées même si des plus récentes sont disponibles depuis. 

Pour mettre à jour vos dépendances, lancez la commande `swift package update`.

## Xcode

Si vous utilisez Xcode 11 ou ultérieur, les changements de dépendances, de Targets, de Products, etc se produiront automatiquement dès lors que le fichier `Package.swift` sera modifié. 

Si vous souhaitez mettre à jour vos dépendances vers les versions les plus récentes, utilisez File → Swift Packages → Update To Latest Swift Package Versions.

Vous voudrez peut-être aussi ajouter le fichier `.swiftpm` à votre fichier `.gitignore`. C'est dans ce fichier que Xcode stoquera la configuration de votre projet Xcode.
