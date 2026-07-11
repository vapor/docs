# Qu'est-ce que Heroku

Heroku est une solution d'hébergement tout-en-un très populaire, vous pouvez en apprendre plus sur [heroku.com](https://www.heroku.com)

## Inscription

Vous aurez besoin d'un compte heroku, si vous n'en avez pas, veuillez vous inscrire ici : [https://signup.heroku.com/](https://signup.heroku.com/)

## Installation de la CLI

Assurez-vous d'avoir installé l'outil en ligne de commande heroku.

### HomeBrew

```bash
brew tap heroku/brew && brew install heroku
```

### Autres options d'installation

Consultez les autres options d'installation ici : [https://devcenter.heroku.com/articles/heroku-cli#download-and-install](https://devcenter.heroku.com/articles/heroku-cli#download-and-install).

### Connexion

Une fois la CLI installée, connectez-vous avec la commande suivante :

```bash
heroku login
```

Vérifiez que le bon email est connecté avec :

```bash
heroku auth:whoami
```

### Créer une application

Rendez-vous sur dashboard.heroku.com pour accéder à votre compte, et créez une nouvelle application depuis le menu déroulant en haut à droite. Heroku vous posera quelques questions comme la région et le nom de l'application, il vous suffit de suivre les instructions.

### Git

Heroku utilise Git pour déployer votre application, vous devez donc placer votre projet dans un dépôt Git, si ce n'est pas déjà fait.

#### Initialiser Git

Si vous devez ajouter Git à votre projet, entrez la commande suivante dans le terminal :

```bash
git init
```

#### Main

Vous devriez choisir une branche et vous y tenir pour déployer sur Heroku, comme la branche **main** ou **master**. Assurez-vous que tous les changements sont validés (commit) dans cette branche avant de la pousser (push).

Vérifiez votre branche actuelle avec :

```bash
git branch
```

L'astérisque indique la branche actuelle.

```bash
* main
  commander
  other-branches
```

!!! note 
    Si vous ne voyez aucune sortie et que vous venez d'exécuter `git init`. Vous devrez d'abord valider (commit) votre code, puis vous verrez la sortie de la commande `git branch`.

Si vous n'êtes _pas_ actuellement sur la bonne branche, basculez-y en entrant (pour **main**) :

```bash
git checkout main
```

#### Valider les changements

Si cette commande produit une sortie, alors vous avez des changements non validés (commit).

```bash
git status --porcelain
```

Validez-les (commit) avec la commande suivante

```bash
git add .
git commit -m "a description of the changes I made"
```

#### Connecter à Heroku

Connectez votre application à heroku (remplacez par le nom de votre application).

```bash
$ heroku git:remote -a your-apps-name-here
```

### Définir le buildpack

Définissez le buildpack pour indiquer à heroku comment traiter vapor.

```bash
heroku buildpacks:set vapor/vapor
```

### Fichier de version Swift

Le buildpack que nous avons ajouté recherche un fichier **.swift-version** pour connaître la version de swift à utiliser. (Remplacez 5.8.1 par la version requise par votre projet.)

```bash
echo "5.8.1" > .swift-version
```

Ceci crée **.swift-version** avec `5.8.1` comme contenu.

### Procfile

Heroku utilise le **Procfile** pour savoir comment lancer votre application, dans notre cas il doit ressembler à ceci :

```
web: App serve --env production --hostname 0.0.0.0 --port $PORT
```

Nous pouvons le créer avec la commande de terminal suivante

```bash
echo "web: App serve --env production" \
  "--hostname 0.0.0.0 --port \$PORT" > Procfile
```

### Valider les changements

Nous venons d'ajouter ces fichiers, mais ils ne sont pas validés (commit). Si nous poussons (push), heroku ne les trouvera pas.

Validez-les (commit) avec la commande suivante.

```bash
git add .
git commit -m "adding heroku build files"
```

### Déployer sur Heroku

Vous êtes prêt à déployer, lancez ceci depuis le terminal. La construction peut prendre du temps, c'est normal.

```bash
git push heroku main
```

### Monter en charge (Scale Up)

Une fois la construction réussie, vous devez ajouter au moins un serveur. Les prix commencent à 5$/mois pour le plan Eco (voir [pricing](https://www.heroku.com/pricing#containers)), assurez-vous d'avoir configuré un moyen de paiement sur Heroku. Ensuite, pour un seul worker web :

```bash
heroku ps:scale web=1
```

### Déploiement continu

Chaque fois que vous souhaitez mettre à jour, il suffit d'intégrer les derniers changements dans main et de les pousser (push) vers heroku, qui redéploiera automatiquement.

## Postgres

### Ajouter une base de données PostgreSQL

Rendez-vous sur votre application depuis dashboard.heroku.com et allez dans la section **Add-ons**.

Là, saisissez `postgres` et vous verrez une option pour `Heroku Postgres`. Sélectionnez-la.

Choisissez le plan Essential 0 à 5$/mois (voir [pricing](https://www.heroku.com/pricing#data-services)), et provisionnez. Heroku s'occupe du reste.

Une fois terminé, vous verrez la base de données apparaître sous l'onglet **Resources**.

### Configurer la base de données

Nous devons maintenant indiquer à notre application comment accéder à la base de données. Dans le répertoire de notre application, exécutons :

```bash
heroku config
```

Cela produira une sortie ressemblant à ceci

```none
=== today-i-learned-vapor Config Vars
DATABASE_URL: postgres://cybntsgadydqzm:2d9dc7f6d964f4750da1518ad71hag2ba729cd4527d4a18c70e024b11cfa8f4b@ec2-54-221-192-231.compute-1.amazonaws.com:5432/dfr89mvoo550b4
```

**DATABASE_URL** représente ici notre base de données postgres. Ne codez **JAMAIS** en dur l'URL statique fournie ici, heroku la fera tourner (rotate) et cela cassera votre application. C'est aussi une mauvaise pratique. Lisez plutôt la variable d'environnement au moment de l'exécution.

L'addon Heroku Postgres [exige](https://devcenter.heroku.com/changelog-items/2035) que toutes les connexions soient chiffrées. Les certificats utilisés par les serveurs Postgres sont internes à Heroku, une connexion TLS **non vérifiée** doit donc être mise en place.

L'extrait suivant montre comment faire les deux :

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

N'oubliez pas de valider (commit) ces changements

```bash
git add .
git commit -m "configured heroku database"
```

### Annuler les migrations de votre base de données

Vous pouvez annuler des migrations ou exécuter d'autres commandes sur heroku avec la commande `run`.

Pour annuler les migrations de votre base de données :

```bash
heroku run App -- migrate --revert --all --yes --env production
```

Pour migrer :

```bash
heroku run App -- migrate --env production
```
