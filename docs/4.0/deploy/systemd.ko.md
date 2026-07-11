# Systemd

Systemd는 대부분의 Linux 배포판에서 기본으로 제공되는 시스템 및 서비스 관리자입니다. 지원되는 Swift 배포판에서는 보통 기본으로 설치되어 있으므로 별도의 설치가 필요하지 않습니다.

## 설정

서버에 있는 각 Vapor 앱은 자신만의 서비스 파일을 가져야 합니다. 예를 들어 `Hello`라는 프로젝트라면, 설정 파일은 `/etc/systemd/system/hello.service`에 위치하게 됩니다. 이 파일은 다음과 같은 형태여야 합니다.

```sh
[Unit]
Description=Hello
Requires=network.target
After=network.target

[Service]
Type=simple
User=vapor
Group=vapor
Restart=always
RestartSec=3
WorkingDirectory=/home/vapor/hello
ExecStart=/home/vapor/hello/.build/release/App serve --env production
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=vapor-hello

[Install]
WantedBy=multi-user.target
```

설정 파일에 명시된 대로 `Hello` 프로젝트는 `vapor` 사용자의 홈 폴더에 위치합니다. `WorkingDirectory`가 `Package.swift` 파일이 있는 프로젝트의 루트 디렉터리를 가리키도록 해야 합니다.

`--env production` 플래그는 상세 로깅(verbose logging)을 비활성화합니다.

### 환경 변수
그 외의 경우, 값을 따옴표로 묶는 것은 선택 사항이지만 권장됩니다.

systemd를 통해 변수를 내보내는 방법은 두 가지입니다. 하나는 모든 변수를 설정해 둔 환경 파일을 만드는 방법입니다.

```sh
EnvironmentFile=/path/to/environment/file1
EnvironmentFile=/path/to/environment/file2
```


또는 서비스 파일의 `[service]` 항목 아래에 직접 추가할 수도 있습니다.

```sh
Environment="PORT=8123"
Environment="ANOTHERVALUE=/something/else"
```
내보낸 변수는 Vapor에서 `Environment.get`을 사용하여 사용할 수 있습니다.

```swift
let port = Environment.get("PORT")
```

## 시작

이제 root 권한으로 다음을 실행하여 앱을 load, enable, start, stop, restart 할 수 있습니다.

```sh
systemctl daemon-reload
systemctl enable hello
systemctl start hello
systemctl stop hello
systemctl restart hello
```
