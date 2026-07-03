# Code asynchrone et concurrence

## Async Await

Swift 5.5 a introduit la notion de concurrence dans le langage sous la forme `async`/`await`. Cette syntaxe offre une façon qualitative de gérer du code asynchrone en Swift et dans les applications Vapor.

Vapor s'est construit sur [SwiftNIO](https://github.com/apple/swift-nio.git), qui nous offre des types primitifs pour de la programmation asynchrone à bas niveau. Ces types étaient (et sont toujours) utilisés dans le code de Vapor avant l'arrivée de `async`/`await`. Cependant, la plupart du code applicatif peut désormais être écrit avec la syntaxe `async`/`await` au lieu d'utiliser les `EventLoopFuture`s. Cette syntaxe permet de simplifier votre code et le rendre plus intelligible.

La plupart des API de Vapor exposent désormais des versions avec `EventLoopFuture` et `async`/`await` vous permettant de choisir celle qui vous correspond le mieux. De façon générale, vous ne devriez utiliser qu'un seul modèle de développement par gestionnaire de requête, et éviter d'en mélanger plusieurs dans votre code. Pour les applications qui ont des besoins de contrôle explicite sur les EventLoops, ou les applications à très hautes performances, vous devriez continuer à utiliser les `EventLoopFuture`s jusqu'à ce que les exécuteurs personnalisés soient implémentés. Pour tous les autres, vous devriez utiliser `async`/`await` car les avantages de lisibilité et maintenabilité l'emportent largement sur la faible pénalité de performances associée.

### Migrer vers async/await

Quelques étapes sont nécessaires pour migrer vers async/await. Pour commencer, si vous êtes sous macOS, vous aurez besoin de macOS 12 Monterey ou ultérieur, ainsi que Xcode 13.1 ou plus. Pour les autres plateformes, il vous faudra Swift 5.5 ou plus récent. Ensuite, assurez-vous d'avoir mis toutes vos dépendances à jour.

Dans votre fichier Package.swift, définissez swift-tools-version à 5.5 tout en haut du fichier :

```swift
// swift-tools-version:5.5
import PackageDescription

// ...
```

Assignez la version de plateforme à macOS 12 :

```swift
    platforms: [
       .macOS(.v12)
    ],
```

Enfin, ajustez la Target `Run` pour quelle soit une `executableTarget` :

```swift
.executableTarget(name: "Run", dependencies: [.target(name: "App")]),
```

Note: si vous déployez pour Linux, assurez-vous de mettre également Swift à jour sur cet environnement, i.e. sur Heroku ou dans votre Dockerfile. Vous devrez par exemple changer votre Dockerfile de la sorte :

```diff
-FROM swift:5.2-focal as build
+FROM swift:5.5-focal as build
...
-FROM swift:5.2-focal-slim
+FROM swift:5.5-focal-slim
```

Vous pouvez maintenant commencer à migrer votre base de code existante. De manière générale, les fonctions qui retournent des `EventLoopFuture`s sont désormais `async`. Par exemple :

```swift
routes.get("firstUser") { req -> EventLoopFuture<String> in
    User.query(on: req.db).first().unwrap(or: Abort(.notFound)).flatMap { user in
        user.lastAccessed = Date()
        return user.update(on: req.db).map {
            return user.name
        }
    }
}
```

Devient désormais :

```swift
routes.get("firstUser") { req async throws -> String in
    guard let user = try await User.query(on: req.db).first() else {
        throw Abort(.notFound)
    }
    user.lastAccessed = Date()
    try await user.update(on: req.db)
    return user.name
}
```

### Travailler avec les anciennes et nouvelles API

Si vous rencontrez des APIs qui n'offrent pas encore de version `async`/`await`, vous pouvez appeler `.get()` sur une fonction retournant un `EventLoopFuture` pour le convertir.

I.e.

```swift
return someMethodCallThatReturnsAFuture().flatMap { futureResult in
    // utilisation de futureResult
}
```

Peut être changé en :

```swift
let futureResult = try await someMethodThatReturnsAFuture().get()
```

Si vous avez besoin d'une conversion dans l'autre sens, vous pouvez convertir ceci :

```swift
let myString = try await someAsyncFunctionThatGetsAString()
```

en ceci :

```swift
let promise = request.eventLoop.makePromise(of: String.self)
promise.completeWithTask {
    try await someAsyncFunctionThatGetsAString()
}
let futureString: EventLoopFuture<String> = promise.futureResult
```

## Les `EventLoopFuture`s

Vous avez peut-être remarqué que certaines APIs de Vapor attendent ou retournent un type `EventLoopFuture` générique. Si c'est votre premier contact avec les futurs, ils pourront vous sembler déroutants au premier abord. Ne vous inquiétez pas, ce guide vous montrera comment tirer parti de leurs puissantes APIs. 

Les promesses et les futurs sont des types liés, mais distincts. Les promesses sont utilisées pour _créer_ des futurs. La plupart du temps, vous travaillerez avec des futurs retournés par les APIs de Vapor et vous n'aurez pas à vous soucier de créer des promesses.

|type|description|mutabilité|
|-|-|-|
|`EventLoopFuture`|Référence une valeur qui n'est potentiellement pas encore disponible.|lecture seule|
|`EventLoopPromise`|Une promesse qu'une valeur sera éventuellement fournie de façon asynchrone.|lecture/écriture|

Les futurs sont une alternative aux APIs asynchrones basées sur un système de callbacks. Les futurs peuvent être chaînés et transformés en des façons qui ne sont pas disponibles pour des Closures.

## Transformation

Tout comme les optionnels et les tableaux en Swift, les futurs peuvent être mappés et flat-mappés. Voici les opérations les plus courantes que vous utiliserez sur des futurs.

|méthode|argument|description|
|-|-|-|
|[`map`](#map)|`(T) -> U`|Convertit la valeur future en une autre valeur.|
|[`flatMapThrowing`](#flatmapthrowing)|`(T) throws -> U`|Convertit la valeur future en une autre valeur ou lève une erreur.|
|[`flatMap`](#flatmap)|`(T) -> EventLoopFuture<U>`|Convertit la valeur future en une autre valeur _future_.|
|[`transform`](#transform)|`U`|Convertit la valeur future en une autre valeur déjà disponible.|

Si vous regardez les signatures des méthodes `map` et `flatMap` sur `Optional<T>` et `Array<T>`, vous constaterez qu'elles sont très similaires aux méthodes disponibles sur `EventLoopFuture<T>`.

### map

La méthode `map` vous permet de convertir la valeur future en une autre valeur. Puisque la valeur future peut ne pas être disponible immédiatement (elle peut être le résultat d'une tâche asynchrone), il est nécessaire de fournir une Closure qui accepte la valeur une fois résolue.

```swift
/// Supposez que nous récupérions une future chaîne de caractères depuis une API.
let futureString: EventLoopFuture<String> = ...

/// Convertissons la future chaîne vers le type entier.
let futureInt = futureString.map { string in
    print(string) // La chaîne telle qu'elle sera reçue de l'API.
    return Int(string) ?? 0
}

/// Nous obtenons ici un futur entier.
print(futureInt) // EventLoopFuture<Int>
```

### flatMapThrowing

La méthode `flatMapThrowing` vous permet de transformer la valeur future en une autre valeur _ou_ lever une erreur. 

!!! info
    Parce que sous le capot, le fait de lever une erreur crée un nouveau futur, cette méthode est préfixée par `flatMap` malgré le fait que la Closure n'accepte pas de retour futur.

```swift
/// Supposez que nous récupérions une future chaîne de caractères depuis une API.
let futureString: EventLoopFuture<String> = ...

/// Convertissons la future chaîne vers le type entier.
let futureInt = futureString.flatMapThrowing { string in
    print(string) // La chaîne telle qu'elle sera reçue de l'API.
    // Convertit la chaîne en entier ou lève une erreur.
    guard let int = Int(string) else {
        throw Abort(...)
    }
    return int
}

/// Nous obtenons ici un futur entier.
print(futureInt) // EventLoopFuture<Int>
```

### flatMap

La méthode `flatMap` vous permet de transformer la valeur future en une autre valeur future. Le nom "flat" map vient du fait qu'elle permet d'éviter de créer des futurs imbriqués (i.e., `EventLoopFuture<EventLoopFuture<T>>`). En d'autres mots, ça vous aide à garder vos génériques à plat.

```swift
/// Supposez que nous récupérions une future chaîne de caractères depuis une API.
let futureString: EventLoopFuture<String> = ...

/// Supposez que nous avons créé un client HTTP
let client: Client = ... 

/// flatMap de la chaîne future en réponse future.
let futureResponse = futureString.flatMap { string in
    client.get(string) // EventLoopFuture<ClientResponse>
}

/// Nous obtenons ici une réponse future.
print(futureResponse) // EventLoopFuture<ClientResponse>
```

!!! info
    Si nous avions utilisé `map` dans l'exemple ci-dessus, nous aurions obtenu : `EventLoopFuture<EventLoopFuture<ClientResponse>>`.

Pour invoquer une méthode levant une exception à l'intérieur d'un `flatMap`, utilisez les mots clés Swift `do` / `catch` et instanciez un [futur résolu](#makefuture).

```swift
/// Supposez que nous ayons déjà ici les chaîne et client futurs de l'exemple précédent.
let futureResponse = futureString.flatMap { string in
    let url: URL
    do {
        // Une méthode synchrone levant une exception.
        url = try convertToURL(string)
    } catch {
        // Utilisez EventLoop pour instancier un futur pré-accompli.
        return eventLoop.makeFailedFuture(error)
    }
    return client.get(url) // EventLoopFuture<ClientResponse>
}
```
    
### transform

La méthode `transform` vous permet de modifier la valeur d'un futur, ignorant complètement sa valeur existante. C'est particulièrement pratique pour convertir des résultats `EventLoopFuture<Void>` où la valeur réelle du futur n'a aucune importance.

!!! Note
    `EventLoopFuture<Void>`, parfois appelé signal, est un futur dont le seul but est de vous notifier de la complétion ou de l'échec d'une opération asynchrone.

```swift
/// Supposez que nous recevions un futur void d'une API.
let userDidSave: EventLoopFuture<Void> = ...

/// Transforme le futur void en statut HTTP
let futureStatus = userDidSave.transform(to: HTTPStatus.ok)
print(futureStatus) // EventLoopFuture<HTTPStatus>
```   

Bien que nous fournissions une valeur déjà existante à `transform`, il s'agit toujours d'une _transformation_. Le futur ne sera pas accompli tant que tous les futurs précédents ne sont pas accomplis (ou échoués).

### Chaînage

La partie la plus intéressante sur les transformations de futurs, c'est leur possibilité d'être chaînés. Cela vous permet d'exprimer de nombreuses conversions et sous-tâches aisément.

Modifions les exemples précédents pour voir comment nous pouvons en tirer parti.

```swift
/// Supposez que nous recevions une future chaîne d'une API.
let futureString: EventLoopFuture<String> = ...

/// Supposez que nous ayons créé un client HTTP.
let client: Client = ... 

/// Transforme la chaîne en URL, puis en réponse
let futureResponse = futureString.flatMapThrowing { string in
    guard let url = URL(string: string) else {
        throw Abort(.badRequest, reason: "Invalid URL string: \(string)")
    }
    return url
}.flatMap { url in
    client.get(url)
}

print(futureResponse) // EventLoopFuture<ClientResponse>
```

Après l'appel initial à map, un `EventLoopFuture<URL>` temporaire est créé. Ce futur est ensuite immédiatement flat-mappé en `EventLoopFuture<Response>`
    
## Futur

Analysons quelques autres méthodes pour travailler avec `EventLoopFuture<T>`.

### makeFuture

Vous pouvez utiliser un EventLoop pour créer un futur pré-accompli comportant une valeur ou une erreur.

```swift
// Crée un futur pré-accompli.
let futureString: EventLoopFuture<String> = eventLoop.makeSucceededFuture("hello")

// Crée un futur pré-échoué.
let futureString: EventLoopFuture<String> = eventLoop.makeFailedFuture(error)
```

### whenComplete

Vous pouvez utiliser `whenComplete` pour ajouter un callback à exécuter à la résolution du futur, qu'il soit en succès ou en échec.

```swift
/// Supposez que nous recevions une future chaîne d'une API.
let futureString: EventLoopFuture<String> = ...

futureString.whenComplete { result in
    switch result {
    case .success(let string):
        print(string) // La chaîne reçue
    case .failure(let error):
        print(error) // Une erreur Swift
    }
}
```

!!! note
    Vous pouvez ajouter autant de callbacks que vous le souhaitez sur un futur.

### Get

Pour les cas où les alternatives basées sur la concurrence n'existent pas pour une API, vous pouvez attendre la valeur du futur avec `try await future.get()`.

```swift
/// Supposez que nous recevions une future chaîne d'une API.
let futureString: EventLoopFuture<String> = ...

/// Attend que la chaîne soit disponible.
let string: String = try await futureString.get()
print(string) /// String
```
    
### Wait

!!! Avertissement
    La fonction `wait()` est obsolète, voir [`Get`](#get) pour l'approche recommandée.

Vous pouvez utiliser `.wait()` pour attendre de façon synchrone que le futur soit accompli. Puique le futur peut échouer, cet appel peut lever une erreur.

```swift
/// Supposez recevoir une future chaîne d'une API.
let futureString: EventLoopFuture<String> = ...

/// Bloque le processus jusqu'à ce que la chaîne soit disponible.
let string = try futureString.wait()
print(string) /// String
```

`wait()` peut uniquement être utilisé sur un processus de fond ou sur le processus principal, i.e., dans `configure.swift`. Il _ne peut pas_ être utilisé sur un processus EventLoop, i.e., dans une Closure de route.

!!! Avertissement
    Tenter d'appeler `wait()` depuis un processus EventLoop résultera en échec d'assertion.
    
## Promesse

La plupart du temps, vous transformerez des futurs retournés par des appels aux APIs de Vapor. Cependant, vous arriverez peut-être à un point où vous devrez créer votre propre objet Promesse.

Pour créer une promesse, vous aurez besoin d'accéder à un `EventLoop`. Vous pouvez y accéder depuis les objets `Application` ou `Request` en fonction de votre contexte.

```swift
let eventLoop: EventLoop 

// Crée une nouvelle promesse de chaîne de caractères.
let promiseString = eventLoop.makePromise(of: String.self)
print(promiseString) // EventLoopPromise<String>
print(promiseString.futureResult) // EventLoopFuture<String>

// Accomplit le futur associé.
promiseString.succeed("Hello")

// Compromet le futur associé.
promiseString.fail(...)
```

!!! info
    Une promesse ne peut être résolue qu'une seule fois. Toute résolution ultérieure sera ignorée.

Les promesses peuvent être résolues (`succeed` / `fail`) depuis n'importe quel processus. C'est pour cette raison qu'elles ont besoin d'un EventLoop pour être initialisées. Les promesses garantissent que l'action de résolution sera exécutée sur son EventLoop d'origine.

## Event Loop

Lorsque votre application démarre, elle crée généralement un EventLoop pour chaque coeur du processeur sur lequel elle tourne. Chaque EventLoop possède exactement un et un seul processus. Si vous êtes familier avec la notion d'EventLoop de Node.js, ceux de Vapor sont similaires. La différence principale est que Vapor est capable de gérer plusieurs EventLoops sur un processus unique puisque Swift supporte le multi-threading.

Chaque fois qu'un client se connecte à votre serveur, il sera assigné à l'un des EventLoops. A partir de là, toute communication entre le serveur et ce client se passera sur ce même EventLoop (et par association, le processus de cet EventLoop). 

L'EventLoop a la responsabilité de suivre l'état de chaque client connecté. S'il existe une requête du client en attente de lecture, l'EventLoop déclenche une notification de lecture, résultant en la lecture des données. Une fois la requête entièrement lue, tout futur en attente des données de cette requête sera accompli. 

Dans les Closures de routes, vous avez accès à l'EventLoop courant à travers l'objet `Request`. 

```swift
req.eventLoop.makePromise(of: ...)
```

!!! Avertissement
    Vapor s'attend à ce que les Closures de routes restent sur `req.eventLoop`. Si vous passez sur un autre processus, vous devez vous assurer que les accès à `Request` et à la future réponse finale se passent tous sur l'EventLoop de la requête. 

En dehors des Closures de routes, vous pouvez accéder à l'un des EventLoops disponible via l'objet `Application`. 

```swift
app.eventLoopGroup.next().makePromise(of: ...)
```

### hop

Vous pouvez modifier l'EventLoop d'un futur en utilisant la méthode `hop`.

```swift
futureString.hop(to: otherEventLoop)
```

## Code bloquant

Appeler du code bloquant sur le processus d'un EventLoop peut empêcher votre application de répondre aux requêtes entrantes à temps. Un exemple d'appel bloquant pourrait être `libc.sleep(_:)`.

```swift
app.get("hello") { req in
    /// Met le processus de l'EventLoop en pause.
    sleep(5)
    
    /// Retourne une simple chaîne lorsque le processus reprend son cours.
    return "Hello, world!"
}
```

`sleep(_:)` est une commande qui bloque le processus courant pendant le nombre de secondes passé en paramètre. Si vous exécutez du code bloquant comme ceci directement sur un EventLoop, celui-ci sera en incapacité de répondre aux autres clients qui lui sont assignés pendant toute la durée du bloquage. En d'autres mots, si vous appelez `sleep(5)` sur un EventLoop, tous les autres clients connectés à cet EventLoop (potentiellement des centaines ou des milliers) seront retardés d'au moins 5 secondes. 

Assurez-vous de lancer tout code bloquant en tâche de fond. Utilisez les promesses pour notifier l'EventLoop de la fin du travail de façon non bloquante.

```swift
app.get("hello") { req -> EventLoopFuture<String> in
    /// Délègue un travail à une tâche de fond
    return req.application.threadPool.runIfActive(eventLoop: req.eventLoop) {
        /// Met la tâche de fond en pause
        /// Ceci n'affectera aucun EventLoop
        sleep(5)
        
        /// Lorsque le "travail bloquant" est terminé,
        /// retourne le résultat.
        return "Hello world!"
    }
}
```

Tous les appels bloquants ne seront pas aussi évidents que `sleep(_:)`. Si vous soupçonnez que l'usage d'un de vos appels soit bloquant, renseignez-vous sur la méthode elle-même ou demandez à quelqu'un qui pourrait connaître cette méthode. Les sections suivantes couvrent les façons dont les méthodes peuvent être bloquantes plus en détails.

### Bloquage sur Entrées/Sorties

Un bloquage en lien avec les entrées/sorties implique d'attendre une ressource lente, telle que le réseau ou disque dur, dont l'échelle de performances est incomparablement plus faible à celle du processeur. Bloquer le processeur pendant que vous attendez ces ressources est un gaspillage du temps de calcul disponible. 

!!! Danger
    N'exécutez jamais d'appel à des ressources liées aux entrées/sorties directement sur un EventLoop.

Tous les packages Vapor sont conçus sur SwiftNIO et utilisent des entrées/sorties non bloquantes. Il existe cependant de nombreux packages Swift et librairies C qui utilisent des entrées/sorties bloquantes. Les probabilités sont assez élevées pour qu'une fonction soit bloquante si elle utilise le disque ou le réseau avec une API synchrone (sans callback ou futur).
    
### Bloquage processeur

La plupart du temps nécessaire au traitement d'une requête est passé dans l'attente de ressources externes, comme des requêtes en bases de données, ou le chargement de ressources réseau. Comme Vapor et SwiftNIO sont non-bloquants, ces temps morts peuvent être utilisés au traitement d'autres requêtes entrantes. En revanche, certaines routes de votre application pourraient avoir besoin d'utiliser votre processeur de façon intensive en réponse à une requête.

Pendant qu'un EventLoop est occupé à traiter une charge de travail intense en ressource processeur, il sera en incapacité de répondre à d'autres requêtes entrantes. Ce compromis est généralement acceptable étant donné que les processeurs sont rapides et que la plupart des tâches que font les applications web sur le processeur sont légères. Mais cela pourrait devenir un problème si des routes exécutent de longues tâches sur le processeur, et empêchent les requêtes de routes plus rapides d'obtenir une réponse rapidement. 

Identifier les tâches gourmandes en processeur dans votre application et les déléguer à un processus de fond peut participer à l'amélioration de la fiabilité et réactivité de votre service. Le travail bloquant le processeur est une zone moins tranchée que celle liée aux entrées/sorties, et en définitive, il vous reviendra de déterminer où vous souhaitez placer vos limites acceptables et compromis. 

Un exemple de tâche intensive sur le processeur est la génération de hash Bcrypt lorsqu'un utilisateur crée un compte ou se connecte. Bcrypt est délibérément très lent et consomme beaucoup de ressources processeur pour des raisons de sécurité. Il se pourrait que ce soit la tâche la plus gourmande en processeur qu'une simple application web ait a exécuter. Déléguer le hachage à un processus de fond peut permettre au processeur de traiter d'autres tâches des EventLoops tout en calculant des hashs, ce qui augmente le nombre de tâches pouvant être traitées en parallèle.
