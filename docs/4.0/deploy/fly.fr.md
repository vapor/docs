# Fly

Fly est une plateforme d'hébergement qui permet d'exécuter des applications serveur et des bases de données en mettant l'accent sur l'edge computing. Consultez [leur site web](https://fly.io/) pour plus d'informations.

!!! note
    Les commandes indiquées dans ce document sont soumises à la [tarification de Fly](https://fly.io/docs/about/pricing/), assurez-vous de bien la comprendre avant de continuer.

## S'inscrire
Si vous n'avez pas de compte, vous devrez en [créer un](https://fly.io/app/sign-up).

## Installer flyctl
La principale façon d'interagir avec Fly est d'utiliser l'outil CLI dédié, `flyctl`, que vous devrez installer.

### macOS
```bash
brew install flyctl
```

### Linux
```bash
curl -L https://fly.io/install.sh | sh
```

### Autres options d'installation
Pour plus d'options et de détails, consultez [la documentation d'installation de `flyctl`](https://fly.io/docs/flyctl/install/).

## Se connecter
Pour vous connecter depuis votre terminal, exécutez la commande suivante :
```bash
fly auth login
```

## Configurer votre projet Vapor
Avant de déployer sur Fly, vous devez vous assurer d'avoir un projet Vapor avec un `Dockerfile` correctement configuré, car il est requis par Fly pour construire votre application. Dans la plupart des cas, cela devrait être très simple puisque les modèles Vapor par défaut en contiennent déjà un.

### Nouveau projet Vapor
Le moyen le plus simple de créer un nouveau projet est de partir d'un modèle. Vous pouvez en créer un en utilisant les modèles GitHub ou la Vapor toolbox. Si vous avez besoin d'une base de données, il est recommandé d'utiliser Fluent avec Postgres ; Fly facilite la création d'une base de données Postgres pour connecter vos applications (voir la [section dédiée](#configurer-postgres) ci-dessous).

#### Utiliser la Vapor toolbox
Assurez-vous d'abord d'avoir installé la Vapor toolbox (voir les instructions d'installation pour [macOS](../install/macos.md#installer-la-toolbox) ou [Linux](../install/linux.md#installer-la-toolbox)).
Créez votre nouvelle application avec la commande suivante, en remplaçant `app-name` par le nom d'application de votre choix :
```bash
vapor new app-name
```

Cette commande affichera un prompt interactif qui vous permettra de configurer votre projet Vapor ; c'est ici que vous pouvez sélectionner Fluent et Postgres si vous en avez besoin.

#### Utiliser les modèles GitHub
Choisissez le modèle qui correspond le mieux à vos besoins dans la liste suivante. Vous pouvez soit le cloner localement avec Git, soit créer un projet GitHub avec le bouton « Use this template ».

- [Modèle Barebones](https://github.com/vapor/template-bare)
- [Modèle Fluent/Postgres](https://github.com/vapor/template-fluent-postgres)
- [Modèle Fluent/Postgres + Leaf](https://github.com/vapor/template-fluent-postgres-leaf)

### Projet Vapor existant
Si vous avez un projet Vapor existant, assurez-vous d'avoir un `Dockerfile` correctement configuré présent à la racine de votre dossier ; la [documentation Vapor sur l'utilisation de Docker](../deploy/docker.md) et la [documentation Fly sur le déploiement d'une application via un Dockerfile](https://fly.io/docs/languages-and-frameworks/dockerfile/) pourraient vous être utiles.

## Lancer votre application sur Fly
Une fois votre projet Vapor prêt, vous pouvez le lancer sur Fly.

Assurez-vous d'abord que votre dossier courant est le dossier racine de votre application Vapor, puis exécutez la commande suivante :
```bash
fly launch
```

Cela démarrera un prompt interactif pour configurer les paramètres de votre application Fly :

- **Name :** vous pouvez en saisir un ou laisser vide pour obtenir un nom généré automatiquement.
- **Region :** la valeur par défaut est celle la plus proche de vous. Vous pouvez choisir de l'utiliser ou n'importe quelle autre dans la liste. Ce paramètre est facile à modifier plus tard.
- **Database :** vous pouvez demander à Fly de créer une base de données à utiliser avec votre application. Si vous préférez, vous pouvez toujours faire de même plus tard avec les commandes `fly pg create` et `fly pg attach` (voir la [section Configurer Postgres](#configurer-postgres) pour plus de détails).

La commande `fly launch` crée automatiquement un fichier `fly.toml`. Il contient des paramètres tels que les mappings de ports privés/publics, les paramètres de health checks, et bien d'autres. Si vous venez de créer un nouveau projet depuis zéro avec `vapor new`, le fichier `fly.toml` par défaut n'a besoin d'aucune modification. Si vous avez un projet existant, il y a de bonnes chances que `fly.toml` convienne également sans modification ou avec des modifications mineures seulement. Vous trouverez plus d'informations dans [la documentation de `fly.toml`](https://fly.io/docs/reference/configuration/).

Notez que si vous demandez à Fly de créer une base de données, vous devrez attendre un peu qu'elle soit créée et passe les health checks.

Avant de se terminer, la commande `fly launch` vous demandera si vous souhaitez déployer votre application immédiatement. Vous pouvez accepter ou le faire plus tard avec `fly deploy`.

!!! tip
    Lorsque votre dossier courant se trouve à la racine de votre application, l'outil CLI fly détecte automatiquement la présence d'un fichier `fly.toml` qui permet à Fly de savoir quelle application vos commandes ciblent. Si vous souhaitez cibler une application spécifique quel que soit votre dossier courant, vous pouvez ajouter `-a name-of-your-app` à la plupart des commandes Fly.

## Déployer
Vous exécutez la commande `fly deploy` chaque fois que vous devez déployer de nouvelles modifications sur Fly.

Fly lit les fichiers `Dockerfile` et `fly.toml` de votre dossier pour déterminer comment construire et exécuter votre projet Vapor.

Une fois votre conteneur construit, Fly en démarre une instance. Il exécutera divers health checks, s'assurant que votre application fonctionne correctement et que votre serveur répond aux requêtes. La commande `fly deploy` se termine avec une erreur si les health checks échouent.

Par défaut, Fly reviendra à la dernière version fonctionnelle de votre application si les health checks échouent pour la nouvelle version que vous avez tenté de déployer.

Lors du déploiement d'un worker en arrière-plan (avec Vapor Queues), ne modifiez pas le `CMD` ou l'`ENTRYPOINT` dans votre Dockerfile ; laissez-le tel quel afin que l'application web principale démarre normalement. Ajoutez plutôt une section `[processes]` dans votre fichier fly.toml comme ceci :

```
[processes]
  app = ""
  worker = "queues"
```

Cela indique à Fly.io d'exécuter le processus `app` avec le point d'entrée Docker par défaut (votre serveur web), et le processus `worker` pour exécuter votre file d'attente de tâches à l'aide de l'interface en ligne de commande de Vapor (c'est-à-dire, `swift run App queues`).

## Configurer Postgres

### Créer une base de données Postgres sur Fly
Si vous n'avez pas créé d'application de base de données lors du lancement initial de votre application, vous pouvez le faire plus tard avec :
```bash
fly pg create
```

Cette commande crée une application Fly capable d'héberger des bases de données disponibles pour vos autres applications sur Fly, consultez la [documentation Fly dédiée](https://fly.io/docs/postgres/) pour plus de détails.

Une fois votre application de base de données créée, rendez-vous dans le dossier racine de votre application Vapor et exécutez :
```bash
fly pg attach name-of-your-postgres-app
```
Si vous ne connaissez pas le nom de votre application Postgres, vous pouvez le trouver avec `fly pg list`.

La commande `fly pg attach` crée une base de données et un utilisateur destinés à votre application, puis les expose à votre application via la variable d'environnement `DATABASE_URL`.

!!! note
    La différence entre `fly pg create` et `fly pg attach` est que la première alloue et configure une application Fly capable d'héberger des bases de données Postgres, tandis que la seconde crée une base de données et un utilisateur réels destinés à l'application de votre choix. Pour peu que cela réponde à vos besoins, une seule application Fly Postgres pourrait héberger plusieurs bases de données utilisées par diverses applications. Lorsque vous demandez à Fly de créer une application de base de données dans `fly launch`, cela revient à appeler à la fois `fly pg create` et `fly pg attach`.

### Connecter votre application Vapor à la base de données
Une fois votre application attachée à votre base de données, Fly définit la variable d'environnement `DATABASE_URL` avec l'URL de connexion contenant vos identifiants (elle doit être traitée comme une information sensible).

Avec la plupart des configurations de projets Vapor courantes, vous configurez votre base de données dans `configure.swift`. Voici comment vous pourriez procéder :

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    try app.databases.use(.postgres(url: databaseURL), as: .psql)
} else {
    // Handle missing DATABASE_URL here...
    //
    // Alternatively, you could also set a different config 
    // depending on wether app.environment is set to to 
    // `.development` or `.production`
}
```

À ce stade, votre projet devrait être prêt à exécuter les migrations et à utiliser la base de données.

### Exécuter les migrations
Avec `release_command` de `fly.toml`, vous pouvez demander à Fly d'exécuter une certaine commande avant de démarrer votre processus serveur principal. Ajoutez ceci à `fly.toml` :
```toml
[deploy]
 release_command = "migrate -y"
```

!!! note
    L'extrait de code ci-dessus suppose que vous utilisez le Dockerfile Vapor par défaut, qui définit l'`ENTRYPOINT` de votre application à `./App`. Concrètement, cela signifie que lorsque vous définissez `release_command` à `migrate -y`, Fly appellera `./App migrate -y`. Si votre `ENTRYPOINT` est défini à une valeur différente, vous devrez adapter la valeur de `release_command`.

Fly exécutera votre commande de release dans une instance temporaire ayant accès à votre réseau Fly interne, à vos secrets et à vos variables d'environnement.

Si votre commande de release échoue, le déploiement ne continuera pas.

### Autres bases de données
Bien que Fly facilite la création d'une application de base de données Postgres, il est possible d'héberger d'autres types de bases de données également (voir par exemple [« Use a MySQL database »](https://fly.io/docs/app-guides/mysql-on-fly/) dans la documentation Fly).

## Secrets et variables d'environnement
### Secrets
Utilisez les secrets pour définir toute valeur sensible en tant que variable d'environnement.
```bash
 fly secrets set MYSECRET=A_SUPER_SECRET_VALUE
```

!!! warning
    Gardez à l'esprit que la plupart des shells conservent un historique des commandes que vous avez tapées. Soyez prudent à ce sujet lorsque vous définissez des secrets de cette façon. Certains shells peuvent être configurés pour ne pas mémoriser les commandes préfixées par un espace. Voir aussi la commande [`fly secrets import`](https://fly.io/docs/flyctl/secrets-import/).

Pour plus d'informations, consultez la [documentation de `fly secrets`](https://fly.io/docs/apps/secrets/).

### Variables d'environnement
Vous pouvez définir d'autres [variables d'environnement](https://fly.io/docs/reference/configuration/#the-env-variables-section) non sensibles dans `fly.toml`, par exemple :
```toml
[env]
  MAX_API_RETRY_COUNT = "3"
  SMS_LOG_LEVEL = "error"
```

## Connexion SSH
Vous pouvez vous connecter aux instances d'une application en utilisant :
```bash
fly ssh console -s
```

## Consulter les logs
Vous pouvez consulter les logs en direct de votre application en utilisant :
```bash
fly logs
```

## Prochaines étapes
Maintenant que votre application Vapor est déployée, il y a bien plus de choses que vous pouvez faire, comme mettre à l'échelle vos applications verticalement et horizontalement sur plusieurs régions, ajouter des volumes persistants, mettre en place le déploiement continu, ou même créer des clusters d'applications distribués. Le meilleur endroit pour apprendre à faire tout cela et bien plus encore est la [documentation Fly](https://fly.io/docs/).
