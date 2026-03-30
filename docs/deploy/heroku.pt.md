# O que é o Heroku

Heroku é uma solução de hospedagem completa e popular, você pode encontrar mais em [heroku.com](https://www.heroku.com)

## Criando uma Conta

Você precisará de uma conta no Heroku, se não tiver uma, por favor cadastre-se aqui: [https://signup.heroku.com/](https://signup.heroku.com/)

## Instalando o CLI

Certifique-se de ter instalado a ferramenta CLI do Heroku.

### HomeBrew

```bash
brew tap heroku/brew && brew install heroku
```

### Outras Opções de Instalação

Veja opções alternativas de instalação aqui: [https://devcenter.heroku.com/articles/heroku-cli#download-and-install](https://devcenter.heroku.com/articles/heroku-cli#download-and-install).

### Fazendo Login

Depois de instalar o CLI, faça login com o seguinte comando:

```bash
heroku login
```

Verifique se o e-mail correto está logado com:

```bash
heroku auth:whoami
```

### Criar uma Aplicação

Visite dashboard.heroku.com para acessar sua conta e crie uma nova aplicação no menu suspenso no canto superior direito. O Heroku fará algumas perguntas como região e nome da aplicação, basta seguir as instruções.

### Git

O Heroku usa Git para fazer o deploy da sua aplicação, então você precisará colocar seu projeto em um repositório Git, se ainda não estiver.

#### Inicializar Git

Se você precisa adicionar o Git ao seu projeto, digite o seguinte comando no Terminal:

```bash
git init
```

#### Main

Você deve escolher uma branch e manter essa para fazer deploy no Heroku, como a branch **main** ou **master**. Certifique-se de que todas as alterações estejam comitadas nesta branch antes de fazer push.

Verifique sua branch atual com:

```bash
git branch
```

O asterisco indica a branch atual.

```bash
* main
  commander
  other-branches
```

!!! note "Nota"
    Se você não vê nenhuma saída e acabou de executar `git init`, você precisará comitar seu código primeiro, então verá a saída do comando `git branch`.

Se você _não_ está atualmente na branch correta, mude para ela digitando (para **main**):

```bash
git checkout main
```

#### Comitar alterações

Se este comando produzir saída, então você tem alterações não comitadas.

```bash
git status --porcelain
```

Comite-as com o seguinte:

```bash
git add .
git commit -m "a description of the changes I made"
```

#### Conectar com o Heroku

Conecte sua aplicação com o Heroku (substitua pelo nome da sua aplicação).

```bash
$ heroku git:remote -a your-apps-name-here
```

### Configurar Buildpack

Configure o buildpack para ensinar o Heroku como lidar com o Vapor.

```bash
heroku buildpacks:set vapor/vapor
```

### Arquivo de versão do Swift

O buildpack que adicionamos procura um arquivo **.swift-version** para saber qual versão do Swift usar. (Substitua 5.8.1 pela versão que seu projeto requer.)

```bash
echo "5.8.1" > .swift-version
```

Isso cria o **.swift-version** com `5.8.1` como seu conteúdo.

### Procfile

O Heroku usa o **Procfile** para saber como executar sua aplicação, no nosso caso ele precisa se parecer com isso:

```
web: App serve --env production --hostname 0.0.0.0 --port $PORT
```

Podemos criar isso com o seguinte comando no terminal:

```bash
echo "web: App serve --env production" \
  "--hostname 0.0.0.0 --port \$PORT" > Procfile
```

### Comitar alterações

Acabamos de adicionar esses arquivos, mas eles não estão comitados. Se fizermos push, o Heroku não os encontrará.

Comite-os com o seguinte:

```bash
git add .
git commit -m "adding heroku build files"
```

### Deploy no Heroku

Você está pronto para o deploy, execute isso no terminal. Pode demorar um pouco para compilar, isso é normal.

```bash
git push heroku main
```

### Escalar

Depois de compilar com sucesso, você precisa adicionar pelo menos um servidor. Os preços começam em $5/mês para o plano Eco (veja [preços](https://www.heroku.com/pricing#containers)), certifique-se de ter o pagamento configurado no Heroku. Então, para um único web worker:

```bash
heroku ps:scale web=1
```

### Deploy Contínuo

Sempre que quiser atualizar, basta trazer as últimas alterações para a main e fazer push para o Heroku, e ele fará o redeploy.

## Postgres

### Adicionar banco de dados PostgreSQL

Visite sua aplicação em dashboard.heroku.com e vá para a seção **Add-ons**.

A partir daqui, digite `postgres` e você verá uma opção para `Heroku Postgres`. Selecione-a.

Escolha o plano Essential 0 por $5/mês (veja [preços](https://www.heroku.com/pricing#data-services)) e provisione. O Heroku fará o resto.

Quando terminar, você verá o banco de dados aparecer na aba **Resources**.

### Configurar o banco de dados

Agora precisamos informar à nossa aplicação como acessar o banco de dados. No diretório da nossa aplicação, vamos executar:

```bash
heroku config
```

Isso produzirá uma saída parecida com esta:

```none
=== today-i-learned-vapor Config Vars
DATABASE_URL: postgres://cybntsgadydqzm:2d9dc7f6d964f4750da1518ad71hag2ba729cd4527d4a18c70e024b11cfa8f4b@ec2-54-221-192-231.compute-1.amazonaws.com:5432/dfr89mvoo550b4
```

**DATABASE_URL** aqui representará nosso banco de dados Postgres. **NUNCA** coloque a URL estática diretamente no código, o Heroku vai rotacioná-la e isso quebrará sua aplicação. Também é uma má prática. Em vez disso, leia a variável de ambiente em tempo de execução.

O addon Heroku Postgres [requer](https://devcenter.heroku.com/changelog-items/2035) que todas as conexões sejam criptografadas. Os certificados usados pelos servidores Postgres são internos ao Heroku, portanto uma conexão TLS **não verificada** deve ser configurada.

O trecho a seguir mostra como fazer ambos:

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    var tlsConfig: TLSConfiguration = .makeClientConfiguration()
    tlsConfig.certificateVerification = .none
    let nioSSLContext = try NIOSSLContext(configuration: tlsConfig)

    var postgresConfig = try SQLPostgresConfiguration(url: databaseURL)
    postgresConfig.coreConfiguration.tls = .require(nioSSLContext)

    app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
} else {
    // ...
}
```

Não esqueça de comitar essas alterações

```bash
git add .
git commit -m "configured heroku database"
```

### Revertendo seu banco de dados

Você pode reverter ou executar outros comandos no Heroku com o comando `run`.

Para reverter seu banco de dados:

```bash
heroku run App -- migrate --revert --all --yes --env production
```

Para migrar:

```bash
heroku run App -- migrate --env production
```
