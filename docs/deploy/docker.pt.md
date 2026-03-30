# Deploy com Docker

Usar Docker para fazer o deploy da sua aplicação Vapor tem vários benefícios:

1. Sua aplicação dockerizada pode ser iniciada de forma confiável usando os mesmos comandos em qualquer plataforma com um Docker Daemon — nomeadamente, Linux (CentOS, Debian, Fedora, Ubuntu), macOS e Windows.
2. Você pode usar docker-compose ou manifestos Kubernetes para orquestrar múltiplos serviços necessários para um deploy completo (ex: Redis, Postgres, nginx, etc.).
3. É fácil testar a capacidade da sua aplicação de escalar horizontalmente, mesmo localmente na sua máquina de desenvolvimento.

Este guia não vai explicar como levar sua aplicação dockerizada para um servidor. O deploy mais simples envolveria instalar o Docker no seu servidor e executar os mesmos comandos que você executaria na sua máquina de desenvolvimento para iniciar sua aplicação.

Deploys mais complicados e robustos geralmente diferem dependendo da sua solução de hospedagem; muitas soluções populares como AWS têm suporte integrado para Kubernetes e soluções de banco de dados customizadas, o que torna difícil escrever melhores práticas de uma forma que se aplique a todos os deploys.

No entanto, usar Docker para iniciar toda a sua stack de servidor localmente para fins de teste é incrivelmente valioso tanto para aplicações serverside grandes quanto pequenas. Além disso, os conceitos descritos neste guia se aplicam em linhas gerais a todos os deploys com Docker.

## Configuração

Você precisará configurar seu ambiente de desenvolvimento para executar o Docker e obter um entendimento básico dos arquivos de recursos que configuram stacks Docker.

### Instalar Docker

Você precisará instalar o Docker para seu ambiente de desenvolvimento. Você pode encontrar informações para qualquer plataforma na seção [Supported Platforms](https://docs.docker.com/install/#supported-platforms) da visão geral do Docker Engine. Se você está no macOS, pode ir diretamente para a página de instalação do [Docker for Mac](https://docs.docker.com/docker-for-mac/install/).

### Gerar Template

Sugerimos usar o template do Vapor como ponto de partida. Se você já tem uma aplicação, compile o template conforme descrito abaixo em uma nova pasta como ponto de referência enquanto dockeriza sua aplicação existente — você pode copiar recursos-chave do template para sua aplicação e ajustá-los levemente como ponto de partida.

1. Instale ou compile o Vapor Toolbox ([macOS](../install/macos.md#install-toolbox), [Linux](../install/linux.md#install-toolbox)).
2. Crie uma nova aplicação Vapor com `vapor new my-dockerized-app` e siga os prompts para habilitar ou desabilitar funcionalidades relevantes. Suas respostas a esses prompts afetarão como os arquivos de recursos Docker são gerados.

## Recursos Docker

Vale a pena, seja agora ou em breve, familiarizar-se com a [Visão Geral do Docker](https://docs.docker.com/engine/docker-overview/). A visão geral vai explicar algumas terminologias-chave que este guia utiliza.

O template de aplicação Vapor tem dois recursos-chave específicos do Docker: um **Dockerfile** e um arquivo **docker-compose**.

### Dockerfile

Um Dockerfile diz ao Docker como compilar uma imagem da sua aplicação dockerizada. Essa imagem contém tanto o executável da sua aplicação quanto todas as dependências necessárias para executá-la. A [referência completa](https://docs.docker.com/engine/reference/builder/) vale a pena manter aberta quando estiver trabalhando na customização do seu Dockerfile.

O Dockerfile gerado para sua aplicação Vapor tem dois estágios. O primeiro estágio compila sua aplicação e configura uma área de espera contendo o resultado. O segundo estágio configura o básico de um ambiente de execução seguro, transfere tudo na área de espera para onde ficará na imagem final, e define um entrypoint e comando padrão que executará sua aplicação em modo de produção na porta padrão (8080). Esta configuração pode ser sobrescrita quando a imagem é utilizada.

### Arquivo Docker Compose

Um arquivo Docker Compose define a forma como o Docker deve compilar múltiplos serviços em relação uns aos outros. O arquivo Docker Compose no template de aplicação Vapor fornece a funcionalidade necessária para fazer o deploy da sua aplicação, mas se você quiser saber mais, consulte a [referência completa](https://docs.docker.com/compose/compose-file/) que tem detalhes sobre todas as opções disponíveis.

!!! note "Nota"
    Se você planeja usar Kubernetes para orquestrar sua aplicação, o arquivo Docker Compose não é diretamente relevante. No entanto, os arquivos de manifesto do Kubernetes são conceitualmente similares e existem até projetos voltados para [converter arquivos Docker Compose](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/) em manifestos Kubernetes.

O arquivo Docker Compose na sua nova aplicação Vapor definirá serviços para executar sua aplicação, executar migrações ou revertê-las, e executar um banco de dados como camada de persistência da sua aplicação. As definições exatas variam dependendo de qual banco de dados você escolheu ao executar `vapor new`.

Note que seu arquivo Docker Compose tem algumas variáveis de ambiente compartilhadas próximo ao topo. (Você pode ter um conjunto diferente de variáveis padrão dependendo de estar ou não usando o Fluent e qual driver do Fluent está em uso.)

```docker
x-shared_environment: &shared_environment
  LOG_LEVEL: ${LOG_LEVEL:-debug}
  DATABASE_HOST: db
  DATABASE_NAME: vapor_database
  DATABASE_USERNAME: vapor_username
  DATABASE_PASSWORD: vapor_password
```

Você verá essas variáveis sendo puxadas para múltiplos serviços abaixo com a sintaxe de referência YAML `<<: *shared_environment`.

As variáveis `DATABASE_HOST`, `DATABASE_NAME`, `DATABASE_USERNAME` e `DATABASE_PASSWORD` estão fixas no código neste exemplo, enquanto o `LOG_LEVEL` receberá seu valor do ambiente executando o serviço ou fará fallback para `'debug'` se a variável não estiver definida.

!!! note "Nota"
    Fixar o nome de usuário e senha no código é aceitável para desenvolvimento local, mas você deve armazenar essas variáveis em um arquivo de secrets para deploy em produção. Uma forma de lidar com isso em produção é exportar o arquivo de secrets para o ambiente que está executando seu deploy e usar linhas como a seguinte no seu arquivo Docker Compose:

    ```
    DATABASE_USERNAME: ${DATABASE_USERNAME}
    ```

    Isso passa a variável de ambiente para os containers como definida pelo host.

Outras coisas a observar:

- Dependências de serviço são definidas por arrays `depends_on`.
- Portas de serviço são expostas ao sistema executando os serviços com arrays `ports` (formatadas como `<host_port>:<service_port>`).
- O `DATABASE_HOST` é definido como `db`. Isso significa que sua aplicação acessará o banco de dados em `http://db:5432`. Isso funciona porque o Docker criará uma rede em uso pelos seus serviços e o DNS interno nessa rede roteará o nome `db` para o serviço chamado `'db'`.
- A diretiva `CMD` no Dockerfile é sobrescrita em alguns serviços com o array `command`. Note que o que é especificado por `command` é executado contra o `ENTRYPOINT` no Dockerfile.
- No Swarm Mode (mais sobre isso abaixo) os serviços por padrão receberão 1 instância, mas os serviços `migrate` e `revert` são definidos como tendo `deploy` `replicas: 0` para que não iniciem por padrão ao executar um Swarm.

## Compilando

O arquivo Docker Compose diz ao Docker como compilar sua aplicação (usando o Dockerfile no diretório atual) e como nomear a imagem resultante (`my-dockerized-app:latest`). Este último é na verdade a combinação de um nome (`my-dockerized-app`) e uma tag (`latest`) onde tags são usadas para versionar imagens Docker.

Para compilar uma imagem Docker da sua aplicação, execute

```shell
docker compose build
```

no diretório raiz do projeto da sua aplicação (a pasta contendo `docker-compose.yml`).

Você verá que sua aplicação e suas dependências precisam ser compiladas novamente mesmo se você as tiver compilado anteriormente na sua máquina de desenvolvimento. Elas estão sendo compiladas no ambiente de compilação Linux que o Docker está usando, então os artefatos de compilação da sua máquina de desenvolvimento não são reutilizáveis.

Quando terminar, você encontrará a imagem da sua aplicação ao executar

```shell
docker image ls
```

## Executando

Sua stack de serviços pode ser executada diretamente a partir do arquivo Docker Compose ou você pode usar uma camada de orquestração como Swarm Mode ou Kubernetes.

### Standalone

A forma mais simples de executar sua aplicação é iniciá-la como um container standalone. O Docker usará os arrays `depends_on` para garantir que quaisquer serviços dependentes também sejam iniciados.

Primeiro, execute:

```shell
docker compose up app
```

e note que tanto o serviço `app` quanto o `db` são iniciados.

Sua aplicação está escutando na porta 8080 e, conforme definido pelo arquivo Docker Compose, ela é acessível na sua máquina de desenvolvimento em **http://localhost:8080**.

Essa distinção de mapeamento de portas é muito importante porque você pode executar qualquer número de serviços nas mesmas portas se todos estiverem rodando em seus próprios containers e cada um expor portas diferentes para a máquina host.

Visite `http://localhost:8080` e você verá `It works!`, mas visite `http://localhost:8080/todos` e você receberá:

```
{"error":true,"reason":"Something went wrong."}
```

Dê uma olhada nos logs no terminal onde você executou `docker compose up app` e verá:

```
[ ERROR ] relation "todos" does not exist
```

Claro! Precisamos executar as migrações no banco de dados. Pressione `Ctrl+C` para encerrar sua aplicação. Vamos iniciar a aplicação novamente, mas desta vez com:

```shell
docker compose up --detach app
```

Agora sua aplicação vai iniciar "desanexada" (em segundo plano). Você pode verificar isso executando:

```shell
docker container ls
```

onde verá tanto o banco de dados quanto sua aplicação rodando em containers. Você pode até verificar os logs executando:

```shell
docker logs <container_id>
```

Para executar as migrações, execute:

```shell
docker compose run migrate
```

Após as migrações, você pode visitar `http://localhost:8080/todos` novamente e receberá uma lista vazia de todos em vez de uma mensagem de erro.

#### Níveis de Log

Lembre-se que a variável de ambiente `LOG_LEVEL` no arquivo Docker Compose será herdada do ambiente onde o serviço é iniciado, se disponível.

Você pode iniciar seus serviços com

```shell
LOG_LEVEL=trace docker-compose up app
```

para obter logging no nível `trace` (o mais granular). Você pode usar essa variável de ambiente para definir o logging em [qualquer nível disponível](../basics/logging.md#levels).

#### Logs de Todos os Serviços

Se você especificar explicitamente seu serviço de banco de dados ao iniciar os containers, verá logs tanto do seu banco de dados quanto da sua aplicação.

```shell
docker-compose up app db
```

#### Encerrando Containers Standalone

Agora que você tem containers rodando "desanexados" do seu shell host, precisa dizer a eles para desligarem de alguma forma. Vale saber que qualquer container em execução pode ser solicitado a encerrar com

```shell
docker container stop <container_id>
```

mas a forma mais fácil de encerrar esses containers específicos é

```shell
docker-compose down
```

#### Limpando o Banco de Dados

O arquivo Docker Compose define um volume `db_data` para persistir seu banco de dados entre execuções. Existem algumas formas de resetar seu banco de dados.

Você pode remover o volume `db_data` ao mesmo tempo que encerra seus containers com

```shell
docker-compose down --volumes
```

Você pode ver quaisquer volumes atualmente persistindo dados com `docker volume ls`. Note que o nome do volume geralmente terá um prefixo de `my-dockerized-app_` ou `test_` dependendo de estar executando no Swarm Mode ou não.

Você pode remover esses volumes um de cada vez com, por exemplo:

```shell
docker volume rm my-dockerized-app_db_data
```

Você também pode limpar todos os volumes com

```shell
docker volume prune
```

Apenas tenha cuidado para não remover acidentalmente um volume com dados que você queria manter!

O Docker não permitirá que você remova volumes que estão atualmente em uso por containers em execução ou parados. Você pode obter uma lista de containers em execução com `docker container ls` e pode ver containers parados também com `docker container ls -a`.

### Swarm Mode

O Swarm Mode é uma interface fácil de usar quando você tem um arquivo Docker Compose em mãos e quer testar como sua aplicação escala horizontalmente. Você pode ler tudo sobre o Swarm Mode nas páginas a partir da [visão geral](https://docs.docker.com/engine/swarm/).

A primeira coisa que precisamos é de um nó manager para nosso Swarm. Execute

```shell
docker swarm init
```

Em seguida, usaremos nosso arquivo Docker Compose para iniciar uma stack chamada `'test'` contendo nossos serviços

```shell
docker stack deploy -c docker-compose.yml test
```

Podemos ver como nossos serviços estão com

```shell
docker service ls
```

Você deve esperar ver `1/1` réplicas para seus serviços `app` e `db` e `0/0` réplicas para seus serviços `migrate` e `revert`.

Precisamos usar um comando diferente para executar migrações no Swarm mode.

```shell
docker service scale --detach test_migrate=1
```

!!! note "Nota"
    Acabamos de solicitar que um serviço de curta duração escale para 1 réplica. Ele vai escalar com sucesso, executar e depois encerrar. No entanto, isso o deixará com `0/1` réplicas em execução. Isso não é um grande problema até querermos executar migrações novamente, mas não podemos dizer para "escalar para 1 réplica" se já é onde ele está. Uma peculiaridade dessa configuração é que da próxima vez que quisermos executar migrações dentro do mesmo runtime do Swarm, precisamos primeiro escalar o serviço para `0` e depois de volta para `1`.

A recompensa pelo nosso trabalho no contexto deste breve guia é que agora podemos escalar nossa aplicação para o que quisermos para testar quão bem ela lida com contenção de banco de dados, falhas e mais.

Se você quiser executar 5 instâncias da sua aplicação concorrentemente, execute

```shell
docker service scale test_app=5
```

Além de observar o Docker escalar sua aplicação, você pode ver que 5 réplicas estão de fato em execução verificando novamente `docker service ls`.

Você pode visualizar (e acompanhar) os logs da sua aplicação com

```shell
docker service logs -f test_app
```

#### Encerrando Serviços do Swarm

Quando quiser encerrar seus serviços no Swarm Mode, faça isso removendo a stack que você criou anteriormente.

```shell
docker stack rm test
```

## Deploys em Produção

Como mencionado no início, este guia não vai entrar em grandes detalhes sobre o deploy da sua aplicação dockerizada em produção porque o tópico é extenso e varia muito dependendo do serviço de hospedagem (AWS, Azure, etc.), ferramentas (Terraform, Ansible, etc.) e orquestração (Docker Swarm, Kubernetes, etc.).

No entanto, as técnicas que você aprende para executar sua aplicação dockerizada localmente na sua máquina de desenvolvimento são amplamente transferíveis para ambientes de produção. Uma instância de servidor configurada para executar o daemon do Docker aceitará todos os mesmos comandos.

Copie os arquivos do seu projeto para o servidor, conecte-se via SSH no servidor e execute um comando `docker-compose` ou `docker stack deploy` para colocar as coisas funcionando remotamente.

Alternativamente, defina sua variável de ambiente `DOCKER_HOST` local para apontar para o seu servidor e execute os comandos `docker` localmente na sua máquina. É importante notar que com essa abordagem, você não precisa copiar nenhum dos arquivos do seu projeto para o servidor, _mas_ você precisa hospedar sua imagem Docker em algum lugar de onde seu servidor possa baixá-la.
