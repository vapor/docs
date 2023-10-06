# Transacciones

Las transacciones te permiten asegurar que múltiples operaciones se completen con éxito antes de un guardado en tu base de datos. 
Una vez una transacción ha empezado, puedes ejecutar consultas de Fluent de manera normal. Sin embargo, ningún dato será guardado en la base de datos hasta que la transacción se complete. 
Si se lanza un error en algún momento durante la transacción (por ti o por la base de datos), no se efectuará ningún cambio.

Para llevar a cabo una transacción, necesitas acceso a algo que pueda conectar con la base de datos. Normalmente, esto es una petición HTTP entrante. Para esto, usa `req.db.transaction(_ :)`:

```swift
req.db.transaction { database in
    // usar la base de datos
}
```
Una vez dentro del closure de la transacción, debes usar la base de datos proporcionada en el parámetro del closure (llamado `database` en el ejemplo) para hacer consultas.

Cuando este closure devuelva de manera exitosa, se hará la transacción.
```swift
var sun: Star = ...
var sirius: Star = ...

return req.db.transaction { database in
    return sun.save(on: database).flatMap { _ in
        return sirius.save(on: database)
    }
}
```
El ejemplo anterior guardará `sun` y *después* `sirius` antes de completar la transacción. Si falla el guardado de cualquiera de las estrellas, ninguna se guardará.

Una vez la transacción se haya completado, el resultado puede transformarse en un futuro diferente, como un estatus HTTP que indique la finalización, de manera similar al siguiente ejemplo:
```swift
return req.db.transaction { database in
    // usa la base de datos y ejecuta la transacción
}.transform(to: HTTPStatus.ok)
```

## `async`/`await`

Si usas `async`/`await` puedes refactorizar el código de la siguiente manera:

```swift
try await req.db.transaction { transaction in
    try await sun.save(on: transaction)
    try await sirius.save(on: transaction)
}
return .ok
```
