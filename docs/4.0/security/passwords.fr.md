# Mots de passe

Vapor inclut une API de hachage de mots de passe pour vous aider à stocker et vérifier des mots de passe en toute sécurité. Cette API est configurable selon l'environnement et prend en charge le hachage asynchrone.

## Configuration

Pour configurer le hacheur de mots de passe de l'application, utilisez `app.passwords`.

```swift
import Vapor

app.passwords.use(...)
```

### Bcrypt

Pour utiliser l'[API Bcrypt](crypto.md#bcrypt) de Vapor pour le hachage des mots de passe, spécifiez `.bcrypt`. C'est la valeur par défaut.

```swift
app.passwords.use(.bcrypt)
```

Bcrypt utilisera un coût de 12 sauf indication contraire. Vous pouvez configurer cela en passant le paramètre `cost`.

```swift
app.passwords.use(.bcrypt(cost: 8))
```

### Texte en clair

Vapor inclut un hacheur de mots de passe non sécurisé qui stocke et vérifie les mots de passe en texte en clair. Il ne doit pas être utilisé en production, mais peut être utile pour les tests.

```swift
switch app.environment {
case .testing:
    app.passwords.use(.plaintext)
default: break
}
```

## Hachage

Pour hacher des mots de passe, utilisez l'assistant `password` disponible sur `Request`.

```swift
let digest = try req.password.hash("vapor")
```

Les condensés de mots de passe peuvent être vérifiés par rapport au mot de passe en clair à l'aide de la méthode `verify`.

```swift
let bool = try req.password.verify("vapor", created: digest)
```

La même API est disponible sur `Application` pour une utilisation pendant le démarrage.

```swift
let digest = try app.password.hash("vapor")
```

### Asynchrone 

Les algorithmes de hachage de mots de passe sont conçus pour être lents et gourmands en CPU. Pour cette raison, vous voudrez peut-être éviter de bloquer la boucle d'événements lors du hachage des mots de passe. Vapor fournit une API de hachage de mots de passe asynchrone qui délègue le hachage à un pool de threads en arrière-plan. Pour utiliser l'API asynchrone, utilisez la propriété `async` d'un hacheur de mots de passe.

```swift
req.password.async.hash("vapor").map { digest in
    // Traiter le condensé.
}

// ou

let digest = try await req.password.async.hash("vapor")
```

La vérification des condensés fonctionne de la même manière :

```swift
req.password.async.verify("vapor", created: digest).map { bool in
    // Traiter le résultat.
}

// ou

let result = try await req.password.async.verify("vapor", created: digest)
```

Le calcul des condensés sur des threads en arrière-plan peut libérer les boucles d'événements de votre application pour traiter davantage de requêtes entrantes.
