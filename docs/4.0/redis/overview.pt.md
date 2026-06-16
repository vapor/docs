# Redis

O [Redis](https://redis.io/) é um dos armazenamentos de estruturas de dados em memória mais populares, comumente usado como cache ou broker de mensagens.

Esta biblioteca é uma integração entre o Vapor e o [**RediStack**](https://github.com/swift-server/RediStack), que é o driver subjacente que se comunica com o Redis.

!!! note "Nota"
    A maioria das funcionalidades do Redis é fornecida pelo **RediStack**.
    Recomendamos fortemente que você se familiarize com sua documentação.

    _Links são fornecidos quando apropriado._

## Pacote

O primeiro passo para usar o Redis é adicioná-lo como dependência ao seu projeto no manifesto do pacote Swift.

> Este exemplo é para um pacote existente. Para ajuda sobre como iniciar um novo projeto, consulte o guia principal de [Primeiros Passos](../getting-started/hello-world.md).

```swift
dependencies: [
    // ...
    .package(url: "https://github.com/vapor/redis.git", from: "4.0.0")
]
// ...
targets: [
    .target(name: "App", dependencies: [
        // ...
        .product(name: "Redis", package: "redis")
    ])
]
```

## Configuração

O Vapor emprega uma estratégia de pool para instâncias de [`RedisConnection`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redisconnection), e há várias opções para configurar conexões individuais, bem como os pools em si.

O mínimo necessário para configurar o Redis é fornecer uma URL para conexão:

```swift
let app = Application()

app.redis.configuration = try RedisConfiguration(hostname: "localhost")
```

### Configuração do Redis

> Documentação da API: [`RedisConfiguration`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration)

#### serverAddresses

Se você tem múltiplos endpoints Redis, como um cluster de instâncias Redis, você vai querer criar uma coleção [`[SocketAddress]`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/socketaddress) para passar no inicializador.

A forma mais comum de criar um `SocketAddress` é com o método estático [`makeAddressResolvingHost(_:port:)`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/niocore/socketaddress/makeaddressresolvinghost(_:port:)).

```swift
let serverAddresses: [SocketAddress] = [
  try .makeAddressResolvingHost("localhost", port: RedisConnection.Configuration.defaultPort)
]
```

Para um único endpoint Redis, pode ser mais fácil trabalhar com os inicializadores de conveniência, pois eles cuidam da criação do `SocketAddress` para você:

- [`.init(url:pool)`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/init(url:tlsconfiguration:pool:)-o9lf) (com `String` ou [`Foundation.URL`](https://developer.apple.com/documentation/foundation/url))
- [`.init(hostname:port:password:database:pool:)`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/init(hostname:port:password:tlsconfiguration:database:pool:))

#### password

Se sua instância Redis é protegida por senha, você precisará passá-la como argumento `password`.

Cada conexão, ao ser criada, será autenticada usando a senha.

#### database

Este é o índice do banco de dados que você deseja selecionar quando cada conexão é criada.

Isso evita que você tenha que enviar o comando `SELECT` para o Redis manualmente.

!!! warning "Aviso"
    A seleção do banco de dados não é mantida. Tenha cuidado ao enviar o comando `SELECT` por conta própria.

### Opções do Pool de Conexões

> Documentação da API: [`RedisConfiguration.PoolOptions`](https://api.vapor.codes/redis/documentation/redis/redisconfiguration/pooloptions)

!!! note "Nota"
    Apenas as opções mais comumente alteradas são destacadas aqui. Para todas as opções, consulte a documentação da API.

#### minimumConnectionCount

Este é o valor para definir quantas conexões você quer que cada pool mantenha o tempo todo.

Se o valor for `0`, então se as conexões forem perdidas por qualquer motivo, o pool não as recriará até que sejam necessárias.

Isso é conhecido como uma conexão de "cold start" e tem alguma sobrecarga em comparação com manter uma contagem mínima de conexões.

#### maximumConnectionCount

Esta opção determina o comportamento de como a contagem máxima de conexões é mantida.

!!! seealso "Veja Também"
    Consulte a API `RedisConnectionPoolSize` para se familiarizar com as opções disponíveis.

## Enviando um Comando

Você pode enviar comandos usando a propriedade `.redis` em qualquer instância de [`Application`](https://api.vapor.codes/vapor/documentation/vapor/application) ou [`Request`](https://api.vapor.codes/vapor/documentation/vapor/request), que lhe dará acesso a um [`RedisClient`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redisclient).

Qualquer `RedisClient` possui diversas extensões para todos os vários [comandos do Redis](https://redis.io/commands).

```swift
let value = try app.redis.get("my_key", as: String.self).wait()
print(value)
// Optional("my_value")

// ou

let value = try await app.redis.get("my_key", as: String.self)
print(value)
// Optional("my_value")
```

### Comandos Não Suportados

Caso o **RediStack** não suporte um comando com um método de extensão, você ainda pode enviá-lo manualmente.

```swift
// cada valor após o comando é o argumento posicional que o Redis espera
try app.redis.send(command: "PING", with: ["hello"])
    .map {
        print($0)
    }
    .wait()
// "hello"

// ou

let res = try await app.redis.send(command: "PING", with: ["hello"])
print(res)
// "hello"
```

## Modo Pub/Sub

O Redis suporta a capacidade de entrar em um [modo "Pub/Sub"](https://redis.io/topics/pubsub) onde uma conexão pode ouvir "canais" específicos e executar closures específicas quando os canais inscritos publicam uma "mensagem" (algum valor de dados).

Existe um ciclo de vida definido para uma assinatura:

1. **subscribe**: invocado uma vez quando a assinatura começa
1. **message**: invocado 0+ vezes conforme mensagens são publicadas nos canais inscritos
1. **unsubscribe**: invocado uma vez quando a assinatura termina, seja por solicitação ou pela perda da conexão

Ao criar uma assinatura, você deve fornecer pelo menos um [`messageReceiver`](https://swiftpackageindex.com/swift-server/RediStack/main/documentation/redistack/redissubscriptionmessagereceiver) para lidar com todas as mensagens publicadas pelo canal inscrito.

Opcionalmente, você pode fornecer um `RedisSubscriptionChangeHandler` para `onSubscribe` e `onUnsubscribe` para lidar com seus respectivos eventos do ciclo de vida.

```swift
// cria 2 assinaturas, uma para cada canal fornecido
app.redis.subscribe
  to: "channel_1", "channel_2",
  messageReceiver: { channel, message in
    switch channel {
    case "channel_1": // fazer algo com a mensagem
    default: break
    }
  },
  onUnsubscribe: { channel, subscriptionCount in
    print("cancelou inscrição de \(channel)")
    print("inscrições restantes: \(subscriptionCount)")
  }
```
