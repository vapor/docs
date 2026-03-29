# Transactions

Transações permitem que você garanta que múltiplas operações sejam concluídas com sucesso antes de salvar dados no seu banco de dados.
Uma vez que uma transação é iniciada, você pode executar queries do Fluent normalmente. No entanto, nenhum dado será salvo no banco de dados até que a transação seja concluída.
Se um erro for lançado em qualquer ponto durante a transação (por você ou pelo banco de dados), nenhuma das alterações terá efeito.

Para realizar uma transação, você precisa de acesso a algo que possa se conectar ao banco de dados. Isso geralmente é uma requisição HTTP recebida. Para isso, use `req.db.transaction(_ :)`:
```swift
req.db.transaction { database in
    // use database
}
```
Uma vez dentro da closure da transação, você deve usar o banco de dados fornecido no parâmetro da closure (chamado `database` no exemplo) para realizar queries.

Uma vez que esta closure retorne com sucesso, a transação será commitada.
```swift
var sun: Star = ...
var sirius: Star = ...

return req.db.transaction { database in
    return sun.save(on: database).flatMap { _ in
        return sirius.save(on: database)
    }
}
```
O exemplo acima salvará `sun` e *então* `sirius` antes de completar a transação. Se qualquer uma das estrelas falhar ao salvar, nenhuma será salva.

Uma vez que a transação for concluída, o resultado pode ser transformado em um future diferente, por exemplo em um status HTTP para indicar conclusão como mostrado abaixo:
```swift
return req.db.transaction { database in
    // use database and perform transaction
}.transform(to: HTTPStatus.ok)
```

## `async`/`await`

Se estiver usando `async`/`await`, você pode refatorar o código para o seguinte:

```swift
try await req.db.transaction { transaction in
    try await sun.save(on: transaction)
    try await sirius.save(on: transaction)
}
return .ok
```
