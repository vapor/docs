# Fly

Fly는 엣지 컴퓨팅에 중점을 두고 서버 애플리케이션과 데이터베이스를 실행할 수 있게 해주는 호스팅 플랫폼입니다. 더 많은 정보는 [Fly 웹사이트](https://fly.io/)를 참고하세요.

!!! note
    이 문서에 명시된 명령어들은 [Fly의 요금 정책](https://fly.io/docs/about/pricing/)의 적용을 받으므로, 계속 진행하기 전에 이를 제대로 이해했는지 확인하세요.

## 가입하기
계정이 없다면, [계정을 만들어야](https://fly.io/app/sign-up) 합니다.

## flyctl 설치하기
Fly와 상호작용하는 주된 방법은 전용 CLI 도구인 `flyctl`을 사용하는 것이며, 이를 설치해야 합니다.

### macOS
```bash
brew install flyctl
```

### Linux
```bash
curl -L https://fly.io/install.sh | sh
```

### 다른 설치 방법
더 많은 옵션과 세부 사항은 [`flyctl` 설치 문서](https://fly.io/docs/flyctl/install/)를 참고하세요.

## 로그인하기
터미널에서 로그인하려면 다음 명령어를 실행하세요.
```bash
fly auth login
```

## Vapor 프로젝트 설정하기
Fly에 배포하기 전에, 적절히 설정된 Dockerfile을 가진 Vapor 프로젝트가 있는지 확인해야 합니다. Fly는 앱을 빌드하는 데 이를 필요로 하기 때문입니다. 기본 Vapor 템플릿에는 이미 Dockerfile이 포함되어 있으므로, 대부분의 경우 매우 쉽게 진행할 수 있습니다.

### 새로운 Vapor 프로젝트
새 프로젝트를 만드는 가장 쉬운 방법은 템플릿으로 시작하는 것입니다. GitHub 템플릿이나 Vapor 툴박스를 사용해서 만들 수 있습니다. 데이터베이스가 필요하다면, Fluent와 Postgres를 사용하는 것을 권장합니다. Fly는 앱과 연결할 Postgres 데이터베이스를 쉽게 만들 수 있게 해줍니다 (아래의 [전용 섹션](#configuring-postgres)을 참고하세요).

#### Vapor 툴박스 사용하기
먼저, Vapor 툴박스가 설치되어 있는지 확인하세요 ([macOS](../install/macos.md#install-toolbox) 또는 [Linux](../install/linux.md#install-toolbox)의 설치 지침을 참고하세요).
다음 명령어로 원하는 앱 이름을 `app-name` 대신 입력해서 새 앱을 만드세요.
```bash
vapor new app-name
```

이 명령어는 Vapor 프로젝트를 설정할 수 있는 대화형 프롬프트를 표시하며, 필요하다면 여기서 Fluent와 Postgres를 선택할 수 있습니다.

#### GitHub 템플릿 사용하기
다음 목록에서 필요에 가장 적합한 템플릿을 선택하세요. Git을 사용해서 로컬로 클론하거나 "Use this template" 버튼으로 GitHub 프로젝트를 만들 수 있습니다.

- [Barebones 템플릿](https://github.com/vapor/template-bare)
- [Fluent/Postgres 템플릿](https://github.com/vapor/template-fluent-postgres)
- [Fluent/Postgres + Leaf 템플릿](https://github.com/vapor/template-fluent-postgres-leaf)

### 기존 Vapor 프로젝트
기존 Vapor 프로젝트가 있다면, 디렉토리 루트에 적절히 설정된 `Dockerfile`이 있는지 확인하세요. [Docker 사용에 대한 Vapor 문서](../deploy/docker.md)와 [Dockerfile을 통해 앱을 배포하는 것에 대한 Fly 문서](https://fly.io/docs/languages-and-frameworks/dockerfile/)가 도움이 될 수 있습니다.

## Fly에서 앱 실행하기
Vapor 프로젝트 준비가 끝났다면, 이를 Fly에서 실행할 수 있습니다.

먼저, 현재 디렉토리가 Vapor 애플리케이션의 루트 디렉토리로 설정되어 있는지 확인하고 다음 명령어를 실행하세요.
```bash
fly launch
```

이 명령어는 Fly 애플리케이션 설정을 구성할 수 있는 대화형 프롬프트를 시작합니다.

- **이름:** 이름을 입력하거나, 비워두면 자동으로 생성된 이름을 받을 수 있습니다.
- **지역:** 기본값은 사용자와 가장 가까운 지역입니다. 이를 사용하거나 목록에 있는 다른 지역을 선택할 수 있습니다. 나중에 쉽게 변경할 수 있습니다.
- **데이터베이스:** Fly에게 앱과 함께 사용할 데이터베이스를 만들어 달라고 요청할 수 있습니다. 원한다면 나중에 `fly pg create`와 `fly pg attach` 명령어로 동일한 작업을 할 수도 있습니다 (자세한 내용은 [Postgres 설정하기 섹션](#configuring-postgres)을 참고하세요).

`fly launch` 명령어는 자동으로 `fly.toml` 파일을 생성합니다. 이 파일에는 private/public 포트 매핑, 헬스 체크 매개변수 등 다양한 설정이 포함됩니다. `vapor new`로 새 프로젝트를 처음부터 만들었다면, 기본 `fly.toml` 파일은 변경할 필요가 없습니다. 기존 프로젝트가 있다면, `fly.toml`도 변경이 없거나 약간의 수정만으로 괜찮을 가능성이 높습니다. 더 많은 정보는 [`fly.toml` 문서](https://fly.io/docs/reference/configuration/)에서 확인할 수 있습니다.

Fly에게 데이터베이스를 만들어 달라고 요청한 경우, 데이터베이스가 생성되고 헬스 체크를 통과할 때까지 조금 기다려야 한다는 점을 참고하세요.

종료하기 전에, `fly launch` 명령어는 앱을 바로 배포할지 물어봅니다. 이를 승낙하거나 나중에 `fly deploy`를 사용해서 배포할 수 있습니다.

!!! tip
    현재 디렉토리가 앱의 루트에 있으면, fly CLI 도구는 `fly.toml` 파일의 존재를 자동으로 감지해서 Fly에게 어떤 앱을 대상으로 명령어를 실행할지 알려줍니다. 현재 디렉토리와 상관없이 특정 앱을 대상으로 지정하고 싶다면, 대부분의 Fly 명령어에 `-a name-of-your-app`을 추가할 수 있습니다.

## 배포하기
Fly에 새로운 변경 사항을 배포해야 할 때마다 `fly deploy` 명령어를 실행합니다.

Fly는 디렉토리의 `Dockerfile`과 `fly.toml` 파일을 읽어서 Vapor 프로젝트를 빌드하고 실행하는 방법을 결정합니다.

컨테이너가 빌드되면, Fly는 그 인스턴스를 시작합니다. 애플리케이션이 정상적으로 실행 중이고 서버가 요청에 응답하는지 확인하기 위해 다양한 헬스 체크를 실행합니다. 헬스 체크가 실패하면 `fly deploy` 명령어는 오류와 함께 종료됩니다.

기본적으로, 배포하려는 새 버전의 헬스 체크가 실패하면 Fly는 앱의 마지막으로 정상 작동했던 버전으로 롤백합니다.

백그라운드 워커를 배포할 때 (Vapor Queues 사용). Dockerfile의 CMD나 ENTRYPOINT를 변경하지 마세요. 그대로 두어야 메인 웹 애플리케이션이 정상적으로 시작됩니다. 대신, `fly.toml` 파일에 다음과 같이 [processes] 섹션을 추가하세요.

```
[processes]
  app = ""
  worker = "queues"
```

이렇게 하면 Fly.io는 기본 Docker entrypoint(웹 서버)로 app 프로세스를 실행하고, worker 프로세스는 Vapor의 커맨드 라인 인터페이스(즉, `swift run App queues`)를 사용해서 작업 큐를 실행합니다.

## Postgres 설정하기

### Fly에서 Postgres 데이터베이스 만들기
앱을 처음 실행할 때 데이터베이스 앱을 만들지 않았다면, 나중에 다음 명령어로 만들 수 있습니다.
```bash
fly pg create
```

이 명령어는 Fly의 다른 앱들이 사용할 수 있는 데이터베이스를 호스팅할 Fly 앱을 생성합니다. 자세한 내용은 [Fly의 전용 문서](https://fly.io/docs/postgres/)를 참고하세요.

데이터베이스 앱이 생성되면, Vapor 앱의 루트 디렉토리로 이동해서 다음을 실행하세요.
```bash
fly pg attach name-of-your-postgres-app
```
Postgres 앱의 이름을 모른다면 `fly pg list`로 확인할 수 있습니다.

`fly pg attach` 명령어는 앱을 위한 데이터베이스와 사용자를 생성한 다음, `DATABASE_URL` 환경 변수를 통해 앱에 노출시킵니다.

!!! note
    `fly pg create`와 `fly pg attach`의 차이점은, 전자는 Postgres 데이터베이스를 호스팅할 수 있는 Fly 앱을 할당하고 설정하는 반면, 후자는 원하는 앱을 위한 실제 데이터베이스와 사용자를 생성한다는 것입니다. 요구 사항에 맞다면, 하나의 Postgres Fly 앱이 여러 앱에서 사용하는 여러 데이터베이스를 호스팅할 수도 있습니다. `fly launch`에서 Fly에게 데이터베이스 앱을 만들어 달라고 요청하면, `fly pg create`와 `fly pg attach`를 모두 호출하는 것과 동일하게 작동합니다.

### Vapor 앱을 데이터베이스에 연결하기
앱이 데이터베이스에 연결되면, Fly는 자격 증명이 포함된 연결 URL을 `DATABASE_URL` 환경 변수에 설정합니다 (이는 민감한 정보로 취급해야 합니다).

대부분의 일반적인 Vapor 프로젝트 설정에서는, `configure.swift`에서 데이터베이스를 설정합니다. 다음은 이를 수행하는 방법의 예시입니다.

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

이 시점에서, 프로젝트는 마이그레이션을 실행하고 데이터베이스를 사용할 준비가 되어 있어야 합니다.

### 마이그레이션 실행하기
`fly.toml`의 `release_command`를 사용하면, Fly에게 메인 서버 프로세스를 실행하기 전에 특정 명령어를 실행하도록 요청할 수 있습니다. `fly.toml`에 다음을 추가하세요.
```toml
[deploy]
 release_command = "migrate -y"
```

!!! note
    위 코드 스니펫은 앱의 `ENTRYPOINT`를 `./App`으로 설정하는 기본 Vapor Dockerfile을 사용한다고 가정합니다. 구체적으로, `release_command`를 `migrate -y`로 설정하면 Fly는 `./App migrate -y`를 호출합니다. `ENTRYPOINT`가 다른 값으로 설정되어 있다면, `release_command` 값을 그에 맞게 조정해야 합니다.

Fly는 내부 Fly 네트워크, 시크릿, 환경 변수에 접근할 수 있는 임시 인스턴스에서 릴리스 명령어를 실행합니다.

릴리스 명령어가 실패하면 배포는 계속 진행되지 않습니다.

### 다른 데이터베이스
Fly는 Postgres 데이터베이스 앱을 쉽게 만들 수 있게 해주지만, 다른 종류의 데이터베이스도 호스팅할 수 있습니다 (예를 들어 Fly 문서의 ["MySQL 데이터베이스 사용하기"](https://fly.io/docs/app-guides/mysql-on-fly/)를 참고하세요).

## 시크릿과 환경 변수
### 시크릿
민감한 값을 환경 변수로 설정하려면 시크릿을 사용하세요.
```bash
 fly secrets set MYSECRET=A_SUPER_SECRET_VALUE
```

!!! warning
    대부분의 셸이 입력한 명령어의 기록을 보관한다는 점을 유의하세요. 이 방법으로 시크릿을 설정할 때는 주의하세요. 일부 셸은 공백으로 시작하는 명령어를 기억하지 않도록 설정할 수 있습니다. [`fly secrets import` 명령어](https://fly.io/docs/flyctl/secrets-import/)도 참고하세요.

더 많은 정보는 [`fly secrets` 문서](https://fly.io/docs/apps/secrets/)를 참고하세요.

### 환경 변수
다른 민감하지 않은 [환경 변수는 `fly.toml`에서](https://fly.io/docs/reference/configuration/#the-env-variables-section) 설정할 수 있습니다. 예를 들면 다음과 같습니다.
```toml
[env]
  MAX_API_RETRY_COUNT = "3"
  SMS_LOG_LEVEL = "error"
```

## SSH 연결
다음을 사용해서 앱의 인스턴스에 연결할 수 있습니다.
```bash
fly ssh console -s
```

## 로그 확인하기
다음을 사용해서 앱의 실시간 로그를 확인할 수 있습니다.
```bash
fly logs
```

## 다음 단계
이제 Vapor 앱이 배포되었으니, 여러 지역에 걸쳐 앱을 수직 및 수평으로 확장하거나, 영구 볼륨을 추가하거나, 지속적 배포를 설정하거나, 심지어 분산 앱 클러스터를 만드는 등 할 수 있는 일이 훨씬 더 많습니다. 이 모든 것과 그 이상을 배우기 가장 좋은 곳은 [Fly 문서](https://fly.io/docs/)입니다.
