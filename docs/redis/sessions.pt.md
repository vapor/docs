# Redis e Sessões

O Redis pode atuar como um provedor de armazenamento para fazer cache de [dados de sessão](../advanced/sessions.md#session-data), como credenciais de usuário.

Se um [`RedisSessionsDelegate`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate) personalizado não for fornecido, um padrão será utilizado.

## Comportamento Padrão

### Criação do SessionID

A menos que você implemente o método [`makeNewID()`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/makenewid()-3hyne) no [seu próprio `RedisSessionsDelegate`](#redissessionsdelegate), todos os valores de [`SessionID`](https://api.vapor.codes/vapor/documentation/vapor/sessionid) serão criados da seguinte forma:

1. Gerar 32 bytes de caracteres aleatórios
1. Codificar o valor em base64

Por exemplo: `Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

### Armazenamento de SessionData

A implementação padrão de `RedisSessionsDelegate` armazenará [`SessionData`](https://api.vapor.codes/vapor/documentation/vapor/sessiondata) como uma string JSON simples usando `Codable`.

A menos que você implemente o método [`makeRedisKey(for:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/makerediskey(for:)-5nfge) no seu próprio `RedisSessionsDelegate`, o `SessionData` será armazenado no Redis com uma chave que prefixa o `SessionID` com `vrs-` (**V**apor **R**edis **S**essions)

Por exemplo: `vrs-Hbxozx8rTj+XXGWAzOhh1npZFXaGLpTWpWCaXuo44xQ=`

## Registrando um Delegate Personalizado

Para personalizar como os dados são lidos e escritos no Redis, registre seu próprio objeto `RedisSessionsDelegate` da seguinte forma:

```swift
import Redis

struct CustomRedisSessionsDelegate: RedisSessionsDelegate {
    // implementação
}

app.sessions.use(.redis(delegate: CustomRedisSessionsDelegate()))
```

## RedisSessionsDelegate

> Documentação da API: [`RedisSessionsDelegate`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate)

Um objeto que conforma com este protocolo pode ser usado para alterar como o `SessionData` é armazenado no Redis.

Apenas dois métodos são obrigatórios para um tipo que conforma com o protocolo: [`redis(_:store:with:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/redis(_:store:with:)) e [`redis(_:fetchDataFor:)`](https://api.vapor.codes/redis/documentation/redis/redissessionsdelegate/redis(_:fetchdatafor:)).

Ambos são obrigatórios, pois a forma como você personaliza a escrita dos dados de sessão no Redis está intrinsecamente ligada à forma como eles são lidos.

### Exemplo de Hash com RedisSessionsDelegate

Por exemplo, se você quisesse armazenar os dados de sessão como um [**Hash** no Redis](https://redis.io/topics/data-types-intro#redis-hashes), você implementaria algo como o seguinte:

```swift
func redis<Client: RedisClient>(
    _ client: Client,
    store data: SessionData,
    with key: RedisKey
) -> EventLoopFuture<Void> {
    // armazena cada campo de dados como um campo separado do hash
    return client.hmset(data.snapshot, in: key)
}
func redis<Client: RedisClient>(
    _ client: Client,
    fetchDataFor key: RedisKey
) -> EventLoopFuture<SessionData?> {
    return client
        .hgetall(from: key)
        .map { hash in
            // hash é [String: RESPValue] então precisamos tentar desempacotar
            // o valor como string e armazenar cada valor no contêiner de dados
            return hash.reduce(into: SessionData()) { result, next in
                guard let value = next.value.string else { return }
                result[next.key] = value
            }
        }
}
```
