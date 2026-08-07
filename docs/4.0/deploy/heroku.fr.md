# Ce qu'est Heroku

Heroku est une solution d'hébergement tout-en-un populaire, que vous pouvez découvrir sur [heroku.com](https://www.heroku.com)

## Créer un compte

Vous aurez besoin d'un compte Heroky, si vous n'en avez pas, veuillez vous inscrire ici : [https://signup.heroku.com/](https://signup.heroku.com/)

## Installer les outils CLI

Assurez-vous d'installer les outils CLI Heroku.

### Via HomeBrew

```bash
brew tap heroku/brew && brew install heroku
```

### Autres options d'installation

Vous trouverez des alternatives sur cette page : [https://devcenter.heroku.com/articles/heroku-cli#download-and-install](https://devcenter.heroku.com/articles/heroku-cli#download-and-install).

### Se connecter

Une fois la CLI installée, connectez-vous avec la commande suivante :

```bash
heroku login
```

Vérifiez que vous utilisez le bon compte avec cette commande :

```bash
heroku auth:whoami
```

### Créer une application

Rendez-vous sur dashboard.heroku.com pour accéder à votre compte, et créez une nouvelle application depuis le menu dépliant en haut à droite. Heroku vous posera quelques questions comme le choix d'une région et un nom d'application, suivez les étapes.

### Git

Heroku utilise Git pour déployer votre application, vous devrez donc placer votre projet dans un dépôt Git, si ce n'est pas déjà le cas.

#### Initialiser Git

Si vous avez besoin d'ajouter Git à votre projet, lancez la commande suivante dans votre Terminal :

```bash
git init
```

#### Main

Vous devez décidez de quelle branche sera utilisée pour déployer vers Heroku, comme les branches **main** ou **master**. Assurez-vous que toutes les modifications à déployer soient sur cette branche avant de les pousser.

Vérifiez votre branche actuelle avec la commande suivante :

```bash
git branch
```

L'astérisque indique la branche en cours d'utilisation.

```bash
* main
  commander
  other-branches
```

!!! Note 
    Si rien ne s'affiche et que vous venez juste de faire `git init`, vous devrez d'abord créer un commit de votre code.

Si vous n'êtes _pas_ actuellement sur la bonne branche, sélectionnez-la avec cette commande (pour la branche **main**) :

```bash
git switch main
```

#### Créer un commit

Si cette commande affiche un résultat, c'est que vous avez des modifications qui ne sont pas encore dans un commit.

```bash
git status --porcelain
```

Créez un commit comme ceci :

```bash
git add .
git commit -m "Description de vos modifications"
```

#### Connexion avec Heroku

Connectez votre application avec Heroku (remplacez le nom de votre application).

```bash
$ heroku git:remote -a nom-de-votre-application
```

### Choix du Buildpack

Définissez le buildpack vapor/vapor pour indiquer à Heroku comment gérer Vapor.

```bash
heroku buildpacks:set vapor/vapor
```

### Fichier de version Swift

Le buildpack que nous avons ajouté recherche un fichier **.swift-version** pour savoir quelle version de Swift utiliser. (Remplacez 5.8.1 par la version dont votre projet a besoin.)

```bash
echo "5.8.1" > .swift-version
```

Cela crée un fichier **.swift-version** avec pour contenu `5.8.1`.

### Procfile

Heroku utilise le **Procfile** pour savoir comment exécuter votre application. Dans notre cas, il doit ressembler à ceci :

```
web: App serve --env production --hostname 0.0.0.0 --port $PORT
```

Nous pouvons le créer avec la commande suivante :

```bash
echo "web: App serve --env production" \
  "--hostname 0.0.0.0 --port \$PORT" > Procfile
```

### Commit des modifications

Nous venons de créer ces fichiers, mais ils ne sont pas encore dans un commit. Si nous poussons la branche, Heroku ne trouvera pas ces fichiers.

Créez un commit avec la commande suivante :

```bash
git add .
git commit -m "Ajout des fichiers de compilation Heroku"
```

### Déployer sur Heroku

Vous êtes prêt à déployer, vous pouvez exécuter la commande suivante dans votre terminal. Cela peut prendre du temps à compiler, ce qui est normal.

```bash
git push heroku main
```

### Mise à l'échelle

Une fois que la compilation est faite, vous devez ajouter au moins un serveur. Cela engendre des frais (voir la [tarification](https://www.heroku.com/pricing#containers)), vous devrez avoir configuré un moyen de paiement sur Heroku. Puis, pour un seul serveur web, vous pourrez exécuter cette commande :

```bash
heroku ps:scale web=1
```

### Déploiement continu

A chaque fois que vous voudrez déployer une mise à jour, il vous suffira de mettre votre code sur la branche choisie et de la pousser vers Heroku pour qu'il relance un déploiement.

## Postgres

### Ajout d'une base de données PostgreSQL

Ouvrez votre application sur dashboard.heroku.com et ouvrez la section **Add-ons**.

Tapez ensuite `postgres`, vous devriez voir une option `Heroku Postgres` s'afficher. Sélectionnez-la.

Choisissez le plan de paiement qui vous correspond (voir la [tarification](https://www.heroku.com/pricing#data-services)). Heroku se charge du reste.

Une fois le processus terminé, vous retrouverez votre base de données sous l'onglet **Resources**.

### Configuration de la base de données

Nous devons maintenant indiquer à notre application comment joindre la base de données. Depuis le répertoire racine de votre application, exécutez la commande suivante :

```bash
heroku config
```

Ce qui affichera quelque-chose de similaire à ceci :

```none
=== tutoriel-vapor Config Vars
DATABASE_URL: postgres://cybntsgadydqzm:2d9dc7f6d964f4750da1518ad71hag2ba729cd4527d4a18c70e024b11cfa8f4b@ec2-54-221-192-231.compute-1.amazonaws.com:5432/dfr89mvoo550b4
```

La variable **DATABASE_URL** représente notre base de données Postgres. Ne mettez **JAMAIS** la valeur de cette URL en dur dans votre code, car Heroku la change régulièrement, ce qui casserait donc votre application. C'est aussi une mauvaise pratique. Au lieu de ça, lisez la variable d'environnement lors de l'exécution.

L'option Postgres d'Heroku [nécessite](https://devcenter.heroku.com/changelog-items/2035) que toutes les connexions soient chiffrées. Les certificats utilisés par les serveurs Postgres sont internes à Heroku, ce qui oblige à configurer une connexion TLS **non-vérifiée**.

L'exemple suivant montre comment appliquer ces configurations :

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

Don't forget to commit these changes

```bash
git add .
git commit -m "Configuration BDD Heroku"
```

### Migrations

Vous pouvez exécuter des commandes sur Heroku avec `run`.

Pour appliquer des migrations :

```bash
heroku run App -- migrate --env production
```

Pour annuler des migrations :

```bash
heroku run App -- migrate --revert --all --yes --env production
```
