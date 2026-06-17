# Environnement, configuration et variables

L'API environnement de Vapor vous aide à configurer votre application dynamiquement. Par défaut, votre application utilise l'environnement `development`. Vous pouvez définir d'autres environnements utiles comme `production` ou `staging` et modifier la façon dont votre application sera configurée dans chacun de ces cas. Vous pouvez aussi charger des variables depuis l'environnement du processus, ou depuis un fichier `.env` (dotenv) en fonction de vos besoins.

Pour accéder à l'environnement actuel, utilisez `app.environment`. Vous pouvez utiliser un switch sur cette propriété dans `configure(_:)` pour exécuter différentes logiques de configuration. 

```swift
switch app.environment {
case .production:
    app.databases.use(....)
default:
    app.databases.use(...)
}
```

## Changer l'environnement

Par défaut, votre application de lance avec l'environnement `development`. Vous pouvez changer cela en passant le drapeau `--env` (`-e`) au démarrage de votre application.

```swift
swift run App serve --env production
```

Vapor définit les environnements suivants :

|nom|nom court|description|
|-|-|-|
|production|prod|Application déployée pour vos utilisateurs.|
|development|dev|Pour du développement local.|
|testing|test|Pour les tests unitaires.|

!!! info
    L'environnement `production` définira le niveau d'émission des logs sur `notice` s'il n'y a pas de contre-indication. Tous les autres environnements utilisent le niveau `info`. 

Vous pouvez choisir entre le drapeau complet et sa version courte `--env` (`-e`).

```swift
swift run App serve -e prod
```

## Traiter des variables

L'objet `Environment` offre une API simple, basée sur une chaîne de caractères, pour accéder aux variables d'environnement du processus.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

En plus de `get`, `Environment` expose une API de recherche dynamique de membre via `process`.

```swift
let foo = Environment.process.FOO
print(foo) // String?
```

Lorsque vous exécutez votre application depuis un terminal, vous pouvez utiliser `export` pour définir des variables d'environnement. 

```sh
export FOO=BAR
swift run App serve
```

Lorsque vous exécutez votre application via Xcode, vous pouvez définir des variables d'environnement en éditant le scheme `App`.

## .env (dotenv)

Les fichiers dotenv contiennent une liste de paires clé-valeur qui sont automatiquement chargées dans l'environnement. Ces fichiers facilitent la configuration de variables d'environnement sans nécéssiter de les définir manuellement.

Vapor cherchera les fichiers dotenv dans le dossier de travail courant. Si vous utilisez Xcode, assurez-vous d'avoir configuré ce dossier en éditant le scheme `App`.

Imaginons que le fichier `.env` suivant soit situé à la racine de notre projet :

```sh
FOO=BAR
```

Lorsque l'application démarre, vous pourrez accéder au contenu de ce fichier comme toute autre variable d'environnement du processus.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

!!! info
    Les variables définies dans le fichier `.env` ne remplaceront pas les variables déjà présentes dans l'environnement du processus. 

En plus du fichier `.env`, Vapor essaiera de charger un fichier dotenv spécifique à l'environnement actuel. Par exemple, en environnement `development`, Vapor chargera aussi `.env.development`. Toute valeur de ce fichier spécifique sera prioritaire sur celle du fichier `.env` général.

Les projets incluent généralement un fichier `.env` comme modèle avec des valeurs par défaut. Les fichiers d'environnement spécifiques sont ignorés avec la ligne suivante dans `.gitignore` :

```gitignore
.env.*
```

Lorsque le projet est cloné sur un nouvel ordinateur, le fichier `.env` modèle peut être copié et les bonnes valeurs peuvent être insérées dans les copies. 

```sh
cp .env .env.development
vim .env.development
```

!!! Avertissement
    Les fichiers dotenv contenant des informations sensibles telles que des mots de passe ne devraient pas être versionnés.

Si vous rencontrez des difficultés pour charger les fichiers .env, essayez d'activer les logs de débug avec `--log debug` pour obtenir plus d'informations. 

## Environnements personnalisés

Pour définir un nom d'environnement personnalisé, vous devrez étendre l'objet `Environment`.

```swift
extension Environment {
    static var staging: Environment {
        .custom(name: "staging")
    }
}
```

L'environnement de l'application est généralement configuré dans `entrypoint.swift` par `Environment.detect()`.

```swift
@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = Application(env)
        defer { app.shutdown() }
        
        try await configure(app)
        try await app.runFromAsyncMainEntrypoint()
    }
}
```

La méthode `detect` les arguments de la ligne de commande du processus et analyse le drapeau `--env` automatiquement. Vous pouvez modifier ce comportement en initialisant une struct `Environment` personnalisée.

```swift
let env = Environment(name: "testing", arguments: ["vapor"])
```

Le tableau passé à arguments doit contenir au moins un argument représentant le nom de l'exécutable. D'autres arguments peuvent être fournis ensuite pour simuler les arguments passés en ligne de commande. C'est particulièrement pratique pour faire des tests.
