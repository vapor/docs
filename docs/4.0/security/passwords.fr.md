# Mots de passe

Vapor contient une API de hachage de mots de passe pour vous aider à stoquer et vérifier les mots de passe de façon sécurisée. Cette API peut se configurer par environnement et permet du hachage asynchrone.

## Configuration

Pour configurer le hacheur de mots de passe de l'application, utilisez `app.passwords`.

```swift
import Vapor

app.passwords.use(...)
```

### Bcrypt

Pour utiliser l'[API Bcrypt](crypto.md#bcrypt) de Vapor pour le hachage, indiquez la valeur `.bcrypt`. C'est la valeur par défaut.

```swift
app.passwords.use(.bcrypt)
```

Bcrypt utilisera une valeur de 12 pour le coût à moins que vous ne précisiez une autre valeur. Vous pouvez la configurer avec le paramètre `cost`.

```swift
app.passwords.use(.bcrypt(cost: 8))
```

### Plaintext

Vapor contient un hacheur de mots de passe non sécurisé qui stoque les valeurs en clair. Ce hacheur ne doit pas être utilisé en production, mais il peut être utile dans le cadre des tests.

```swift
switch app.environment {
case .testing:
    app.passwords.use(.plaintext)
default: break
}
```

## Hachage

Pour hacher des mots de passe, utilisez la propriété `password` présente sur l'objet `Request`.

```swift
let digest = try req.password.hash("vapor")
```

Les empreintes (digest) obtenues par hachage de mots de passe peuvent être comparées au mot de passe reçu en clair grâce à la méthode `verify`.

```swift
let bool = try req.password.verify("vapor", created: digest)
```

La même API est présente sur l'objet `Application` pour un usage au démarrage.

```swift
let digest = try app.password.hash("vapor")
```

### Asynchrone

Les algorithmes de hachage de mots de passe sont conçus pour être lents et consommer beaucoup de ressource processeur. De ce fait, vous voudrez probablement éviter de bloquer l'event-loop lorsque vous hachez des mots de passe. Vapor fournit une API de hachage asynchrone qui délègue l'opération à un processus de fond. Pour utiliser l'API asynchrone, utilisez la propriété `async` présente sur les objets de type hacheur.

```swift
req.password.async.hash("vapor").map { digest in
    // Gérer l'empreinte obtenue.
}

// ou

let digest = try await req.password.async.hash("vapor")
```

La vérification des empreintes se fait de manière similaire :

```swift
req.password.async.verify("vapor", created: digest).map { bool in
    // Gérer le résultat.
}

// ou

let result = try await req.password.async.verify("vapor", created: digest)
```

Calculer des empreintes de hachage en tâche de fond peut libérer les event-loops de votre application, lui permettant de traiter plus de requêtes entrantes.

