# Supervisor

[Supervisor](http://supervisord.org)는 Vapor 앱을 손쉽게 시작하고, 중지하고, 재시작할 수 있게 해주는 프로세스 제어 시스템입니다.

## 설치

Supervisor는 Linux의 패키지 관리자를 통해 설치할 수 있습니다.

### Ubuntu

```sh
sudo apt-get update
sudo apt-get install supervisor
```

### CentOS와 Amazon Linux

```sh
sudo yum install supervisor
```

### Fedora

```sh
sudo dnf install supervisor
```

## 설정

서버에 있는 각 Vapor 앱은 자신만의 설정 파일을 가져야 합니다. 예를 들어 `Hello` 프로젝트라면 설정 파일은 `/etc/supervisor/conf.d/hello.conf`에 위치하게 됩니다.

```sh
[program:hello]
command=/home/vapor/hello/.build/release/App serve --env production
directory=/home/vapor/hello/
user=vapor
stdout_logfile=/var/log/supervisor/%(program_name)s-stdout.log
stderr_logfile=/var/log/supervisor/%(program_name)s-stderr.log
```

설정 파일에 명시된 대로 `Hello` 프로젝트는 `vapor` 사용자의 홈 폴더에 위치합니다. `directory`가 `Package.swift` 파일이 있는 프로젝트의 루트 디렉터리를 가리키도록 해야 합니다.

`--env production` 플래그는 상세 로깅(verbose logging)을 비활성화합니다.

### 환경 변수

Supervisor를 사용하여 Vapor 앱에 변수를 export할 수 있습니다. 여러 환경 변수 값을 export하려면 모두 한 줄에 작성하세요. [Supervisor 문서](http://supervisord.org/configuration.html#program-x-section-values)에 따르면 다음과 같습니다.

> 영숫자가 아닌 문자를 포함하는 값은 따옴표로 묶어야 합니다(예: KEY="val:123",KEY2="val,456"). 그 외의 경우 값을 따옴표로 묶는 것은 선택 사항이지만 권장됩니다.

```sh
environment=PORT=8123,ANOTHERVALUE="/something/else"
```

Export된 변수는 Vapor에서 `Environment.get`을 사용하여 사용할 수 있습니다.

```swift
let port = Environment.get("PORT")
```

## 시작

이제 앱을 로드하고 시작할 수 있습니다.

```sh
supervisorctl reread
supervisorctl add hello
supervisorctl start hello
```

!!! note
    `add` 명령을 실행하면 이미 앱이 시작되었을 수도 있습니다.
