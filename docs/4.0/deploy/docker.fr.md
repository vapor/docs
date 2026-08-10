# Déployer avec Docker

Utiliser Docker pour déployer votre application Vapor vous offre plusieurs avantages : 

1. Votre application Dockerisée vous offrira des démarrages fiables en utilisant les mêmes commandes sur toute plateforme où Docker tourne -- pour les nommer, Linux (CentOS, Debian, Fedora, Ubuntu), macOS, et Windows.
2. Vous pourrez utiliser des manifestes docker-compose ou Kubernetes pour orchestrer les différents services nécessaires à un déploiement complet (par exemple Redis, Postgres, Nginx, etc.).
3. Vous pourrez aisément tester les capacités de votre application à se mettre à l'échelle de façon horizontale, même en local sur votre machine de développement.

Ce guide ne fera qu'expliquer comment envoyer votre application Dockerisée sur votre serveur. Le déploiement le plus simple nécessitera l'installation de Docker sur votre serveur, et l'exécution des mêmes commandes que vous lanceriez sur votre environnement de développement pour démarrer votre application. 

Les déploiements plus robustes et complexes diffèrent généralement en fonction de votre solution d'hébergement; plusieurs solutions populaires comme AWS offrent un support intégré de Kubernetes ainsi que des solutions de bases de données spécifiques qui rendent difficile la rédaction de bonnes pratiques qui pourraient s'appliquer à tous les déploiements. 

Néanmoins, utiliser Docker pour lancer toute votre stack serveur en local à des fins de tests apporte une réelle plus-value aussi bien pour les petites que pour les grosses applications serveur. De plus, les concepts décrits dans ce guide s'appliquent à tous les déploiements avec Docker.

## Préparation

Vous devrez configurer votre environnement de développement pour lancer Docker et avoir une compréhension basique des fichiers de ressources qui configurent les stacks Docker.

### Installer Docker

Vous devrez installer Docker sur votre environnement de développement. Vous trouverez des documentations pour n'importe quelle plateforme dans la section [Supported Platforms](https://docs.docker.com/install/#supported-platforms) de l'aperçu du moteur Docker. Si vous êtes sur macOS, vous pouvez directement aller à la page d'installation [Docker for Mac](https://docs.docker.com/docker-for-mac/install/).

### Générer un modèle

Nous vous suggérons d'utiliser le modèle de Vapor pour commencer. Si vous avez déjà une application, compilez le modèle comme décrit ci-dessous dans un nouveau dossier pour qu'il serve de référence pendant la Dockerisation de votre application existante -- vous pouvez copier les ressources clés du modèle dans votre application et les modifier petit à petit pour commencer.

1. Installez ou compilez la Toolbox Vapor ([macOS](../install/macos.md#installer-la-toolbox), [Linux](../install/linux.md#installer-la-toolbox)).
2. Créez une nouvelle application Vapor avec la commande `vapor new my-dockerized-app` et suivez les étapes pour activer les fonctionnalités dont vous avez besoin. Vos réponses auront un effet sur la façon dont les fichiers de ressources Docker seront générés.

## Ressources Docker

Il vous sera utile, dès maintenant ou dans un futur proche, de vous familiariser avec l'[Aperçu de Docker](https://docs.docker.com/engine/docker-overview/). Cet aperçu vous expliquera la terminologie utilisée dans ce guide. 

Le modèle d'application Vapor contient deux ressources clés spécifiques à Docker : un fichier **Dockerfile** et **docker-compose**.

### Le Dockerfile

Un Dockerfile explique à Docker comment construire une image de votre application Dockerisée. Cette image contient l'exécutable de votre application et toutes les dépendances nécessaires pour l'exécuter. La [référence complète](https://docs.docker.com/engine/reference/builder/) pourra vous être utile pour personnaliser votre Dockerfile.

Le Dockerfile généré pour votre application Vapor définit deux étapes (stages). La première étape compile votre application et définit une zone de stoquage pour l'exécutable généré. La deuxième étape configure un environnement sécurisé d'exécution basique, transfère les fichiers générés à l'étape précédente vers leur emplacement prévu dans l'image finale, et définit le point d'entrée par défaut ainsi que la commande qui exécutera votre application en mode production sur le port par défaut (8080). Cette configuration pourra être modifiée lorsque l'image sera utilisée.

### Le fichier docker-compose

Un fichier docker-compose définit la façon dont Docker doit mettre en relation les différents services. Le fichier docker-compose de l'application modèle de Vapor contient les outils nécessaires pour déployer votre application, mais si vous souhaitez en apprendre d'avantage, vous devriez consulter la [référence complète](https://docs.docker.com/compose/compose-file/) qui détaille toutes les options disponibles.

!!! Note
    Si vous comptez utiliser Kubernetes pour orchestrer votre application, le fichier docker-compose n'aura pas un intérêt réel. Cependant, les fichiers de manifeste Kubernetes sont conceptuellement similaires et il existe même des projets qui visent à [convertir des fichiers docker-compose](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/) en manifestes Kubernetes.

Le fichier docker-compose de votre nouvelle application Vapor va définir des services pour exécuter votre application, lancer ou annuler des migrations, et exécuter une base de données pour la couche de persistance de votre application. Les définitions exactes dépendront du choix de base de données que vous avez fait en lançant la commande `vapor new`.

Notez que votre fichier docker-compose contient des variables d'environnement partagées vers le haut du fichier. (Vous aurez peut-être des variables différentes en fonction de si vous utilisez Fluent, et du driver Fluent choisi.)

```docker
x-shared_environment: &shared_environment
  LOG_LEVEL: ${LOG_LEVEL:-debug}
  DATABASE_HOST: db
  DATABASE_NAME: vapor_database
  DATABASE_USERNAME: vapor_username
  DATABASE_PASSWORD: vapor_password
```

Ces variables seront récupérées par différents services plus bas via la syntaxe de référence YAML `<<: *shared_environment`.

Les variables `DATABASE_HOST`, `DATABASE_NAME`, `DATABASE_USERNAME`, et `DATABASE_PASSWORD` sont ici codées en dur, alors que `LOG_LEVEL` récupèrera sa valeur depuis l'environnement exécutant le service ou définira la valeur par défaut `'debug'` en cas de variable non définie.

!!! Note
    Coder en dur les valeurs username et password est acceptable sur un environnement de développement local, mais vous devriez stoquer ces valeurs dans un fichier de secrets pour un déploiement en production. Une façon de faire est d'exporter le fichier de secrets sur l'environnement qui exécute le déploiement et d'utiliser des lignes comme l'exemple suivant dans votre fichier docker-compose : 

    ```
    DATABASE_USERNAME: ${DATABASE_USERNAME}
    ```

    Cela fera simplement passer la variable d'environnement au conteneur telle qu'elle est définie sur la machine hôte des déploiements.

Autres choses à prendre en compte :

- Les dépendances entre services se définissent par un tableau sous la clé `depends_on`.
- Les ports des services sont exposés au système qui les exécute par des tableaux sous la clé `ports` (au format `<port_hôte>:<port_service_dockerisé>`).
- La variable `DATABASE_HOST` est définie sur la valeur `db`. Votre application se connectera donc à la base de données à l'adresse `http://db:5432`. Ça fonctionne car Docker créera un réseau que vos services utiliseront, et le DNS interne de ce réseau acheminera toutes les requêtes à `db` vers le service nommé `'db'`.
- L'instruction `CMD` du Dockerfile est remplacée pour certains services par le tableau sous la clé `command`. Notez que ce qui est défini sous `command` sera passé en argument à ce qui est défini dans `ENTRYPOINT` du Dockerfile.
- En mode Swarm (plus de détails plus bas), chaque service se verra attribué une seule instance par défaut, mais les services `migrate` et `revert` sont définis avec le paramètre `deploy` `replicas: 0` pour éviter qu'ils ne démarrent automatiquement avec Swarm.

## Construction de l'image

Le fichier docker-compose indique à Docker comment construire votre application (via le Dockerfile du dossier courrant) et comment nommer l'image résultante (`my-dockerized-app:latest`). Ce nom est en fait une combinaison entre un nom (`my-dockerized-app`) et un tag (`latest`) où les tags servent à versionner les images Docker.

Pour construire une image Docker pour votre application, exécutez la commande

```shell
docker compose build
```

depuis le dossier racine du projet de votre application (qui contient le fichier `docker-compose.yml`).

Vous constaterez que votre application et ses dépendances doivent être compilées à nouveau, même si vous les aviez déjà compilées sur votre machine de développement. Étant compilées dans l'environnement Linux que Docker utilise, leurs artefacts de compilation qui existent sur votre machine de développement ne sont pas ré-utilisables.

Une fois que c'est fait, vous pourrez voir l'image de votre application avec la commande suivante :

```shell
docker image ls
```

## Exécution

Votre stack de services peut être directement exécutée depuis le fichier docker-compose, ou bien vous pouvez utiliser une couche d'orchestration comme le mode Swarm de Docker, ou Kubernetes.

### Standalone

La façon la plus simple de lancer votre application est de démarrer uniquement son conteneur. Docker utilisera les tableaux définis par les clés `depends_on` pour s'assurer que tous les services requis soient eux-aussi démarrés.

Commencez par exécuter ceci :

```shell
docker compose up app
```

Remarquez que les deux services `app` et `db` sont démarrés.

Votre application écoute le port 8080, et comme défini dans le fichier docker-compose, elle est rendue accessible à votre machine de développement hôte à l'adresse **http://localhost:8080**.

Cette correspondance de ports est très importante car elle permet de lancer simultanément plusieurs services qui écoutent le même port en interne dans leur conteneur et l'exposent à votre machine sur des ports différents.

Allez sur `http://localhost:8080` et vous obtiendrez `It works!`, mais allez sur `http://localhost:8080/todos` et vous obtiendrez ceci :

```
{"error":true,"reason":"Something went wrong."}
```

Jettez un oeil aux logs affichés dans le terminal où vous avez exécuté `docker compose up app` et vous verrez ceci :

```
[ ERROR ] relation "todos" does not exist
```

Bien sûr ! Nous devons exécuter les migrations sur notre base de données. Faites `Ctrl+C` pour arrêter votre application. Nous allons la redémarrer, mais cette fois-ci avec cette commande :

```shell
docker compose up --detach app
```

Votre application va démarrer en mode "détachée" (en tâche de fond). Vous pouvez le vérifier avec cette commande :

```shell
docker container ls
```

Vous verrez les conteneurs de la base de données et de votre application. Vous pouvez également voir les logs avec la commande suivante :

```shell
docker logs <container_id>
```

Pour lancer les migrations, exécutez cette commande :

```shell
docker compose run migrate
```

Ensuite, retournez sur `http://localhost:8080/todos` où vous obtiendrez une liste vide de choses à faire, à la place du message d'erreur précédent.

#### Niveaux de log

Souvenez-vous que nous avons mentionné plus haut que la valeur de la variable d'environnement `LOG_LEVEL` du fichier docker-compose sera héritée de l'environnement qui démarre les services si elle existe.

Vous pouvez démarrer vos services avec la commande

```shell
LOG_LEVEL=trace docker-compose up app
```

pour avoir un niveau de log défini sur `trace` (c'est le niveau le plus précis). Vous pouvez utiliser cette variable d'environnement pour définir n'importe quel [niveau de log disponible](../basics/logging.md#niveau-de-log).

#### Logs de tous les services

Si vous mentionnez explicitement le service de votre base de données au démarrage des conteneurs, vous verrez à la fois les logs de votre base de données et de votre application.

```shell
docker-compose up app db
```

#### Arrêt de conteneurs standalones

Maintenant que vos conteneurs tournent en mode "détaché" de votre shell hôte, vous devez tout de même pouvoir leur indiquer de s'arrêter. Il est utile de savoir que tout conteneur en cours d'exécution peut être arrêté avec la commande

```shell
docker container stop <id_du_conteneur>
```

mais le plus simple pour ces conteneurs en particulier sera la commande

```shell
docker-compose down
```

#### Effacer la base de données

Le fichier docker-compose définit un volume `db_data` pour que la base de données soit conservée entre chaque exécution. Il existe plusieurs façons de ré-initialiser votre base de données.

Vous pouvez supprimer le volume `db_data` en même temps que vous stoppez les conteneurs avec la commande

```shell
docker-compose down --volumes
```

Vous pouvez afficher la liste de tous les volumes qui stoquent des données avec `docker volume ls`. Notez que les noms de volumes auront généralement un préfixe comme `my-dockerized-app_` ou `test_` en fonction de si vous utilisez le mode Swarm ou non. 

Vous pouvez les supprimer un à un avec la commande suivante en remplaçant le nom du volume par celui que vous souhaitez effacer :

```shell
docker volume rm my-dockerized-app_db_data
```

Vous pouvez également supprimer tous les volumes en une fois avec la commande suivante :

```shell
docker volume prune
```

Faites juste attention à ne pas supprimer accidentellement un volume sur lequel sont stoquées des données que vous souhaitez conserver !

Docker ne vous laissera pas supprimer des volumes qui sont utilisés par des conteneurs en cours d'exécution ou stoppés. Vous pouvez lister les conteneurs en cours d'exécution avec `docker container ls` et vous pouvez aussi voir ceux qui sont arrêtés avec la commande `docker container ls -a`.

### Mode Swarm

Le mode Swarm est une interface pratique lorsque vous avez un fichier docker-compose sous la main et que vous voulez tester la mise à l'échelle horizontale de votre application. Vous pourrez tout savoir sur le mode Swarm en lisant sa [page de présentation](https://docs.docker.com/engine/swarm/).

Nous aurons d'abord besoin d'un noeud de gestion du Swarm. Exécutez la commande suivante :

```shell
docker swarm init
```

Nous utiliserons ensuite notre fichier docker-compose pour démarrer une stack nommée `'test'` qui contiendra nos services :

```shell
docker stack deploy -c docker-compose.yml test
```

Nous pouvons observer l'état de nos services avec cette commande :

```shell
docker service ls
```

Vous devriez voir `1/1` pour les copies (replicas) de vos services `app` et `db`, et `0/0` pour les services `migrate` et `revert`.

En mode Swarm, nous devons utiliser une autre commande pour lancer les migrations.

```shell
docker service scale --detach test_migrate=1
```

!!! Note
    Nous venons de demander à un service à exécution courte d'augmenter ses copies à un exemplaire. Il va donc instancier un service, l'exécuter, puis s'arrêter. Cependant, cela laissera une exécution de `0/1` instances attendues. Ce n'est pas gênant jusqu'à la prochaine migration à exécuter, car nous ne pourrons pas demander de "monter à une instance" si c'est déjà la configuration définie. Une bizarrerie de cette configuration, à la prochaine migration que nous voudrons exécuter dans cet environnement d'exécution Swarm, nous devrons demander de réduire à `0` les instances attendues avant de les remettre sur `1`.

En revanche nous y gagnons sur le fait de pouvoir re-dimensionner notre application à souhaite pour tester la charge sur la base de données, les crashs, etc.

Si vous souhaitez exécuter 5 instances de votre application en parallèle, exécutez cette commande :

```shell
docker service scale test_app=5
```

En plus de constater le redimensionnement Docker à la hausse, vous pouvez voir vos 5 instances avec `docker service ls`.

Vous pouvez voir (et suivre) les logs de votre application avec la commande suivante :

```shell
docker service logs -f test_app
```

#### Arrêt de services Swarm

Quand vous souhaitez stopper des services en mode Swarm, vous le faites en supprimant la stack créée précédemment.

```shell
docker stack rm test
```

## Déploiements de production

Comme noté en introduction, ce guide ne détaillera pas le déploiement de votre application Dockerisée en production car le sujet est vaste et diffère grandement d'un hébergeur à l'autre (AWS, Azure, etc.), des outils utilisés (Terraform, Ansible, etc.), et des orchestrateurs (Docker Swarm, Kubernetes, etc.).

Cependant, les techniques apprises en exécutant votre stack Docker sur votre machine de développement sont facilement portables sur un environnement de production. Un serveur ayant Docker acceptera les mêmes commandes.

Copiez votre projet sur le serveur, connectez-vous en SSH sur le serveur, et lancez `docker-compose` ou `docker stack deploy` pour lancer votre stack.

Vous pouvez aussi définir votre variable d'environnement locale `DOCKER_HOST` sur votre serveur distant et lancer les commandes `docker` en local. Il est important de préciser qu'avec cette approche, vous n'avez pas besoin de copier votre projet sur le serveur _mais_ vous devrez héberger les images Docker à un endroit d'où le serveur pourra les récupérer.
