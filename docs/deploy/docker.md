# Docker Deploys

Using Docker to deploy your Vapor app has several benefits: 

1. Your dockerized app can be spun up reliably using the same commands on any platform with a Docker Daemon -- namely, Linux (CentOS, Debian, Fedora, Ubuntu), macOS, and Windows.
2. You can use docker-compose or Kubernetes manifests to orchestrate multiple services needed for a full deployment (e.g. Redis, Postgres, nginx, etc.).
3. It is easy to test your app's ability to scale horizontally, even locally on your development machine.

This guide will stop short of explaining how to get your dockerized app onto a server. The simplest deploy would involve installing Docker on your server and running the same commands you would run on your development machine to spin up your application. 

More complicated and robust deployments are usually different depending on your hosting solution; many popular solutions like AWS have builtin support for Kubernetes and custom database solutions which make it difficult to write best practices in a way that applies to all deployments. 

Nevertheless, using Docker to spin your entire server stack up locally for testing purposes is incredibly valuable for both big and small serverside apps. Additionally, the concepts described in this guide apply in broad strokes to all Docker deployments.

## Set Up

You will need to set your developer environment up to run Docker and gain a basic understanding of the resource files that configure Docker stacks.

### Install Docker

You will need to install Docker for your developer environment. You can find information for any platform in the [Supported Platforms](https://docs.docker.com/install/#supported-platforms) section of the Docker Engine Overview. If you are on Mac OS, you can jump straight to the [Docker for Mac](https://docs.docker.com/docker-for-mac/install/) install page.

### Generate Template

We suggest using the Vapor template as a starting place. If you already have an App, build the template as described below into a new folder as a point of reference while dockerizing your existing app -- you can copy key resources from the template to your app and tweak them slightly as a jumping off point.

1. Install or build the Vapor Toolbox ([macOS](../install/macos.md#install-toolbox), [Linux](../install/linux.md#install-toolbox)).
2. Create a new Vapor App with `vapor new my-dockerized-app` and walk through the prompts to enable or disable relevant features. Your answers to these prompts will affect how the Docker resource files are generated.

## Docker Resources

It is worthwhile, whether now or in the near future, to familiarize yourself with the [Docker Overview](https://docs.docker.com/engine/docker-overview/). The overview will explain some key terminology that this guide uses. 

The template Vapor App has two key Docker-specific resources: A **Dockerfile** and a **docker-compose** file.

### Dockerfile

A Dockerfile tells Docker how to build an image of your dockerized app. That image contains both your app's executable and all dependencies needed to run it. The [full reference](https://docs.docker.com/engine/reference/builder/) is worth keeping open when you work on customizing your Dockerfile.

The Dockerfile generated for your Vapor app has two stages. The first stage builds your app and sets up a holding area containing the result. The second stage sets up the basics of a secure runtime environment, transfers everything in the holding area to where it will live in the final image, and sets a default entrypoint and command that will run your app in production mode on the default port (8080). This configuration can be overridden when the image is used.

### Docker Compose File

A Docker Compose file defines the way Docker should build out multiple services in relation to each other. The Docker Compose file in the Vapor App template provides the necessary functionality to deploy your app, but if you want to learn more you should consult the [full reference](https://docs.docker.com/compose/compose-file/) which has details on all of the available options.

!!! note
    If you ultimately plan to use Kubernetes to orchestrate your app, the Docker Compose file is not directly relevant. However, Kubernetes manifest files are similar conceptually and there are even projects out there aimed at [porting Docker Compose files](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/) to Kubernetes manifests.

The Docker Compose file in your new Vapor App will define services for running your app, running migrations or reverting them, and running a database as your app's persistence layer. The exact definitions will vary depending on which database you chose to use when you ran `vapor new`.

Note that your Docker Compose file has some shared environment variables near the top. (You may have a different set of default variables depending on whether or not you're using Fluent, and which Fluent driver is in use if you are.)

```docker
x-shared_environment: &shared_environment
  LOG_LEVEL: ${LOG_LEVEL:-debug}
  DATABASE_HOST: db
  DATABASE_NAME: vapor_database
  DATABASE_USERNAME: vapor_username
  DATABASE_PASSWORD: vapor_password
```

You will see these pulled into multiple services below with the `<<: *shared_environment` YAML reference syntax.

The `DATABASE_HOST`, `DATABASE_NAME`, `DATABASE_USERNAME`, and `DATABASE_PASSWORD` variables are hard coded in this example whereas the `LOG_LEVEL` will take its value from the environment running the service or fall back to `'debug'` if that variable is unset.

!!! note
    Hard-coding the username and password is acceptable for local development, but you should store these variables in a secrets file for production deployment. One way to handle this in production is to export the secrets file to the environment that is running your deploy and use lines like the following in your Docker Compose file: 

    ```
    DATABASE_USERNAME: ${DATABASE_USERNAME}
    ```

    This passes the environment variable through to the containers as-defined by the host.

Other things to take note of:

- Service dependencies are defined by `depends_on` arrays.
- Service ports are exposed to the system running the services with `ports` arrays (formatted as `<host_port>:<service_port>`).
- The `DATABASE_HOST` is defined as `db`. This means your app will access the database at `http://db:5432`. That works because Docker is going to spin up a network in use by your services and the internal DNS on that network will route the name `db` to the service named `'db'`.
- The `CMD` directive in the Dockerfile is overridden in some services with the `command` array. Note that what is specified by `command` is run against the `ENTRYPOINT` in the Dockerfile.
- In Swarm Mode (more on this below) services will by default be given 1 instance, but the `migrate` and `revert` services are defined as having `deploy` `replicas: 0` so they do not start up by default when running a Swarm.

## Building

The Docker Compose file tells Docker how to build your app (by using the Dockerfile in the current directory) and what to name the resulting image (`my-dockerized-app:latest`). The latter is actually the combination of a name (`my-dockerized-app`) and a tag (`latest`) where tags are used to version Docker images.

To build a Docker image for your app, run
```shell
docker compose build
```
from the root directory of your app's project (the folder containing `docker-compose.yml`).

You'll see that your app and its dependencies must be built again even if you had previously built them on your development machine. They are being built in the Linux build environment Docker is using so the build artifacts from your development machine are not reusable.

When it is done, you will find your app's image when running
```shell
docker image ls
```

## Running

Your stack of services can be run directly from the Docker Compose file or you can use an orchestration layer like Swarm Mode or Kubernetes.

### Standalone

The simplest way to run your app is to start it as a standalone container. Docker will use the `depends_on` arrays to make sure any dependant services are also started.

First, execute:
```shell
docker compose up app
```
and notice that both the `app` and `db` services are started.

Your app is listening on port 8080 and, as defined by the Docker Compose file, it is made accessible on your development machine at **http://localhost:8080**.

This port mapping distinction is very important because you can run any number of services on the same ports if they are all running in their own containers and they each expose different ports to the host machine.

Visit `http://localhost:8080` and you will see `It works!` but visit `http://localhost:8080/todos` and you will get: 
```
{"error":true,"reason":"Something went wrong."}
```

Take a peak at the logs output in the terminal where you ran `docker compose up app` and you will see:
```
[ ERROR ] relation "todos" does not exist
```

Of course! We need to run migrations on the database. Press `Ctrl+C` to bring your app down. We are going to start the app up again but this time with:
```shell
docker compose up --detach app
```

Now your app is going to start up "detached" (in the background). You can verify this by running:
```shell
docker container ls
```
where you will see both the database and your app running in containers. You can even check on the logs by running:
```shell
docker logs <container_id>
```

To run migrations, execute:
```shell
docker compose run migrate
```

After migrations run, you can visit `http://localhost:8080/todos` again and you will get an empty list of todos instead of an error message.

#### Log Levels

Recall above that the `LOG_LEVEL` environment variable in the Docker Compose file will be inherited from the environment where the service is started if available.

You can bring your services up with
```shell
LOG_LEVEL=trace docker-compose up app
```
to get `trace` level logging (the most granular). You can use this environment variable to set the logging to [any available level](../logging.md#levels).

#### All Service Logs

If you explicitly specify your database service when you bring containers up then you will see logs for both your database and your app.
```shell
docker-compose up app db
```

#### Bringing Standalone Containers Down

Now that you've got containers running "detached" from your host shell, you need to tell them to shut down somehow. It's worth knowing that any running container can be asked to shut down with
```shell
docker container stop <container_id>
```
but the easiest way to bring these particular containers down is
```shell
docker-compose down
```

#### Wiping The Database

The Docker Compose file defines a `db_data` volume to persist your database between runs. There are a couple of ways to reset your database.

You can remove the `db_data` volume at the same time as bringing your containers down with
```shell
docker-compose down --volumes
```

You can see any volumes currently persisting data with `docker volume ls`. Note that the volume name will generally have a prefix of `my-dockerized-app_` or `test_` depending on whether you were running in Swarm Mode or not. 

You can remove these volumes one at a time with e.g.
```shell
docker volume rm my-dockerized-app_db_data
```

You can also clean up all volumes with
```shell
docker volume prune
```

Just be careful you don't accidentally prune a volume with data you wanted to keep around!

Docker will not let you remove volumes that are currently in use by running or stopped containers. You can get a list of running containers with `docker container ls` and you can see stopped containers as well with `docker container ls -a`.

### Swarm Mode

Swarm Mode is an easy interface to use when you've got a Docker Compose file handy and you want to test how your app scales horizontally. You can read all about Swarm Mode in the pages rooted at the [overview](https://docs.docker.com/engine/swarm/).

The first thing we need is a manager node for our Swarm. Run
```shell
docker swarm init
```

Next we will use our Docker Compose file to bring up a stack named `'test'` containing our services
```shell
docker stack deploy -c docker-compose.yml test
```

We can see how our services are doing with
```shell
docker service ls
```

You should expect to see `1/1` replicas for your `app` and `db` services and `0/0` replicas for your `migrate` and `revert` services.

We need to use a different command to run migrations in Swarm mode.
```shell
docker service scale --detach test_migrate=1
```

!!! note
    We have just asked a short-lived service to scale to 1 replica. It will successfully scale up, run, and then exit. However, that will leave it with `0/1` replicas running. This is no big deal until we want to run migrations again, but we cannot tell it to "scale up to 1 replica" if that is already where it is at. A quirk of this setup is that the next time we want to run migrations within the same Swarm runtime, we need to first scale the service down to `0` and then back up to `1`.

The payoff for our trouble in the context of this short guide is that now we can scale our app to whatever we want in order to test how well it handles database contention, crashes, and more.

If you want to run 5 instances of your app concurrently, execute
```shell
docker service scale test_app=5
```

In addition to watching docker scale your app up, you can see that 5 replicas are indeed running by again checking `docker service ls`.

You can view (and follow) the logs for your app with
```shell
docker service logs -f test_app
```

#### Bringing Swarm Services Down

When you want to bring your services down in Swarm Mode, you do so by removing the stack you created earlier.
```shell
docker stack rm test
```

## Production Deploys

As noted at the top, this guide will not go into great detail about deploying your dockerized app to production because the topic is large and varies greatly depending on the hosting service (AWS, Azure, etc.), tooling (Terraform, Ansible, etc.), and orchestration (Docker Swarm, Kubernetes, etc.).

However, the techniques you learn to run your dockerized app locally on your development machine are largely transferable to production environments. A server instance set up to run the docker daemon will accept all the same commands.

Copy your project files to your server, SSH into the server, and run a `docker-compose` or `docker stack deploy` command to get things running remotely.

Alternatively, set your local `DOCKER_HOST` environment variable to point at your server and run the `docker` commands locally on your machine. It is important to note that with this approach, you do not need to copy any of your project files to the server _but_ you do need to host your docker image somewhere your server can pull it from.
