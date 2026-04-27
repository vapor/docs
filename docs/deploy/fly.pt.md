# Fly

Fly é uma plataforma de hospedagem que permite executar aplicações de servidor e bancos de dados com foco em edge computing. Veja [o site deles](https://fly.io/) para mais informações.

!!! note "Nota"
    Os comandos especificados neste documento estão sujeitos à [precificação do Fly](https://fly.io/docs/about/pricing/), certifique-se de entendê-la corretamente antes de continuar.

## Criando uma Conta
Se você não tem uma conta, precisará [criar uma](https://fly.io/app/sign-up).

## Instalando o flyctl
A principal forma de interagir com o Fly é usando a ferramenta CLI dedicada, `flyctl`, que você precisará instalar.

### macOS
```bash
brew install flyctl
```

### Linux
```bash
curl -L https://fly.io/install.sh | sh
```

### Outras opções de instalação
Para mais opções e detalhes, veja a [documentação de instalação do `flyctl`](https://fly.io/docs/flyctl/install/).

## Fazendo Login
Para fazer login pelo seu terminal, execute o seguinte comando:
```bash
fly auth login
```

## Configurando seu Projeto Vapor
Antes de fazer o deploy no Fly, você deve garantir que tem um projeto Vapor com um Dockerfile adequadamente configurado, já que ele é necessário para o Fly compilar sua aplicação. Na maioria dos casos, isso deve ser muito fácil, pois os templates padrão do Vapor já contêm um.

### Novo Projeto Vapor
A forma mais fácil de criar um novo projeto é começar com um template. Você pode criar um usando os templates do GitHub ou o Vapor toolbox. Se você precisar de um banco de dados, é recomendado usar o Fluent com Postgres; o Fly facilita a criação de um banco de dados Postgres para conectar suas aplicações (veja a [seção dedicada](#configurando-postgres) abaixo).

#### Usando o Vapor toolbox
Primeiro, certifique-se de ter instalado o Vapor toolbox (veja as instruções de instalação para [macOS](../install/macos.md#install-toolbox) ou [Linux](../install/linux.md#install-toolbox)).
Crie sua nova aplicação com o seguinte comando, substituindo `app-name` pelo nome desejado:
```bash
vapor new app-name
```

Este comando exibirá um prompt interativo que permitirá configurar seu projeto Vapor, onde você pode selecionar Fluent e Postgres se precisar deles.

#### Usando templates do GitHub
Escolha o template que melhor atenda às suas necessidades na lista a seguir. Você pode cloná-lo localmente usando Git ou criar um projeto no GitHub com o botão "Use this template".

- [Template básico](https://github.com/vapor/template-bare)
- [Template Fluent/Postgres](https://github.com/vapor/template-fluent-postgres)
- [Template Fluent/Postgres + Leaf](https://github.com/vapor/template-fluent-postgres-leaf)

### Projeto Vapor Existente
Se você tem um projeto Vapor existente, certifique-se de ter um `Dockerfile` corretamente configurado na raiz do seu diretório; a [documentação do Vapor sobre uso do Docker](../deploy/docker.md) e a [documentação do Fly sobre deploy de uma aplicação via Dockerfile](https://fly.io/docs/languages-and-frameworks/dockerfile/) podem ser úteis.

## Lançar sua Aplicação no Fly
Quando seu projeto Vapor estiver pronto, você pode lançá-lo no Fly.

Primeiro, certifique-se de que seu diretório atual está na raiz da sua aplicação Vapor e execute o seguinte comando:
```bash
fly launch
```

Isso iniciará um prompt interativo para configurar as definições da sua aplicação no Fly:

- **Nome:** você pode digitar um ou deixar em branco para obter um nome gerado automaticamente.
- **Região:** o padrão é a mais próxima de você. Você pode escolher usá-la ou qualquer outra da lista. Isso é fácil de alterar depois.
- **Banco de dados:** você pode pedir ao Fly para criar um banco de dados para usar com sua aplicação. Se preferir, você pode fazer o mesmo depois com os comandos `fly pg create` e `fly pg attach` (veja a [seção Configurando Postgres](#configurando-postgres) para mais detalhes).

O comando `fly launch` cria automaticamente um arquivo `fly.toml`. Ele contém configurações como mapeamentos de portas públicas/privadas, parâmetros de health checks, entre outros. Se você acabou de criar um novo projeto do zero usando `vapor new`, o arquivo `fly.toml` padrão não precisa de alterações. Se você tem um projeto existente, é provável que o `fly.toml` também esteja ok sem alterações ou com apenas pequenas mudanças. Você pode encontrar mais informações na [documentação do `fly.toml`](https://fly.io/docs/reference/configuration/).

Note que se você solicitar ao Fly para criar um banco de dados, precisará esperar um pouco para que ele seja criado e passe nos health checks.

Antes de encerrar, o comando `fly launch` perguntará se você gostaria de fazer o deploy da sua aplicação imediatamente. Você pode aceitar ou fazer depois usando `fly deploy`.

!!! tip "Dica"
    Quando seu diretório atual está na raiz da sua aplicação, a ferramenta CLI do Fly detecta automaticamente a presença de um arquivo `fly.toml`, o que permite ao Fly saber qual aplicação seus comandos estão direcionando. Se você quiser direcionar uma aplicação específica independentemente do seu diretório atual, pode adicionar `-a nome-da-sua-app` à maioria dos comandos do Fly.

## Deploy
Execute o comando `fly deploy` sempre que precisar fazer o deploy de novas alterações no Fly.

O Fly lê os arquivos `Dockerfile` e `fly.toml` do seu diretório para determinar como compilar e executar seu projeto Vapor.

Uma vez que seu container é compilado, o Fly inicia uma instância dele. Ele executará vários health checks, garantindo que sua aplicação está funcionando corretamente e que seu servidor responde a requisições. O comando `fly deploy` encerra com erro se os health checks falharem.

Por padrão, o Fly fará rollback para a última versão funcional da sua aplicação se os health checks falharem para a nova versão que você tentou fazer deploy.

Ao fazer o deploy de um worker em background (com Vapor Queues), não altere o CMD ou ENTRYPOINT no seu Dockerfile; deixe como está para que a aplicação web principal inicie normalmente. Em vez disso, adicione uma seção [processes] no seu arquivo fly.toml assim:

```
[processes]
  app = ""
  worker = "queues"
```

Isso diz ao Fly.io para executar o processo app com o entrypoint padrão do Docker (seu servidor web) e o processo worker para executar sua fila de jobs usando a interface de linha de comando do Vapor (ou seja, swift run App queues).

## Configurando Postgres

### Criando um banco de dados Postgres no Fly
Se você não criou uma aplicação de banco de dados quando lançou sua aplicação pela primeira vez, pode fazer isso depois usando:
```bash
fly pg create
```

Este comando cria uma aplicação Fly que será capaz de hospedar bancos de dados disponíveis para suas outras aplicações no Fly, veja a [documentação dedicada do Fly](https://fly.io/docs/postgres/) para mais detalhes.

Uma vez que sua aplicação de banco de dados esteja criada, vá para o diretório raiz da sua aplicação Vapor e execute:
```bash
fly pg attach name-of-your-postgres-app
```
Se você não sabe o nome da sua aplicação Postgres, pode encontrá-lo com `fly pg list`.

O comando `fly pg attach` cria um banco de dados e usuário destinados à sua aplicação, e então os expõe à sua aplicação através da variável de ambiente `DATABASE_URL`.

!!! note "Nota"
    A diferença entre `fly pg create` e `fly pg attach` é que o primeiro aloca e configura uma aplicação Fly que será capaz de hospedar bancos de dados Postgres, enquanto o segundo cria um banco de dados e usuário reais destinados à aplicação de sua escolha. Desde que atenda aos seus requisitos, uma única aplicação Postgres no Fly pode hospedar múltiplos bancos de dados usados por várias aplicações. Quando você pede ao Fly para criar uma aplicação de banco de dados no `fly launch`, ele faz o equivalente a chamar tanto `fly pg create` quanto `fly pg attach`.

### Conectando sua aplicação Vapor ao banco de dados
Uma vez que sua aplicação está conectada ao banco de dados, o Fly define a variável de ambiente `DATABASE_URL` com a URL de conexão que contém suas credenciais (ela deve ser tratada como informação sensível).

Com a maioria das configurações comuns de projetos Vapor, você configura seu banco de dados em `configure.swift`. Veja como você pode fazer isso:

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    try app.databases.use(.postgres(url: databaseURL), as: .psql)
} else {
    // Trate a DATABASE_URL ausente aqui...
    //
    // Alternativamente, você também pode definir uma configuração diferente
    // dependendo se app.environment está definido como
    // `.development` ou `.production`
}
```

Neste ponto, seu projeto deve estar pronto para executar migrações e usar o banco de dados.

### Executando migrações
Com o `release_command` do `fly.toml`, você pode pedir ao Fly para executar um determinado comando antes de iniciar seu processo principal do servidor. Adicione isso ao `fly.toml`:
```toml
[deploy]
 release_command = "migrate -y"
```

!!! note "Nota"
    O trecho de código acima assume que você está usando o Dockerfile padrão do Vapor que define o `ENTRYPOINT` da sua aplicação como `./App`. Concretamente, isso significa que quando você define `release_command` como `migrate -y`, o Fly chamará `./App migrate -y`. Se seu `ENTRYPOINT` estiver definido com um valor diferente, você precisará adaptar o valor de `release_command`.

O Fly executará seu release command em uma instância temporária que tem acesso à sua rede interna do Fly, secrets e variáveis de ambiente.

Se seu release command falhar, o deploy não continuará.

### Outros bancos de dados
Embora o Fly facilite a criação de uma aplicação de banco de dados Postgres, é possível hospedar outros tipos de bancos de dados também (por exemplo, veja ["Use a MySQL database"](https://fly.io/docs/app-guides/mysql-on-fly/) na documentação do Fly).

## Secrets e variáveis de ambiente
### Secrets
Use secrets para definir quaisquer valores sensíveis como variáveis de ambiente.
```bash
 fly secrets set MYSECRET=A_SUPER_SECRET_VALUE
```

!!! warning "Aviso"
    Tenha em mente que a maioria dos shells mantém um histórico dos comandos que você digitou. Tenha cuidado com isso ao definir secrets dessa forma. Alguns shells podem ser configurados para não lembrar comandos que são precedidos por um espaço. Veja também o [comando `fly secrets import`](https://fly.io/docs/flyctl/secrets-import/).

Para mais informações, veja a [documentação do `fly secrets`](https://fly.io/docs/apps/secrets/).

### Variáveis de ambiente
Você pode definir outras variáveis de ambiente não sensíveis no [`fly.toml`](https://fly.io/docs/reference/configuration/#the-env-variables-section), por exemplo:
```toml
[env]
  MAX_API_RETRY_COUNT = "3"
  SMS_LOG_LEVEL = "error"
```

## Conexão SSH
Você pode conectar-se às instâncias de uma aplicação usando:
```bash
fly ssh console -s
```

## Verificando os logs
Você pode verificar os logs em tempo real da sua aplicação usando:
```bash
fly logs
```

## Próximos passos
Agora que sua aplicação Vapor está implantada, há muito mais que você pode fazer, como escalar suas aplicações vertical e horizontalmente em múltiplas regiões, adicionar volumes persistentes, configurar deploy contínuo, ou até criar clusters de aplicações distribuídas. O melhor lugar para aprender como fazer tudo isso e mais é a [documentação do Fly](https://fly.io/docs/).
