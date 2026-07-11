# Déploiements Docker

Utiliser Docker pour déployer votre application Vapor présente plusieurs avantages :

1. Votre application dockerisée peut être démarrée de manière fiable en utilisant les mêmes commandes sur toute plateforme disposant d'un Docker Daemon -- à savoir Linux (CentOS, Debian, Fedora, Ubuntu), macOS et Windows.
2. Vous pouvez utiliser docker-compose ou des manifestes Kubernetes pour orchestrer les multiples services nécessaires à un déploiement complet (par exemple Redis, Postgres, nginx, etc.).
3. Il est facile de tester la capacité de votre application à monter en charge horizontalement, même localement sur votre machine de développement.

Ce guide n'expliquera pas en détail comment déployer votre application dockerisée sur un serveur. Le déploiement le plus simple consisterait à installer Docker sur votre serveur et à exécuter les mêmes commandes que celles utilisées sur votre machine de développement pour démarrer votre application.

Les déploiements plus complets et robustes varient généralement selon votre solution d'hébergement ; de nombreuses solutions populaires comme AWS offrent un support natif pour Kubernetes et des solutions de base de données personnalisées, ce qui rend difficile de rédiger des bonnes pratiques applicables à tous les déploiements.

Néanmoins, utiliser Docker pour démarrer localement l'ensemble de votre stack serveur à des fins de test est extrêmement précieux, aussi bien pour les grandes que pour les petites applications côté serveur. De plus, les concepts décrits dans ce guide s'appliquent, à grands traits, à tous les déploiements Docker.

## Mise en place

Vous devrez configurer votre environnement de développement pour exécuter Docker et acquérir une compréhension de base des fichiers de ressources qui configurent les stacks Docker.

### Installer Docker

Vous devrez installer Docker pour votre environnement de développement. Vous trouverez des informations pour toute plateforme dans la section [Plateformes supportées](https://docs.docker.com/install/#supported-platforms) de la vue d'ensemble de Docker Engine. Si vous êtes sur Mac OS, vous pouvez aller directement à la page d'installation de [Docker pour Mac](https://docs.docker.com/docker-for-mac/install/).

### Générer un modèle

Nous vous suggérons d'utiliser le modèle Vapor comme point de départ. Si vous avez déjà une application, générez le modèle comme décrit ci-dessous dans un nouveau dossier comme point de référence pendant que vous dockerisez votre application existante -- vous pouvez copier les ressources clés du modèle vers votre application et les ajuster légèrement comme base de travail.

1. Installez ou compilez la Vapor Toolbox ([macOS](../install/macos.md#installer-la-toolbox), [Linux](../install/linux.md#installer-la-toolbox)).
2. Créez une nouvelle application Vapor avec `vapor new my-dockerized-app` et suivez les questions pour activer ou désactiver les fonctionnalités concernées. Vos réponses à ces questions affecteront la façon dont les fichiers de ressources Docker seront générés.

## Ressources Docker

Il est utile, maintenant ou dans un futur proche, de vous familiariser avec la [vue d'ensemble de Docker](https://docs.docker.com/engine/docker-overview/). Cette vue d'ensemble explique une partie de la terminologie clé utilisée dans ce guide.

Le modèle d'application Vapor comporte deux ressources Docker essentielles : un **Dockerfile** et un fichier **docker-compose**.

### Dockerfile

Un Dockerfile indique à Docker comment construire une image de votre application dockerisée. Cette image contient à la fois l'exécutable de votre application et toutes les dépendances nécessaires à son exécution. La [référence complète](https://docs.docker.com/engine/reference/builder/) mérite d'être gardée ouverte lorsque vous personnalisez votre Dockerfile.

Le Dockerfile généré pour votre application Vapor comporte deux étapes. La première étape construit votre application et met en place une zone de stockage temporaire contenant le résultat. La deuxième étape met en place les bases d'un environnement d'exécution sécurisé, transfère tout le contenu de la zone de stockage temporaire vers son emplacement final dans l'image, et définit un point d'entrée et une commande par défaut qui exécuteront votre application en mode production sur le port par défaut (8080). Cette configuration peut être surchargée lorsque l'image est utilisée.

### Fichier Docker Compose

Un fichier Docker Compose définit la façon dont Docker doit construire plusieurs services les uns par rapport aux autres. Le fichier Docker Compose du modèle d'application Vapor fournit les fonctionnalités nécessaires pour déployer votre application, mais si vous souhaitez en apprendre davantage, consultez la [référence complète](https://docs.docker.com/compose/compose-file/) qui détaille toutes les options disponibles.

!!! note
    Si vous prévoyez finalement d'utiliser Kubernetes pour orchestrer votre application, le fichier Docker Compose n'est pas directement pertinent. Cependant, les fichiers de manifeste Kubernetes sont conceptuellement similaires et il existe même des projets visant à [porter les fichiers Docker Compose](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/) vers des manifestes Kubernetes.

Le fichier Docker Compose de votre nouvelle application Vapor définira des services pour exécuter votre application, exécuter des migrations ou les annuler, et exécuter une base de données comme couche de persistance de votre application. Les définitions exactes varieront selon la base de données que vous avez choisie lors de l'exécution de `vapor new`.

Notez que votre fichier Docker Compose contient des variables d'environnement partagées près du début. (Vous pourriez avoir un ensemble différent de variables par défaut selon que vous utilisez Fluent ou non, et selon le driver Fluent utilisé le cas échéant.)

```docker
x-shared_environment: &shared_environment
  LOG_LEVEL: ${LOG_LEVEL:-debug}
  DATABASE_HOST: db
  DATABASE_NAME: vapor_database
  DATABASE_USERNAME: vapor_username
  DATABASE_PASSWORD: vapor_password
```

Vous verrez ces variables réutilisées dans plusieurs services ci-dessous grâce à la syntaxe de référence YAML `<<: *shared_environment`.

Les variables `DATABASE_HOST`, `DATABASE_NAME`, `DATABASE_USERNAME` et `DATABASE_PASSWORD` sont codées en dur dans cet exemple, tandis que `LOG_LEVEL` prendra sa valeur depuis l'environnement exécutant le service, ou reviendra à `'debug'` si cette variable n'est pas définie.

!!! note
    Coder en dur le nom d'utilisateur et le mot de passe est acceptable pour le développement local, mais vous devriez stocker ces variables dans un fichier de secrets pour un déploiement en production. Une façon de gérer cela en production est d'exporter le fichier de secrets vers l'environnement exécutant votre déploiement et d'utiliser des lignes comme celle-ci dans votre fichier Docker Compose :

    ```
    DATABASE_USERNAME: ${DATABASE_USERNAME}
    ```

    Cela transmet la variable d'environnement aux conteneurs telle que définie par l'hôte.

Autres points à noter :

- Les dépendances entre services sont définies par des tableaux `depends_on`.
- Les ports des services sont exposés au système exécutant les services grâce à des tableaux `ports` (au format `<port_hôte>:<port_service>`).
- `DATABASE_HOST` est défini comme `db`. Cela signifie que votre application accèdera à la base de données via `http://db:5432`. Cela fonctionne parce que Docker va démarrer un réseau utilisé par vos services, et le DNS interne de ce réseau fera correspondre le nom `db` au service nommé `'db'`.
- La directive `CMD` du Dockerfile est surchargée dans certains services par le tableau `command`. Notez que ce qui est spécifié par `command` est exécuté par rapport à l'`ENTRYPOINT` du Dockerfile.
- En mode Swarm (plus de détails ci-dessous), les services se voient par défaut attribuer 1 instance, mais les services `migrate` et `revert` sont définis avec `deploy` `replicas: 0` afin qu'ils ne démarrent pas par défaut lors de l'exécution d'un Swarm.

## Construction

Le fichier Docker Compose indique à Docker comment construire votre application (en utilisant le Dockerfile du dossier courant) et comment nommer l'image résultante (`my-dockerized-app:latest`). Ce dernier est en réalité la combinaison d'un nom (`my-dockerized-app`) et d'un tag (`latest`), les tags étant utilisés pour versionner les images Docker.

Pour construire une image Docker pour votre application, exécutez

```shell
docker compose build
```

depuis le dossier racine du projet de votre application (le dossier contenant `docker-compose.yml`).

Vous constaterez que votre application et ses dépendances doivent être reconstruites même si vous les aviez déjà construites précédemment sur votre machine de développement. Elles sont construites dans l'environnement de build Linux utilisé par Docker, donc les artefacts de build de votre machine de développement ne sont pas réutilisables.

Une fois terminé, vous trouverez l'image de votre application en exécutant

```shell
docker image ls
```

## Exécution

Votre stack de services peut être exécutée directement depuis le fichier Docker Compose, ou vous pouvez utiliser une couche d'orchestration comme le mode Swarm ou Kubernetes.

### Autonome

La façon la plus simple d'exécuter votre application est de la démarrer comme un conteneur autonome. Docker utilisera les tableaux `depends_on` pour s'assurer que tous les services dépendants sont également démarrés.

Exécutez d'abord :

```shell
docker compose up app
```

et remarquez que les services `app` et `db` sont tous deux démarrés.

Votre application écoute sur le port 8080 et, comme défini par le fichier Docker Compose, elle est accessible sur votre machine de développement à l'adresse **http://localhost:8080**.

Cette distinction de mappage de port est très importante, car vous pouvez exécuter n'importe quel nombre de services sur les mêmes ports s'ils s'exécutent tous dans leurs propres conteneurs et exposent chacun des ports différents à la machine hôte.

Visitez `http://localhost:8080` et vous verrez `It works!`, mais visitez `http://localhost:8080/todos` et vous obtiendrez :

```
{"error":true,"reason":"Something went wrong."}
```

Jetez un œil aux logs affichés dans le terminal où vous avez exécuté `docker compose up app` et vous verrez :

```
[ ERROR ] relation "todos" does not exist
```

Bien sûr ! Nous devons exécuter les migrations sur la base de données. Appuyez sur `Ctrl+C` pour arrêter votre application. Nous allons redémarrer l'application, mais cette fois avec :

```shell
docker compose up --detach app
```

Maintenant votre application va démarrer « détachée » (en arrière-plan). Vous pouvez le vérifier en exécutant :

```shell
docker container ls
```

où vous verrez à la fois la base de données et votre application s'exécuter dans des conteneurs. Vous pouvez même consulter les logs en exécutant :

```shell
docker logs <container_id>
```

Pour exécuter les migrations, exécutez :

```shell
docker compose run migrate
```

Après l'exécution des migrations, vous pouvez visiter à nouveau `http://localhost:8080/todos` et vous obtiendrez une liste vide de todos au lieu d'un message d'erreur.

#### Niveaux de log

Rappelez-vous ci-dessus que la variable d'environnement `LOG_LEVEL` du fichier Docker Compose sera héritée de l'environnement où le service est démarré, si elle est disponible.

Vous pouvez démarrer vos services avec

```shell
LOG_LEVEL=trace docker-compose up app
```

pour obtenir des logs de niveau `trace` (le plus granulaire). Vous pouvez utiliser cette variable d'environnement pour définir la journalisation à [n'importe quel niveau disponible](../basics/logging.md#niveau-de-log).

#### Logs de tous les services

Si vous spécifiez explicitement votre service de base de données lorsque vous démarrez les conteneurs, vous verrez les logs à la fois de votre base de données et de votre application.

```shell
docker-compose up app db
```

#### Arrêter les conteneurs autonomes

Maintenant que vous avez des conteneurs qui s'exécutent « détachés » de votre shell hôte, vous devez leur demander de s'arrêter d'une manière ou d'une autre. Il est utile de savoir que n'importe quel conteneur en cours d'exécution peut être invité à s'arrêter avec

```shell
docker container stop <container_id>
```

mais la façon la plus simple d'arrêter ces conteneurs particuliers est

```shell
docker-compose down
```

#### Effacer la base de données

Le fichier Docker Compose définit un volume `db_data` pour persister votre base de données entre les exécutions. Il existe plusieurs façons de réinitialiser votre base de données.

Vous pouvez supprimer le volume `db_data` en même temps que vous arrêtez vos conteneurs avec

```shell
docker-compose down --volumes
```

Vous pouvez voir tous les volumes persistant actuellement des données avec `docker volume ls`. Notez que le nom du volume aura généralement un préfixe `my-dockerized-app_` ou `test_` selon que vous exécutiez en mode Swarm ou non.

Vous pouvez supprimer ces volumes un par un avec par exemple

```shell
docker volume rm my-dockerized-app_db_data
```

Vous pouvez également nettoyer tous les volumes avec

```shell
docker volume prune
```

Faites juste attention à ne pas supprimer accidentellement un volume contenant des données que vous vouliez conserver !

Docker ne vous permettra pas de supprimer des volumes actuellement utilisés par des conteneurs en cours d'exécution ou arrêtés. Vous pouvez obtenir une liste des conteneurs en cours d'exécution avec `docker container ls`, et vous pouvez voir également les conteneurs arrêtés avec `docker container ls -a`.

### Mode Swarm

Le mode Swarm est une interface facile à utiliser lorsque vous avez un fichier Docker Compose sous la main et que vous souhaitez tester comment votre application monte en charge horizontalement. Vous pouvez tout lire sur le mode Swarm dans les pages à partir de la [vue d'ensemble](https://docs.docker.com/engine/swarm/).

La première chose dont nous avons besoin est un nœud manager pour notre Swarm. Exécutez

```shell
docker swarm init
```

Ensuite, nous utiliserons notre fichier Docker Compose pour démarrer une stack nommée `'test'` contenant nos services

```shell
docker stack deploy -c docker-compose.yml test
```

Nous pouvons voir comment se comportent nos services avec

```shell
docker service ls
```

Vous devriez voir `1/1` réplicas pour vos services `app` et `db`, et `0/0` réplicas pour vos services `migrate` et `revert`.

Nous devons utiliser une commande différente pour exécuter les migrations en mode Swarm.

```shell
docker service scale --detach test_migrate=1
```

!!! note
    Nous venons de demander à un service de courte durée de monter à 1 réplica. Il montera en charge avec succès, s'exécutera, puis s'arrêtera. Cependant, cela le laissera avec `0/1` réplicas en cours d'exécution. Ce n'est pas un problème avant que nous voulions à nouveau exécuter des migrations, mais nous ne pouvons pas lui demander de « monter à 1 réplica » s'il y est déjà. Une particularité de cette configuration est que la prochaine fois que nous voudrons exécuter des migrations au sein du même runtime Swarm, nous devrons d'abord réduire le service à `0`, puis remonter à `1`.

Le bénéfice de tous ces efforts, dans le contexte de ce court guide, est que nous pouvons maintenant faire monter en charge notre application comme bon nous semble afin de tester comment elle gère la contention de base de données, les plantages, et plus encore.

Si vous souhaitez exécuter 5 instances de votre application simultanément, exécutez

```shell
docker service scale test_app=5
```

En plus d'observer Docker faire monter en charge votre application, vous pouvez vérifier que 5 réplicas sont bien en cours d'exécution en consultant à nouveau `docker service ls`.

Vous pouvez visualiser (et suivre) les logs de votre application avec

```shell
docker service logs -f test_app
```

#### Arrêter les services Swarm

Lorsque vous souhaitez arrêter vos services en mode Swarm, vous le faites en supprimant la stack que vous avez créée précédemment.

```shell
docker stack rm test
```

## Déploiements en production

Comme indiqué au début, ce guide n'entrera pas dans les détails du déploiement de votre application dockerisée en production, car le sujet est vaste et varie grandement selon le service d'hébergement (AWS, Azure, etc.), l'outillage (Terraform, Ansible, etc.) et l'orchestration (Docker Swarm, Kubernetes, etc.).

Cependant, les techniques que vous apprenez pour exécuter votre application dockerisée localement sur votre machine de développement sont largement transposables aux environnements de production. Une instance de serveur configurée pour exécuter le daemon Docker acceptera exactement les mêmes commandes.

Copiez les fichiers de votre projet sur votre serveur, connectez-vous en SSH au serveur, et exécutez une commande `docker-compose` ou `docker stack deploy` pour lancer les choses à distance.

Alternativement, définissez votre variable d'environnement locale `DOCKER_HOST` pour qu'elle pointe vers votre serveur et exécutez les commandes `docker` localement sur votre machine. Il est important de noter qu'avec cette approche, vous n'avez pas besoin de copier vos fichiers de projet sur le serveur, _mais_ vous devez héberger votre image Docker quelque part où votre serveur peut la récupérer.
