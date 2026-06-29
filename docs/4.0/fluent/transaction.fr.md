# Transactions

Les transactions vous permettent de garantir que plusieurs opérations se terminent avec succès avant de valider définitivement leur enregistrement dans votre base de données. 
Une fois une transaction démarrée, vous pouvez exécuter des requêtes Fluent normalement. Cependant, aucune donnée ne sera enregistrée dans la base de données tant que la transaction n'est pas terminée. 
Si une erreur est générée à tout moment au cours de la transaction (par vous ou par la base de données), aucune des modifications ne prendra effet.

Pour effectuer une transaction, vous devez accéder à un objet qui peut se connecter à la base de données. Il s'agit généralement d'une requête HTTP entrante. Pour cela, utilisez `req.db.transaction(_ :)` :
```swift
req.db.transaction { database in
    // utiliser la base de données
}
```
Une fois à l'intérieur de la closure de la transaction, vous devez utiliser la base de données fournie dans le paramètre de closure (nommée `database` dans l'exemple) pour effectuer des requêtes.

La transaction sera validée et toutes ses opérations seront définitivement enregistrées si aucune erreur n'est rencontrée.
```swift
var sun: Star = ...
var sirius: Star = ...

return req.db.transaction { database in
    return sun.save(on: database).flatMap { _ in
        return sirius.save(on: database)
    }
}
```
L'exemple ci-dessus enregistrera `sun` et *puis* `sirius` avant de terminer la transaction. Si un seul des deux enregistrements échoue, aucun ne sera validé.

Une fois la transaction terminée, le résultat peut être transformé en un futur différent, par exemple en un statut HTTP pour indiquer le statut de fin de la transaction, comme ci-dessous :
```swift
return req.db.transaction { database in
    // utilise la base de données pour effectuer une transaction
}.transform(to: HTTPStatus.ok)
```

## `async`/`await`

Si vous utilisez `async`/`await`, vous pouvez refactoriser le code comme ceci :

```swift
try await req.db.transaction { transaction in
    try await sun.save(on: transaction)
    try await sirius.save(on: transaction)
}
return .ok
```
