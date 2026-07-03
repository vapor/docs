# Journalisation, logs 

L'API de journalisation de Vapor est construite sur [SwiftLog](https://github.com/apple/swift-log). Cela rend Vapor compatible avec toute les [implémentations backend](https://github.com/apple/swift-log#backends) de SwiftLog.

## Logger

Les instances de `Logger` sont utilisées pour émettre des messages dans les journaux de logs. Vapor expose quelques méthodes faciles pour obtenir un logger.

### Request

Chaque objet `Request` possède son propre logger, que vous devriez utiliser pour logger toute information relative à la requête actuelle.

```swift
app.get("hello") { req -> String in
    req.logger.info("Hello, logs!")
    return "Hello, world!"
}
```

Le logger associé à la requête comporte un UUID permettant d'identifier la requête entrante et rendre le suivi des logs plus pratique.

```
[ INFO ] Hello, logs! [request-id: C637065A-8CB0-4502-91DC-9B8615C5D315] (App/routes.swift:10)
```

!!! info
    Les méta-données du logger ne seront affichées qu'à un niveau de log `debug` ou inférieur.

### Application

Pour logger des messages lors du démarrage ou de la configuration de votre application, utilisez le logger de l'objet `Application`.

```swift
app.logger.info("Setting up migrations...")
app.migrations.use(...)
```

### Logger personnalisé

Pour les cas où vous n'avez accès ni à l'objet `Application` ni à l'objet `Request`, vous pouvez instancier un nouveau `Logger`. 

```swift
let logger = Logger(label: "dev.logger.my")
logger.info(...)
```

Bien que les loggers personnalisés émettront aussi vos messages vers votre backend de journalisation configuré, ils n'auront aucune méta-donnée importante liée, comme l'UUID de la requête. Utilisez autant que possible les loggers fournis avec la requête ou l'application. 

## Niveau de log

SwiftLog supporte différents niveaux de log.

|nom|description|
|-|-|
|trace|Pour des messages contenant des informations utiles uniquement lors du suivi de l'exécution d'un programme.|
|debug|Pour des messages contenant des informations utiles lors du débogage d'un programme.|
|info|Pour des messages d'information.|
|notice|Pour des conditions qui ne sont pas vraiment des erreurs, mais peuvent nécessiter une intervention.|
|warning|Pour des conditions qui ne sont pas encore des erreurs, mais requièrent une attention un peu plus importante que le niveau notice.|
|error|Pour des conditions d'erreur.|
|critical|Pour des conditions d'erreur critique qui nécessitent généralement une intervention immédiate.|

Lorqu'un message est émis avec le niveau `critical`, le backend de journalisation peut exécuter des opérations plus lourdes pour capturer l'état du système (comme les stack traces) afin de faciliter l'analyse et le débogage.

Par défaut, Vapor utilise le niveau `info`. Lorsque vous lancez l'application en environnement `production`, le niveau `notice` sera utilisé pour améliorer les performances (seuls les messages ayant un niveau supérieur ou égal à `notice` seront alors émis). 

### Modifier le niveau de log

Peu importe en quel mode d'environnement vous lancez votre application, vous pouvez modifier le niveau de log à utiliser pour augmenter ou réduire la quantité de logs produits. 

La première méthode consiste à passer le drapeau `--log` optionnel au démarrage de votre application.

```sh
swift run App serve --log debug
```

La deuxième méthode consiste à définir la variable d'environnement `LOG_LEVEL`.

```sh
export LOG_LEVEL=debug
swift run App serve
```

Ces deux méthodes sont compatibles avec Xcode, en éditant le scheme `App`.

## Configuration

SwiftLog se configure en amorçant l'objet `LoggingSystem` une fois par processus. Vapor configure généralement cela dans `entrypoint.swift`.

```swift
var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
```

`bootstrap(from:)` est une méthode fournie par Vapor qui va configurer le gestionnaire de logs par défaut en fonction des arguments passés en ligne de commande et des variables d'environnement. Le gestionnaire de logs par défaut enverra les messages au terminal et supporte la colorisation ANSI. 

### Gestionnaire personnalisé

Vous pouvez remplacer le gestionnaire de logs configuré par défaut en enregistrant le votre.

```swift
import Logging

LoggingSystem.bootstrap { label in
    StreamLogHandler.standardOutput(label: label)
}
```

Tous les backends supportés par SwiftLog fonctionneront avec Vapor. Cependant, la modification du niveau de log via argument en ligne de commande ou variable d'environnement ne fonctionne qu'avec le logger par défaut de Vapor.
