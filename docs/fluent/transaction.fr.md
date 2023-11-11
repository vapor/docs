# Transactions

Les transactions vous permettent de garantir que plusieurs opérations se terminent avec succès avant d'enregistrer les données dans votre base de données. 
Une fois une transaction démarrée, vous pouvez exécuter des requêtes Fluent normalement. Cependant, aucune donnée ne sera enregistrée dans la base de données tant que la transaction n'est pas terminée. 
Si une erreur est générée à tout moment au cours de la transaction (par vous ou par la base de données), aucune des modifications ne prendra effet.

Pour effectuer une transaction, vous devez accéder à quelque chose qui peut se connecter à la base de données. Il s'agit généralement d'une requête HTTP entrante. Pour cela, utilisez `req.db.transaction(_ :)` :
```swift
req.db.transaction { database in
    // utiliser la base de données
}
```
Une fois à l'intérieur de la closure de la transaction, vous devez utiliser la base de données fournie dans le paramètre de closure (nommée `database` dans l'exemple) pour effectuer des requêtes.

Une fois cette fermeture réussie, la transaction sera validée.
```swift
var sun: Star = ...
var sirius: Star = ...

return req.db.transaction { database in
    return sun.save(on: database).flatMap { _ in
        return sirius.save(on: database)
    }
}
```
L'exemple ci-dessus enregistrera `sun` et *puis* `sirius` avant de terminer la transaction. Si l’une des étoiles ne parvient pas à sauvegarder, aucune des deux ne le fera.

Une fois la transaction terminée, le résultat peut être transformé dans un futur différent, par exemple en un statut HTTP pour indiquer la fin, comme indiqué ci-dessous :
```swift
return req.db.transaction { database in
    // utiliser la base de données et effectue une transaction
}.transform(to: HTTPStatus.ok)
```

## `async`/`await`

Si vous utilisez `async`/`await`, vous pouvez refactoriser le code comme suit :

```swift
try await req.db.transaction { transaction in
    try await sun.save(on: transaction)
    try await sirius.save(on: transaction)
}
return .ok
```
