# Déployer sur Fly

Fly est un hébergeur qui se spécialise en Edge-Computing. Visitez [leur site web](https://fly.io/) pour plus d'informations.

!!! Note
    Les commandes indiquées sur cette page sont soumises à la [tarification Fly](https://fly.io/docs/about/pricing/), assurez-vous d'en prendre correctement connaissance avant de poursuivre.

## Créer un compte

Si vous n'avez pas déjà un compte, vous devrez en [créer un](https://fly.io/app/sign-up).

## Installation de flyctl

Votre principale interface avec Fly est leur outil en lignes de commandes, `flyctl`, que vous devrez installer.

### macOS

```bash
brew install flyctl
```

### Linux

```bash
curl -L https://fly.io/install.sh | sh
```

### Autres options d'installation

Pour plus d'options et détails, consultez la [documentation d'installation de `flyctl`](https://fly.io/docs/flyctl/install/).

## Connexion

Pour vous connecter depuis votre terminal, lancez la commande suivante :
```bash
fly auth login
```

## Configuration d'un projet Vapor

Avant de déployer sur Fly, vous devez avoir un projet Vapor avec un Dockerfile correctement configuré, Fly en aura besoin pour compiler votre application. Dans la plupart des cas, cela devrait être facile puisque les projets Vapor en contiennent déjà un par défaut.

### Nouveau projet Vapor

Le moyen le plus simple pour démarrer un nouveau projet est d'utiliser un modèle de démarrage. Vous pouvez utiliser un des modèles proposés sur nos dépots GitHub vapor/template-* ou la toolbox Vapor. Si vous avez besoin d'une base de données, nous recommandons d'utiliser Fluent avec Postgres; Fly facilite la création de BDD Postgres et leur connexion (voir la [section dédiée](#configuration-de-postgres) plus base).

#### Avec la toolbox Vapor

Tout d'abord, assurez-vous d'avoir installé la toolbox Vapor (voir les instructions d'installation pour [macOS](../install/macos.md#installer-la-toolbox) ou [Linux](../install/linux.md#installer-la-toolbox)).
Créez votre nouvelle application avec la commande suivante, en remplaçant `mon-appli` par le nom que vous voulez donner à votre application :

```bash
vapor new mon-appli
```

Cette commande lancera une interface interactive qui vous aidera à configurer votre projet Vapor, et vous pourrez choisir d'utiliser Fluent et Postgres si vous en avez besoin.

#### Avec les modèles GitHub

Choisissez le modèle le plus adapté à vos besoins parmi les options suivantes. Vous pouvez utiliser Git pour le cloner localement ou créer un projet GitHub grâce au bouton "Use this template".

- [Modèle minimal](https://github.com/vapor/template-bare)
- [Modèle minimal avec Fluent/Postgres](https://github.com/vapor/template-fluent-postgres)
- [Modèle minimal avec Fluent/Postgres et Leaf](https://github.com/vapor/template-fluent-postgres-leaf)

### Projet Vapor existant

Si vous avez déjà un projet Vapor, assurez-vous d'avoir un `Dockerfile` correctement configuré à sa racine; La [documentation Vapor sur l'usage de Docker](../deploy/docker.md) et [celles de Fly sur le déploiement via Dockerfile](https://fly.io/docs/languages-and-frameworks/dockerfile/) pourraient vous servir.

## Exécuter votre application sur Fly

Une fois votre projet Vapor prêt, vous pouvez l'exécuter sur Fly.

Tout d'abord, assurez-vous que votre répertoire de travail actuel soit la racine de votre projet Vapor et lancez cette commande :

```bash
fly launch
```

Cela lancera une interface interactive pour configurer votre application Fly :

- **Name :** vous pouvez choisir un nom ou laisser vide, ce qui en génèrera un aléatoire.
- **Region :** par défaut, la région la plus proche de vous sera sélectionnée. Vous pouvez en choisir une dans la liste. Vous pourrez facilement la changer plus tard.
- **Database :** vous pouvez demander à Fly de créer une base de données pour votre application. Si vous préférez, vous pourrez aussi le faire plus tard avec les commandes `fly pg create` et `fly pg attach` (voir la [section Configuration de Postgres](#configuration-de-postgres) pour plus de détails).

La commande `fly launch` crée automatiquement un fichier `fly.toml`. Celui-ci contient des configurations comme le mappage des ports privés/publiques, les tests d'état de santé, et plusieurs autres. Si vous venez juste de créer un nouveau projet via la commande `vapor new`, le fichier `fly.toml` par défaut n'a pas besoin d'être modifié. Si vous aviez un projet existant, il est possible que le fichier `fly.toml` soit bon aussi, sans changement nécessaire, ou changements minimes. Vous trouverez plus d'informations dans la [documentation sur le fichier `fly.toml`](https://fly.io/docs/reference/configuration/).

Notez que si vous demandez à Fly de créer une base de données, vous devrez patienter un peu le temps de sa création et des vérifications d'état de santé.

Avant de terminer, la commande `fly launch` vous demandera si vous souhaitez déployer votre application dans la foulée. Vous pouvez accepter ou le faire plus tard par la commande `fly deploy`.

!!! Astuce
    Quand votre répertoire de travail courant est à la racine de votre projet, l'outil CLI de Fly détecte automatiquement la présence du fichier `fly.toml` qui permet à Fly de connaître l'application ciblée par vos commandes. Si vous souhaitez cibler une application spécifique sans tenir compte de votre répertoire de travail, vous pouvez ajouter `-a nom-de-votre-appli` à la plupart des commandes Fly.

## Déployer

Vous pouvez exécuter la commande `fly deploy` pour toute modification que vous souhaitez déployer sur Fly.

Fly consultera les fichiers `Dockerfile` et `fly.toml` de votre projet pour savoir comment compiler et exécuter votre application Vapor.

Une fois votre conteneur construit, Fly en démarre une instance. Il procèdera à différents tests de santé, pour s'assurer que votre application tourne bien et que votre serveur répond aux requêtes. La commande `fly deploy` termine en erreur en cas d'échec de ces tests.

Par défaut, si un test d'état est en échec lors de votre tentative de déploiement, Fly procèdera à une restauration de votre application dans sa version précédente.

Si vous déployez un Worker de tâche de fond (avec Vapor Queues), ne modifiez ni CMD ni ENTRYPOINT de votre Dockerfile; laissez les valeurs par défaut pour que l'application web principal démarre normalement. En revanche, ajoutez une section [processes] à votre fichier fly.toml comme ceci :

```
[processes]
  app = ""
  worker = "queues"
```

Cela indique à Fly.io qu'il faut lancer le processus applicatif avec le point d'entrée Docker par défaut (votre serveur web), et le processus du Worker qui traitera vos files d'attentes avec les CLI Vapor (ie, `swift run App queues`).

## Configuration de Postgres

### Créer une base de données Postgres sur Fly

Si vous n'avez pas créé de base de données au premier lancement de votre application, vous pouvez le faire plus tard avec la commande suivante :

```bash
fly pg create
```

Cette commande crée une application Fly qui pourra héberger des bases de données disponibles pour vos autres applications Fly. Consultez la [documentation Fly dédiée](https://fly.io/docs/postgres/) pour plus de détails.

Une fois que votre application de base de données est créée, allez dans le répertoire racine de votre application Vapor et exécutez la commande suivante :

```bash
fly pg attach nom-de-votre-appli-postgres
```

Si vous ne connaissez pas le nom de votre application Postgres, vous pouvez le trouver via `fly pg list`.

La commande `fly pg attach` crée une base de données avec un utilisateur prévu pour votre application, puis l'expose via la variable d'environnement `DATABASE_URL`. 

!!! Note
    La différence entre `fly pg create` et `fly pg attach` est que la première commande crée et configure une application Fly capable d'héberger une base de données Postgres, alors que la dernière crée une vraie base de données (avec son utilisateur) destinée à l'application de votre choix. Si vous en avez besoin, une seule application Postgres Fly peut héberger plusieurs bases de données utilisées par différentes applications. Lorsque vous demandez à Fly de créer une application de base de données avec `fly launch`, il exécute un équivalent des commandes `fly pg create` et `fly pg attach`.

### Connecter votre application Vapor à la base de données

Une fois votre application attachée à votre base de données, Fly définit la variable d'environnement `DATABASE_URL` avec l'URL de connexion contenant les données d'identification (considérez-la comme une information sensible).

Pour la plupart des projets Vapor, la configuration de la base de données se fait dans le fichier `configure.swift`. Voici un exemple de comment vous pourriez faire :

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    try app.databases.use(.postgres(url: databaseURL), as: .psql)
} else {
    // Gestion du cas où DATABASE_URL n'est pas défini...
    //
    // Vous pourriez aussi définir une configuration différente
    // en fonction de la valeur de app.environment qui pourrait valoir 
    // `.development` ou `.production`
}
```

Maintenant, votre projet devrait pouvoir exécuter des migrations et utiliser la base de données.

### Lancer des migrations

Avec l'instruction `release_command` du fichier `fly.toml`, vous pouvez demander à Fly d'exécuter certaines commandes avant l'exécution du processus principal de votre serveur. Ajoutez ceci au fichier `fly.toml` :

```toml
[deploy]
 release_command = "migrate -y"
```

!!! Note
    L'exemple ci-dessus suppose que vous utilisiez le Dockerfile Vapor par défaut, qui définit la valeur `ENTRYPOINT` de votre application à `./App`. Concrètement, cela signifie que lorsque vous définissez `release_command` à `migrate -y`, Fly exécutera `./App migrate -y`. Si votre `ENTRYPOINT` est défini sur une valeur différente, vous devrez adapter la valeur de `release_command`.

Fly exécutera cette commande de mise en production sur une instance temporaire ayant accès à votre réseau Fly interne, secrets, et variables d'environnement.

Si votre commande de mise en production échoue, le déploiement s'arrêtera.

### Autres bases de données

Bien que Fly facilite la création d'applications de bases de données Postgres, il est aussi possible d'héberger d'autres bases de données (par exemple, voir l'article ["Use a MySQL database"](https://fly.io/docs/app-guides/mysql-on-fly/) de la documentation Fly).

## Secrets et variables d'environnement

### Secrets

Utilisez des secrets pour stoquer toute valeur sensible en variables d'environnement.
```bash
 fly secrets set MONSECRET=UNE_VALEUR_SENSIBLE_À_GARDER_SECRÈTE
```

!!! Attention
    Gardez à l'esprit que la plupart des shells conservent un historique des commandes que vous avez écrites. Soyez prudent lorsque vous définissez des secrets de cette façon. Certains shells peuvent être configurés pour oublier les commandes qui commencent par un espace. Vous pouvez aussi voir la [commande `fly secrets import`](https://fly.io/docs/flyctl/secrets-import/).

Pour plus d'informations, lisez la [documentation sur les `secrets fly`](https://fly.io/docs/apps/secrets/).

### Variables d'environnement

Vous pouvez définir d'autres [variables d'environnement dans `fly.toml`](https://fly.io/docs/reference/configuration/#the-env-variables-section) pour les informations non sensibles, par exemple :

```toml
[env]
  MAX_API_RETRY_COUNT = "3"
  SMS_LOG_LEVEL = "error"
```

## Connexion SSH

Vous pouvez vous connecter aux instances de vos applications avec la commande suivante :

```bash
fly ssh console -s
```

## Accès aux logs

Vous pouvez afficher les logs en direct de votre application avec la commande suivante :

```bash
fly logs
```

## Pour aller plus loin

Une fois votre application Vapor déployée, vous pouvez encore faire de nombreuses choses, telle que la mise à l'échelle de votre application de façon verticale et horizontale sur différentes régions, ajouter des volumes persistants, configurer le déploiement continu, ou même créer des clusters applicatifs distribués. Le meilleur endroit pour apprendre à faire tout ça et même plus est la [documentation Fly](https://fly.io/docs/).
