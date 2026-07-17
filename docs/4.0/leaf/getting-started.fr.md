# Leaf

Leaf est un puissant langage de templates dont la syntaxe s'inspire de Swift. Vous pouvez l'utiliser pour générer des pages HTML dynamiques pour un site front-end ou générer des e-mails au contenu enrichi.

## Package

La première étape pour utiliser Leaf est de l'ajouter aux dépendances de votre projet dans votre manifeste SPM.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        /// Vos autres dépendances ...
        .package(url: "https://github.com/vapor/leaf.git", from: "4.4.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "Leaf", package: "leaf"),
            // Vos autres dépendances
        ]),
        // Vos autres targets
    ]
)
```

## Configuration

Une fois le package ajouté à votre projet, vous pouvez configurer Vapor pour qu'il l'utilise. Cela se fait généralement dans [`configure.swift`](../getting-started/folder-structure.md#configureswift).

```swift
import Leaf

app.views.use(.leaf)
```

Ceci indique à Vapor d'utiliser `LeafRenderer` lorsque vous appelez `req.view` dans votre code.

!!! Avertissement 
    Pour que Leaf puisse trouver les templates lorsque vous l'exécutez depuis Xcode, vous devez définir le [répertoire de travail personnalisé](../getting-started/xcode.md#custom-working-directory) pour votre espace de travail Xcode.

### Cache de génération des pages

Leaf possède un cache interne pour générer les pages. Lorsque l'environnement de l'`Application` est défini sur `.development`, ce cache est désactivé, afin que les modifications apportées aux templates prennent immédiatement effet. Sur `.production` et tout autre environnement, le cache est activé par défaut. Tout changement apporté aux templates ne prendra pas effet avant le prochain démarrage de l'application.

Pour désactiver le cache de Leaf, faites ceci :

```swift
app.leaf.cache.isEnabled = false
```

!!! Avertissement
    Bien que désactiver le cache soit utile pour du débogage, cela n'est pas recommandé en production à cause de son impact significatif sur les performances causé par la recompilation du template pour chaque requête.

## Structure de dossiers

Une fois que vous avez configuré Leaf, vous devrez créer un dossier `Views` pour y stoquer vos fichiers `.leaf`. Par défaut, Leaf s'attend à trouver ce répertoire sous `./Resources/Views` en partant de la racine de votre projet.

Vous voudrez également activer le [`FileMiddleware`](https://api.vapor.codes/vapor/filemiddleware) de Vapor pour servir les fichiers de votre dossier `/Public` si vous comptez servir des fichiers Javascript ou CSS par exemple.

```
VaporApp
├── Package.swift
├── Resources
│   ├── Views
│   │   └── hello.leaf
├── Public
│   ├── images (ressources images)
│   ├── styles (ressources CSS)
└── Sources
    └── ...
```

## Générer une vue

Maintenant que Leaf est configuré, générons votre premier template. Dans le dossier `Resources/Views`, créez un nouveau fichier `hello.leaf` avec le contenu suivant :

```leaf
Hello, #(name)!
```

!!! Astuce
    Si vous utilisez VSCode, nous recommandons d'installer l'extension Vapor pour activer la colorisation syntaxique : [Vapor for VS Code](https://marketplace.visualstudio.com/items?itemName=Vapor.vapor-vscode).

Ensuite, enregistrez une route (généralement dans `routes.swift` ou un contrôleur) pour générer la vue.

```swift
app.get("hello") { req -> EventLoopFuture<View> in
    return req.view.render("hello", ["name": "Leaf"])
}

// ou

app.get("hello") { req async throws -> View in
    return try await req.view.render("hello", ["name": "Leaf"])
}
```

Cela utilise la propriété générique `view` présente sur `Request` plutôt que d'appeler Leaf directement. De cette façon, vous pourrez configurer un générateur différent dans vos tests.


Ouvrez votre navigateur et rendez-vous sur `/hello`. Vous devriez voir `Hello, Leaf!`. Bravo, vous venez de générer votre première vue avec Leaf !
