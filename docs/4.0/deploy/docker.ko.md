# Docker 배포

Docker를 사용하여 Vapor 앱을 배포하면 다음과 같은 여러 이점이 있습니다.

1. 도커라이즈된(dockerized) 앱은 Docker Daemon이 있는 어떤 플랫폼에서도, 즉 Linux(CentOS, Debian, Fedora, Ubuntu), macOS, Windows에서도 동일한 명령어를 사용하여 안정적으로 실행할 수 있습니다.
2. docker-compose나 Kubernetes 매니페스트를 사용하여 전체 배포에 필요한 여러 서비스(Redis, Postgres, nginx 등)를 오케스트레이션할 수 있습니다.
3. 개발 머신에서 로컬로도 앱이 수평으로 확장되는 능력을 손쉽게 테스트할 수 있습니다.

이 가이드에서는 도커라이즈된 앱을 서버에 올리는 방법까지는 다루지 않습니다. 가장 간단한 배포 방법은 서버에 Docker를 설치하고, 개발 머신에서 앱을 실행할 때 사용했던 것과 동일한 명령어를 실행하여 애플리케이션을 띄우는 것입니다.

더 복잡하고 견고한 배포는 사용하는 호스팅 솔루션에 따라 대체로 달라집니다. AWS와 같은 많은 인기 있는 솔루션은 Kubernetes와 커스텀 데이터베이스 솔루션을 기본적으로 지원하기 때문에, 모든 배포에 적용될 수 있는 모범 사례를 작성하기가 어렵습니다.

그럼에도 불구하고, 테스트 목적으로 전체 서버 스택을 로컬에서 Docker로 띄워보는 것은 크고 작은 서버 사이드 앱 모두에게 매우 유용합니다. 또한 이 가이드에서 설명하는 개념들은 대체로 모든 Docker 배포에 적용됩니다.

## 설정

Docker를 실행할 수 있도록 개발 환경을 설정하고, Docker 스택을 구성하는 리소스 파일에 대한 기본적인 이해를 갖춰야 합니다.

### Docker 설치하기

개발 환경에 Docker를 설치해야 합니다. Docker Engine 개요의 [지원 플랫폼](https://docs.docker.com/install/#supported-platforms) 섹션에서 어떤 플랫폼에 대한 정보든 찾을 수 있습니다. Mac OS를 사용 중이라면 [Docker for Mac](https://docs.docker.com/docker-for-mac/install/) 설치 페이지로 바로 이동해도 됩니다.

### 템플릿 생성하기

시작점으로 Vapor 템플릿을 사용하는 것을 권장합니다. 이미 앱이 있다면, 아래에 설명된 대로 템플릿을 새 폴더에 빌드하여 기존 앱을 도커라이즈할 때 참고할 자료로 삼으세요. 템플릿에서 핵심 리소스를 복사하여 앱에 붙여넣고 약간 조정하면 좋은 출발점이 됩니다.

1. Vapor Toolbox를 설치하거나 빌드합니다 ([macOS](../install/macos.md#toolbox-설치하기), [Linux](../install/linux.md#toolbox-설치하기)).
2. `vapor new my-dockerized-app` 명령어로 새 Vapor 앱을 생성하고, 프롬프트를 따라가며 필요한 기능을 활성화하거나 비활성화합니다. 이 프롬프트에 대한 답변에 따라 Docker 리소스 파일이 생성되는 방식이 달라집니다.

## Docker 리소스

지금이든 가까운 미래든, [Docker 개요](https://docs.docker.com/engine/docker-overview/)에 익숙해지는 것은 그만한 가치가 있습니다. 이 개요 문서는 이 가이드에서 사용하는 몇 가지 핵심 용어를 설명해줍니다.

Vapor 앱 템플릿에는 두 가지 핵심 Docker 관련 리소스가 있습니다. 바로 **Dockerfile**과 **docker-compose** 파일입니다.

### Dockerfile

Dockerfile은 도커라이즈된 앱의 이미지를 어떻게 빌드할지 Docker에게 알려줍니다. 이 이미지에는 앱의 실행 파일과 이를 실행하는 데 필요한 모든 의존성이 포함됩니다. Dockerfile을 커스터마이징할 때는 [전체 레퍼런스](https://docs.docker.com/engine/reference/builder/)를 열어두는 것이 좋습니다.

Vapor 앱을 위해 생성된 Dockerfile은 두 단계로 이루어져 있습니다. 첫 번째 단계는 앱을 빌드하고 그 결과물을 담아둘 임시 저장 공간을 설정합니다. 두 번째 단계는 안전한 런타임 환경의 기본 요소를 설정하고, 임시 저장 공간에 있던 모든 것을 최종 이미지 내 위치로 옮긴 다음, 기본 포트(8080)에서 프로덕션 모드로 앱을 실행할 기본 entrypoint와 command를 설정합니다. 이 설정은 이미지를 사용할 때 재정의할 수 있습니다.

### Docker Compose 파일

Docker Compose 파일은 Docker가 여러 서비스를 서로 어떻게 연관지어 빌드해야 하는지 정의합니다. Vapor 앱 템플릿의 Docker Compose 파일은 앱을 배포하는 데 필요한 기능을 제공하지만, 더 자세히 알고 싶다면 사용 가능한 모든 옵션에 대한 세부 정보가 담긴 [전체 레퍼런스](https://docs.docker.com/compose/compose-file/)를 참고하세요.

!!! note
    최종적으로 Kubernetes를 사용하여 앱을 오케스트레이션할 계획이라면, Docker Compose 파일은 직접적인 관련이 없습니다. 하지만 Kubernetes 매니페스트 파일은 개념적으로 유사하며, [Docker Compose 파일을 이식](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/)하여 Kubernetes 매니페스트로 만들어주는 프로젝트도 존재합니다.

새 Vapor 앱의 Docker Compose 파일은 앱을 실행하는 서비스, 마이그레이션을 실행하거나 되돌리는 서비스, 그리고 앱의 영속성 계층으로 쓰일 데이터베이스를 실행하는 서비스를 정의합니다. `vapor new`를 실행할 때 어떤 데이터베이스를 선택했는지에 따라 정확한 정의는 달라집니다.

Docker Compose 파일 상단에는 공유되는 환경 변수가 있습니다. (Fluent를 사용하는지 여부와, 사용한다면 어떤 Fluent 드라이버를 사용하는지에 따라 기본 변수 세트가 다를 수 있습니다.)

```docker
x-shared_environment: &shared_environment
  LOG_LEVEL: ${LOG_LEVEL:-debug}
  DATABASE_HOST: db
  DATABASE_NAME: vapor_database
  DATABASE_USERNAME: vapor_username
  DATABASE_PASSWORD: vapor_password
```

아래에서 `<<: *shared_environment` YAML 참조 문법을 통해 이 값들이 여러 서비스로 가져와지는 것을 볼 수 있습니다.

이 예제에서 `DATABASE_HOST`, `DATABASE_NAME`, `DATABASE_USERNAME`, `DATABASE_PASSWORD` 변수는 하드코딩되어 있는 반면, `LOG_LEVEL`은 서비스를 실행하는 환경에서 값을 가져오며, 해당 변수가 설정되어 있지 않으면 `'debug'`로 대체됩니다.

!!! note
    로컬 개발 환경에서는 사용자 이름과 비밀번호를 하드코딩해도 괜찮지만, 프로덕션 배포에서는 이 변수들을 시크릿 파일에 저장해야 합니다. 프로덕션에서 이를 처리하는 한 가지 방법은 시크릿 파일을 배포를 실행하는 환경으로 내보내고, Docker Compose 파일에서 다음과 같은 줄을 사용하는 것입니다.

    ```
    DATABASE_USERNAME: ${DATABASE_USERNAME}
    ```

    이렇게 하면 호스트에서 정의된 환경 변수가 컨테이너로 전달됩니다.

그 밖에 눈여겨볼 점들:

- 서비스 의존성은 `depends_on` 배열로 정의됩니다.
- 서비스 포트는 `ports` 배열(`<host_port>:<service_port>` 형식)을 통해 서비스를 실행하는 시스템에 노출됩니다.
- `DATABASE_HOST`는 `db`로 정의되어 있습니다. 즉, 앱은 데이터베이스에 `http://db:5432`로 접근하게 됩니다. 이는 Docker가 서비스들이 사용할 네트워크를 띄우고, 그 네트워크 내부의 DNS가 `db`라는 이름을 `'db'`라는 이름의 서비스로 라우팅해주기 때문에 가능합니다.
- Dockerfile의 `CMD` 지시어는 일부 서비스에서 `command` 배열로 재정의됩니다. `command`로 지정된 내용은 Dockerfile의 `ENTRYPOINT`를 대상으로 실행된다는 점에 유의하세요.
- Swarm Mode(아래에서 더 자세히 다룹니다)에서는 서비스에 기본적으로 인스턴스 1개가 할당되지만, `migrate`와 `revert` 서비스는 `deploy`의 `replicas: 0`으로 정의되어 있어 Swarm을 실행할 때 기본적으로 시작되지 않습니다.

## 빌드하기

Docker Compose 파일은 (현재 디렉터리의 Dockerfile을 사용하여) 앱을 어떻게 빌드할지와, 생성된 이미지에 어떤 이름(`my-dockerized-app:latest`)을 붙일지를 Docker에게 알려줍니다. 후자는 사실 이름(`my-dockerized-app`)과 태그(`latest`)의 조합이며, 태그는 Docker 이미지의 버전을 관리하는 데 사용됩니다.

앱의 Docker 이미지를 빌드하려면 다음을 실행하세요.

```shell
docker compose build
```

이 명령어는 앱 프로젝트의 루트 디렉터리(`docker-compose.yml`이 있는 폴더)에서 실행합니다.

개발 머신에서 이미 앱과 그 의존성을 빌드한 적이 있더라도, 다시 빌드되어야 한다는 것을 확인할 수 있습니다. Docker가 사용하는 Linux 빌드 환경에서 빌드되기 때문에, 개발 머신에서 만들어진 빌드 산출물은 재사용할 수 없습니다.

빌드가 끝나면 다음을 실행하여 앱의 이미지를 확인할 수 있습니다.

```shell
docker image ls
```

## 실행하기

서비스 스택은 Docker Compose 파일에서 직접 실행할 수도 있고, Swarm Mode나 Kubernetes 같은 오케스트레이션 레이어를 사용할 수도 있습니다.

### 단독 실행

앱을 실행하는 가장 간단한 방법은 단독 컨테이너로 시작하는 것입니다. Docker는 `depends_on` 배열을 사용하여 의존하는 서비스도 함께 시작되도록 합니다.

먼저 다음을 실행하세요.

```shell
docker compose up app
```

그러면 `app`과 `db` 서비스가 모두 시작되는 것을 확인할 수 있습니다.

앱은 8080 포트에서 대기하며, Docker Compose 파일에 정의된 대로 개발 머신에서 **http://localhost:8080**을 통해 접근할 수 있습니다.

이 포트 매핑의 구분은 매우 중요합니다. 각 서비스가 자신만의 컨테이너에서 실행되면서 호스트 머신에는 서로 다른 포트를 노출하는 한, 동일한 포트에서 얼마든지 많은 서비스를 실행할 수 있기 때문입니다.

`http://localhost:8080`에 방문하면 `It works!`가 보이지만, `http://localhost:8080/todos`에 방문하면 다음과 같은 결과를 얻게 됩니다.

```
{"error":true,"reason":"Something went wrong."}
```

`docker compose up app`을 실행한 터미널의 로그 출력을 살펴보면 다음을 볼 수 있습니다.

```
[ ERROR ] relation "todos" does not exist
```

당연합니다! 데이터베이스에 마이그레이션을 실행해야 합니다. `Ctrl+C`를 눌러 앱을 중지하세요. 이번에는 다음과 같이 앱을 다시 시작할 것입니다.

```shell
docker compose up --detach app
```

이제 앱이 "분리된(detached)" 상태(백그라운드)로 시작됩니다. 다음을 실행하여 이를 확인할 수 있습니다.

```shell
docker container ls
```

여기서 데이터베이스와 앱이 모두 컨테이너에서 실행 중인 것을 볼 수 있습니다. 다음을 실행하여 로그도 확인할 수 있습니다.

```shell
docker logs <container_id>
```

마이그레이션을 실행하려면 다음을 실행하세요.

```shell
docker compose run migrate
```

마이그레이션이 실행된 후, 다시 `http://localhost:8080/todos`에 방문하면 에러 메시지 대신 빈 todo 목록을 얻게 됩니다.

#### 로그 레벨

위에서 언급했듯이, Docker Compose 파일의 `LOG_LEVEL` 환경 변수는 서비스가 시작되는 환경에 해당 값이 있다면 그 값을 물려받습니다.

다음과 같이 서비스를 시작하면

```shell
LOG_LEVEL=trace docker-compose up app
```

가장 세밀한 수준인 `trace` 레벨 로깅을 얻을 수 있습니다. 이 환경 변수를 사용하여 로깅을 [사용 가능한 모든 레벨](../basics/logging.md#레벨level)로 설정할 수 있습니다.

#### 전체 서비스 로그

컨테이너를 시작할 때 데이터베이스 서비스를 명시적으로 지정하면 데이터베이스와 앱의 로그를 모두 볼 수 있습니다.

```shell
docker-compose up app db
```

#### 단독 컨테이너 종료하기

이제 컨테이너들이 호스트 셸로부터 "분리된" 채로 실행 중이므로, 어떻게든 종료하라고 알려주어야 합니다. 실행 중인 컨테이너는 다음 명령어로 종료를 요청할 수 있다는 점을 알아두면 좋습니다.

```shell
docker container stop <container_id>
```

하지만 이 컨테이너들을 종료하는 가장 쉬운 방법은 다음과 같습니다.

```shell
docker-compose down
```

#### 데이터베이스 초기화하기

Docker Compose 파일은 실행 간 데이터베이스를 유지하기 위해 `db_data` 볼륨을 정의합니다. 데이터베이스를 초기화하는 방법에는 몇 가지가 있습니다.

컨테이너를 종료하는 동시에 `db_data` 볼륨을 제거할 수 있습니다.

```shell
docker-compose down --volumes
```

`docker volume ls`로 현재 데이터를 유지하고 있는 모든 볼륨을 확인할 수 있습니다. Swarm Mode에서 실행 중이었는지 여부에 따라 볼륨 이름에는 일반적으로 `my-dockerized-app_` 또는 `test_` 접두사가 붙습니다.

다음과 같이 이 볼륨들을 하나씩 제거할 수도 있습니다.

```shell
docker volume rm my-dockerized-app_db_data
```

또는 다음과 같이 모든 볼륨을 한꺼번에 정리할 수도 있습니다.

```shell
docker volume prune
```

다만 실수로 유지하고 싶었던 데이터가 담긴 볼륨을 정리해버리지 않도록 주의하세요!

실행 중이거나 중지된 컨테이너가 현재 사용하고 있는 볼륨은 Docker가 제거를 허용하지 않습니다. `docker container ls`로 실행 중인 컨테이너 목록을 확인할 수 있으며, `docker container ls -a`로 중지된 컨테이너까지 확인할 수 있습니다.

### Swarm Mode

Docker Compose 파일을 이미 가지고 있고 앱이 수평으로 어떻게 확장되는지 테스트하고 싶을 때, Swarm Mode는 사용하기 쉬운 인터페이스입니다. Swarm Mode에 대한 모든 내용은 [개요](https://docs.docker.com/engine/swarm/)에 뿌리를 둔 페이지들에서 읽어볼 수 있습니다.

가장 먼저 필요한 것은 Swarm을 위한 매니저 노드입니다. 다음을 실행하세요.

```shell
docker swarm init
```

다음으로, Docker Compose 파일을 사용하여 서비스들을 담은 `'test'`라는 이름의 스택을 띄웁니다.

```shell
docker stack deploy -c docker-compose.yml test
```

다음을 통해 서비스들의 상태를 확인할 수 있습니다.

```shell
docker service ls
```

`app`과 `db` 서비스는 `1/1` 레플리카가, `migrate`와 `revert` 서비스는 `0/0` 레플리카가 보여야 합니다.

Swarm 모드에서 마이그레이션을 실행하려면 다른 명령어를 사용해야 합니다.

```shell
docker service scale --detach test_migrate=1
```

!!! note
    방금 우리는 수명이 짧은 서비스에게 레플리카를 1개로 확장하라고 요청했습니다. 이 서비스는 성공적으로 확장되어 실행된 후 종료됩니다. 하지만 이로 인해 `0/1` 레플리카가 실행 중인 상태로 남게 됩니다. 마이그레이션을 다시 실행하고 싶어지기 전까지는 큰 문제가 되지 않지만, 이미 1개 레플리카에 도달해 있는 상태에서는 "1개 레플리카로 확장"하라고 지시할 수 없습니다. 이 설정의 특이한 점은, 동일한 Swarm 런타임 내에서 다음번에 마이그레이션을 실행하고 싶다면 먼저 서비스를 `0`으로 축소한 다음 다시 `1`로 확장해야 한다는 것입니다.

이 짧은 가이드에서 이러한 수고를 감수한 보람은, 이제 데이터베이스 경합, 크래시 등을 앱이 얼마나 잘 처리하는지 테스트하기 위해 원하는 만큼 앱을 확장할 수 있다는 것입니다.

앱의 인스턴스 5개를 동시에 실행하고 싶다면 다음을 실행하세요.

```shell
docker service scale test_app=5
```

Docker가 앱을 확장하는 과정을 지켜보는 것 외에도, `docker service ls`를 다시 확인해보면 실제로 레플리카 5개가 실행 중인 것을 볼 수 있습니다.

다음을 통해 앱의 로그를 확인(및 팔로우)할 수 있습니다.

```shell
docker service logs -f test_app
```

#### Swarm 서비스 종료하기

Swarm Mode에서 서비스를 종료하고 싶다면, 앞서 생성했던 스택을 제거하면 됩니다.

```shell
docker stack rm test
```

## 프로덕션 배포

앞서 언급했듯이, 이 가이드는 도커라이즈된 앱을 프로덕션에 배포하는 방법을 자세히 다루지 않습니다. 이 주제는 방대하며 호스팅 서비스(AWS, Azure 등), 도구(Terraform, Ansible 등), 오케스트레이션(Docker Swarm, Kubernetes 등)에 따라 크게 달라지기 때문입니다.

하지만 개발 머신에서 도커라이즈된 앱을 로컬로 실행하기 위해 배운 기법들은 대체로 프로덕션 환경에도 적용할 수 있습니다. docker daemon을 실행하도록 설정된 서버 인스턴스는 동일한 명령어를 모두 받아들입니다.

프로젝트 파일을 서버로 복사하고, 서버에 SSH로 접속한 다음, `docker-compose`나 `docker stack deploy` 명령어를 실행하여 원격에서 실행되도록 하세요.

또는 로컬의 `DOCKER_HOST` 환경 변수를 서버를 가리키도록 설정하고, `docker` 명령어를 로컬 머신에서 실행할 수도 있습니다. 이 방식에서는 프로젝트 파일을 서버로 복사할 필요는 없지만, 서버가 이미지를 가져올 수 있는 곳에 Docker 이미지를 호스팅해야 한다는 점에 유의해야 합니다.
