# Docker 部署

使用 Docker 部署 Vapor 应用程序有几个好处：

1. 你的 dockerized 应用程序可以在任何带有 Docker 守护进程的平台上使用相同的命令可靠地启动，即 Linux（CentOS、Debian、Fedora、Ubuntu）、macOS 和 Windows。
2. 你可以使用 docker-compose 或 Kubernetes 清单来编排完整部署所需的多个服务（例如 Redis、Postgres、nginx 等）。
3. 测试你的应用程序水平扩展的能力很容易，甚至在你的开发机器上本地测试。

本指南不会解释如何将你的 dockerized 应用程序放到服务器上。最简单的部署将涉及在你的服务器上安装 Docker，并运行你在开发机上运行的那些命令来启动你的应用程序。

更复杂、更强大的部署通常会因你的托管解决方案而异；许多流行的解决方案（如 AWS）都内置了对 Kubernetes 和定制数据库解决方案的支持，这使得编写适用于所有部署的最佳实践变得困难。

尽管如此，使用 Docker 在本地运行整个服务器堆栈以进行测试对于大型和小型服务器端应用程序都非常有价值。此外，本指南中描述的概念广泛适用于所有 Docker 部署。

## 设置

你需要设置你的开发环境来运行 Docker，并基本了解配置 Docker 堆栈的资源文件。

### 安装 Docker

你需要在开发环境安装 Docker。你可以在 Docker 引擎概述的[平台支持](https://docs.docker.com/install/#supported-platforms)部分找到任何平台的信息。如果你用的是 Mac OS，则可以直接跳转到 [Docker for Mac](https://docs.docker.com/docker-for-mac/install/) 安装页面。

### 生成模板

我们建议使用 Vapor 模板作为起点。如果你已经有了一个应用程序，请在对现有应用程序进行 docker 化时将如下所述的模板构建到一个新文件夹中作为参考点 —— 你可以将关键资源从模板复制到你的应用程序，并以此为起点对它们进行轻微的调整。

1. 安装或构建 Vapor 工具箱（[macOS](../install/macos.zh.md#install-toolbox)、[Linux](../install/linux.zh.md#install-toolbox)）。
2. 终端运行 `vapor new my-dockerized-app` 命令来创建一个新的 Vapor 应用程序并按照提示启用或禁用相关功能。你对这些提示的回答将影响 Docker 资源文件的生成方式。

## Docker 资源

无论是现在还是在不久的将来，熟悉一下 [Docker 概述](https://docs.docker.com/engine/docker-overview/)都是值得的。概述将解释本指南使用的一些关键术语。

Vapor 应用模板有两个针对 Docker 的关键资源：一个 **Dockerfile** 文件和一个 **docker-compose** 文件。

### Dockerfile

Dockerfile 告诉 Docker 如何构建 dockerized 应用程序的镜像。该镜像包含你应用程序的可执行文件和运行它所需的所有依赖项。当你自定义 Dockerfile 时，请查阅此[参考文档](https://docs.docker.com/engine/reference/builder/)。

为你的 Vapor 应用程序生成的 Dockerfile 有两个阶段。第一阶段构建你的应用程序并设置一个包含结果的保存区域。第二阶段设置安全运行时的基础环境，将保存区域中的所有内容传输到最终镜像中的位置，并设置默认入口点和命令，在默认端口（8080）上以生产模式运行你的应用程序。使用镜像时可以覆盖此配置。

### Docker Compose 文件

Docker Compose 文件定义了 Docker 应该如何构建彼此相关的多个服务。Vapor 应用程序模板中的 Docker Compose 文件提供了部署应用程序所需的功能，但如果你想了解更多信息，请参考[完整文档](https://docs.docker.com/compose/compose-file/)，其中包含所有可用选项的详细信息。

!!! note "注意"
    如果你最终计划使用 Kubernetes 来部署你的应用程序，虽然它与 Docker Compose 文件并不直接相关。但是 Kubernetes 清单文件和 Docker Compose 文件在概念上是相似的，甚至还有一些项目旨在将 [Docker Compose 文件移植](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/)到 Kubernetes 清单文件中。

新的 Vapor 应用程序中的 Docker Compose 文件将定义用于运行应用程序、运行迁移或恢复它们以及运行数据库作为应用程序持久层的服务。确切的定义将根据你在运行 `vapor new` 命令时选择使用的数据库而有所不同。

请注意，你的 Docker Compose 文件在顶部附近有一些共享环境变量。（你可能有一组不同的默认变量，具体取决于你是否使用 Fluent，以及你使用的是哪个 Fluent 驱动程序。）

```docker
x-shared_environment: &shared_environment
  LOG_LEVEL: ${LOG_LEVEL:-debug}
  DATABASE_HOST: db
  DATABASE_NAME: vapor_database
  DATABASE_USERNAME: vapor_username
  DATABASE_PASSWORD: vapor_password
```

你将看到这些使用 `<<: *shared_environment` YAML 参考语法被拉入到下面的多个服务中。

在此示例中 `DATABASE_HOST`，`DATABASE_NAME`，`DATABASE_USERNAME` 和 `DATABASE_PASSWORD` 变量是硬编码的，而 `LOG_LEVEL` 将从运行服务的环境中获取其值，或者如果未设置该变量，则回退到 `'debug'` 级别。

!!! note "注意"
    对于本地开发来说，硬编码用户名和密码是可以接受的，但是你应该将这些变量存储在一个机密文件中，以便进行生产部署。在生产中处理此问题的一种方法是将机密文件导出到运行部署的环境中，并在 Docker Compose 文件中使用如下行：

    ```
    DATABASE_USERNAME: ${DATABASE_USERNAME}
    ```

    这会将环境变量传递给主机定义的容器。

其它注意的事项：

- 服务依赖项由 `depends_on` 数组定义。
- 服务端口通过 `ports`数组（格式为 `<host_port>:<service_port>`）暴露给运行服务的系统。
- `DATABASE_HOST` 定义为 `db`。这意味着你的应用程序将访问 `http://db:5432` 中的数据库。这是可行的，因为 Docker 将启动你的服务正在使用的网络，该网络上的内部 DNS 会将名称 `db` 路由到名为 `'db'` 的服务。
- 在一些服务中，Dockerfile 中的 `CMD` 指令会被 `command` 数组覆盖。注意，`command` 指定的内容是针对 Dockerfile 中的 `ENTRYPOINT` 运行的。

- 在集群模式下（更多内容见下文），默认情况下会为服务提供1个实例，但 `migrate` 和 `revert` 服务被定义为具有 `deploy` `replicas: 0` 因此它们在运行集群时不会默认启动。

## 构建

Docker Compose 文件告诉 Docker 如何构建你的应用程序（使用当前目录中的 Dockerfile)，以及如何命名生成的镜像（`my-dockeralized-app：latest`）。后者实际上是名称（`my-dockeralized-app`）和标签（`latest`）的组合，其中标签用于对 Docker 镜像进行版本控制。

要为你的应用程序构建 Docker 镜像，请运行

```shell
docker compose build
```

从项目的根目录（包含 `docker-compose.yml` 的文件夹）。

你将看到应用程序及其依赖项必须重新构建，即使你之前已在开发机器上构建它们。它们是在 Docker 使用的 Linux 构建环境中构建的，因此来自你的开发机器的构建工件不可重用。

完成后，你将在运行下面命令时找到应用程序的镜像

```shell
docker image ls
```

## 运行

你的服务堆栈可以直接从 Docker Compose 文件运行，也可以使用编排层，如集群模式或 Kubernetes。

### 独立

运行应用程序的最简单方法是将其作为独立容器启动。Docker 将使用 `Dependents_on` 数组来确保所有依赖服务也已启动。

首先，执行：

```shell
docker compose up app
```

并注意 `app` 和 `db` 服务都已启动。


你的应用程序正在监听8080端口，并且，正如 Docker Compose 文件所定义的那样，可以在你的开发机上访问 **http://localhost:8080**。

这种端口映射区别非常重要，因为你可以在相同的端口上运行任意数量的服务，前提是这些服务都在各自的容器中运行，并且每个服务都向主机公开不同的端口。

访问 `http://localhost:8080`，你会看到 `It works!`，但访问 `http://localhost:8080/todos`，你会得到：

```
{"error":true,"reason":"Something went wrong."}
```

在你运行 `docker compose up app` 命令的终端中查看输出的日志，你将看到：

```
[ ERROR ] relation "todos" does not exist
```

当然！我们需要在数据库上运行迁移。按下 `Ctrl+C` 可关闭你的应用程序。我们将再次启动应用程序，但这次是：

```shell
docker compose up --detach app
```

现在你的应用程序将启动 “detached”（在后台）。你可以通过运行以下命令验证这一点：

```shell
docker container ls
```

你将在其中看到数据库和你的应用程序都在容器中运行。你甚至可以通过运行以下命令检查日志：

```shell
docker logs <container_id>
```

要运行迁移，请执行：

```shell
docker compose run migrate
```

迁移运行后，你可以再次访问 `http://localhost:8080/todos`，你将获得一个空的待办事项列表，而不是错误消息。

#### 日志级别

回想一下，Docker Compose 文件中的 `LOG_LEVEL` 环境变量将从启动服务的环境继承（如果可用）。

你可以通过以下方式提升你的服务

```shell
LOG_LEVEL=trace docker-compose up app
```

获取 `trace` 级别日志记录（最精细的）。你可以使用此环境变量将日志记录设置为[任何可用级别](../basics/logging.zh.md#level)。

#### 所有服务日志

如果在启动容器时显式指定数据库服务，则会同时看到数据库和应用程序的日志。

```shell
docker-compose up app db
```

#### 停用独立容器

现在你已经让容器与主机外壳“分离”运行了，你需要告诉它们以某种方式关闭。值得知道的是，任何正在运行的容器都可以被要求关闭

```shell
docker container stop <container_id>
```

将这些特定容器关闭的最简单方法是

```shell
docker-compose down
```

#### 擦除数据

Docker Compose 文件定义了一个 `db_data` 卷以在运行期间持久保存你的数据库。有几种方法可以重置数据库。

你可以在关闭容器的同时删除 `db_data` 卷

```shell
docker-compose down --volumes
```

你可以通过 `docker volume ls` 命令查看当前持久化数据的任何卷。请注意，卷名通常会有前缀 `my-dockeralized-app_` 或 `test_`，这取决于你是否在集群模式下运行。

你可以一次删除这些卷，例如

```shell
docker volume rm my-dockerized-app_db_data
```

你还可以使用下面命令清理所有卷

```shell
docker volume prune
```

请注意，不要不小心修剪了包含你想要保留的数据的卷！

Docker 不允许你通过运行或停止的容器删除当前正在使用的卷。使用 `docker tainer ls` 命令可以获取运行中的容器列表，使用 `docker tainer ls-a` 命令也可以看到停止的容器列表。

### 集群模式

当你手头有 Docker Compose 文件并且想要测试你的应用程序如何水平扩展时，集群模式是一个易于使用的界面。你可以在[概述](https://docs.docker.com/engine/swarm/)中阅读有关集群模式的所有信息。

第一件事是我们需要创建集群的管理节点。运行如下命令

```shell
docker swarm init
```

接下来，我们将使用 Docker Compose 文件来调出一个名为的 `test` 的堆栈，其中包含我们的服务

```shell
docker stack deploy -c docker-compose.yml test
```

我们可以看到我们的服务是如何处理的

```shell
docker service ls
```

你应该会看到 `app` 和 `db` 服务的`1/1`副本，以及 `Migrate` 和 `revert` 服务的`0/0`副本。

我们需要使用不同的命令在集群模式下运行迁移。

```shell
docker service scale --detach test_migrate=1
```

!!! note "注意"
    我们刚刚将一个短服务扩展到1个副本，它将成功扩展、运行，然后退出。但是，这将使它与`0/1`副本一起运行。 在我们想再次运行迁移之前，这没什么大不了的，但如果它已经存在，我们不能告诉它“扩展到1个副本”。 这个设置的一个注意点是，下次我们想在同一个 Swarm 运行时中运行迁移时，我们需要先将服务缩减到 `0`，然后再回到 `1`。

在这篇简短的指南中，我们的困扰得到了解决，现在我们可以将应用程序扩展到任何我们想要的范围，以测试它处理数据库争用、崩溃等问题的能力。

如果要同时运行5个应用程序实例，请执行

```shell
docker service scale test_app=5
```

除了通过 docker 扩展你的应用程序之外，通过再次检查 `docker service ls`，你还可以看到5个副本确实在运行。

你可以查看（并关注）应用程序的日志

```shell
docker service logs -f test_app
```

#### 集群模式下线服务

当你想要在集群模式下关闭你的服务时，你可以通过删除先前创建的堆栈来实现。

```shell
docker stack rm test
```

## 生产部署

正如上面提到的，本指南不会详细介绍如何将你的 dockerized 应用程序部署到生产环境，因为该部分内容较多并且根据托管服务（AWS、Azure 等）、工具（Terraform、Ansible 等）和编排（Docker Swarm、Kubernetes 等）的不同而有很大差异。

然而，你学习的在开发机上本地运行 dockerized 应用程序的技术在很大程度上可以转移到生产环境中。设置为运行 docker 守护进程的服务器实例接受所有相同的命令。

将你的项目文件复制到你的服务器上，通过 SSH 连接到服务器，然后运行 `docker-compose` 或 `docker stack deploy` 命令来远程运行。

或者，将本地的 `DOCKER_HOST` 环境变量设置为指向你的服务器，并在你的计算机上本地运行 `docker` 命令。重要的是要注意，使用这种方法，你不需要将任何项目文件复制到服务器上，_但是_ 你需要将你的 docker 镜像托管的位置能够让你的服务器可以拉取。



