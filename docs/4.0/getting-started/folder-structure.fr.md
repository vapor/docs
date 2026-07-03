# Structure des dossiers

Maintenant que vous avez créé, compilé, et exécuté votre première application Vapor, prenons un moment pour vous familiariser avec la structure des dossiers de Vapor. Cette structure est basée sur celle de [Swift Package Manager](spm.md), donc si vous avez travaillé avec SPM auparavant, cela devrait vous être familier. 

```
.
├── Public
├── Sources
│   ├── App
│   │   ├── Controllers
│   │   ├── Migrations
│   │   ├── Models
│   │   ├── configure.swift 
│   │   ├── entrypoint.swift
│   │   └── routes.swift
│       
├── Tests
│   └── AppTests
└── Package.swift
```

Les sections ci-dessous expliquent chaque partie de la structure des dossiers plus en détails.

## Public

Ce dossier contient les fichiers publics qui seront servis par votre application si `FileMiddleware` est activé. Ce sont généralement des images, feuilles de style, et fichiers JavaScript. Par exemple, une requête sur `localhost:8080/favicon.ico` vérifiera si `Public/favicon.ico` existe et la retournera le cas échéant.

Vous devrez activer `FileMiddleware` dans votre fichier `configure.swift` avant que Vapor ne puisse servir des fichiers publiques, comme ceci :

```swift
// Sert des fichiers depuis le dossier `Public/`
let fileMiddleware = FileMiddleware(
    publicDirectory: app.directory.publicDirectory
)
app.middleware.use(fileMiddleware)
```

## Sources

Ce dossier contient tous les fichiers source Swift de votre projet. 
Le dossier racine, `App`, représente le module de votre package, 
tel que déclaré dans le manifeste de [Swift Package Manager](spm.md).

### App

C'est ici que vous développerez toute la logique de votre application. 

#### Controllers

Les Contrôleurs sont un bon moyen de regrouper la logique de votre application. La plupart des contrôleurs ont différentes fonctions qui acceptent une requête et retournent une forme de réponse.

#### Migrations

Le dossier Migrations contiendra vos migrations de base de données si vous utilisez Fluent.

#### Models

Le dossier Models est le bon endroit pour ranger vos structs `Content` ou vos `Model`s pour Fluent.

#### configure.swift

Ce fichier contient la fonction `configure(_:)`. Cette méthode est appelée par `entrypoint.swift` pour configurer l'`Application` nouvellement instanciée. Ces ici que vous devriez enregistrer des services comme les routes, bases de données, fournisseurs, et autres. 

#### entrypoint.swift

Ce fichier contient le point d'entrée `@main` pour l'application, qui prépare, configure et exécute votre application Vapor.

#### routes.swift

Ce fichier contient la fonction `routes(_:)`. Cette méthode est appelée vers la fin de `configure(_:)` pour enregistrer les routes de votre `Application`. 

## Tests

Chaque module non-exécutable de votre dossier `Sources` peut avoir un dossier correspondant dans `Tests`. Cela contient du code basé sur le module `XCTest` pour tester votre package. Les tests peuvent être exécutés avec la commande `swift test` dans un terminal, ou en pressant ⌘+U dans Xcode. 

### AppTests

Ce dossier contient les tests unitaires pour le code de votre module `App`.

## Package.swift

Il reste enfin le manifeste de [Swift Package Manager](spm.md).

