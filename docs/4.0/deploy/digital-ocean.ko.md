# DigitalOcean에 배포하기

이 가이드는 간단한 Hello, world Vapor 애플리케이션을 [Droplet](https://www.digitalocean.com/products/droplets/)에 배포하는 과정을 안내합니다. 이 가이드를 따라 하려면 결제가 설정된 [DigitalOcean](https://www.digitalocean.com) 계정이 필요합니다.

## 서버 생성

먼저 Linux 서버에 Swift를 설치하는 것부터 시작하겠습니다. 생성 메뉴를 사용하여 새 Droplet을 만드세요.

![Create Droplet](../images/digital-ocean-create-droplet.png)

배포판(distributions)에서 Ubuntu 22.04 LTS를 선택합니다. 이어지는 가이드에서는 이 버전을 예시로 사용합니다.

![Ubuntu Distro](../images/digital-ocean-distributions-ubuntu.png)

!!! note 
    Swift가 지원하는 버전이라면 어떤 Linux 배포판을 선택해도 됩니다. 공식적으로 지원되는 운영체제는 [Swift Releases](https://swift.org/download/#releases) 페이지에서 확인할 수 있습니다.

배포판을 선택한 후, 원하는 플랜과 데이터센터 지역을 선택하세요. 그런 다음 서버가 생성된 후 접속할 수 있도록 SSH 키를 설정합니다. 마지막으로 Droplet 생성을 클릭하고 새 서버가 준비될 때까지 기다립니다.

새 서버가 준비되면 Droplet의 IP 주소 위에 마우스를 올리고 복사를 클릭하세요.

![Droplet List](../images/digital-ocean-droplet-list.png)

## 초기 설정

터미널을 열고 SSH를 사용하여 root로 서버에 접속하세요.

```sh
ssh root@your_server_ip
```

DigitalOcean에서는 [Ubuntu 22.04 초기 서버 설정](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-22-04)에 관한 자세한 가이드를 제공합니다. 이 가이드에서는 기본적인 내용만 간단히 다룹니다.

### 방화벽 설정

방화벽에서 OpenSSH를 허용하고 방화벽을 활성화하세요.

```sh
ufw allow OpenSSH
ufw enable
```

### 사용자 추가

`root` 외에 새 사용자를 생성하세요. 이 가이드에서는 새 사용자를 `vapor`라고 부릅니다.

```sh
adduser vapor
```

새로 생성한 사용자가 `sudo`를 사용할 수 있도록 허용합니다.

```sh
usermod -aG sudo vapor
```

root 사용자의 authorized SSH 키를 새로 생성한 사용자에게 복사하세요. 이렇게 하면 새 사용자로 SSH 접속을 할 수 있습니다.

```sh
rsync --archive --chown=vapor:vapor ~/.ssh /home/vapor
```

마지막으로, 현재 SSH 세션을 종료하고 새로 생성한 사용자로 다시 로그인하세요. 

```sh
exit
ssh vapor@your_server_ip
```

## Swift 설치

새 Ubuntu 서버를 생성하고 root가 아닌 사용자로 로그인했으니, 이제 Swift를 설치할 수 있습니다. 

### Swiftly CLI 도구를 이용한 자동 설치 (권장)

Linux에 Swiftly와 Swift를 설치하는 방법에 대한 안내는 [Swiftly 웹사이트](https://swiftlang.github.io/swiftly/)를 참고하세요. 그런 다음 아래 명령어로 Swift를 설치합니다.

#### 기본 사용법

```sh
$ swiftly install latest

Fetching the latest stable Swift release...
Installing Swift 5.9.1
Downloaded 488.5 MiB of 488.5 MiB
Extracting toolchain...
Swift 5.9.1 installed successfully!

$ swift --version

Swift version 5.9.1 (swift-5.9.1-RELEASE)
Target: x86_64-unknown-linux-gnu
```

## Vapor Toolbox를 이용해 Vapor 설치하기

이제 Swift가 설치되었으니, Vapor Toolbox를 이용해 Vapor를 설치해 보겠습니다. Toolbox는 소스로부터 직접 빌드해야 합니다. GitHub에서 toolbox의 [releases](https://github.com/vapor/toolbox/releases)를 확인하여 최신 버전을 찾으세요. 이 예제에서는 18.6.0을 사용합니다.

### Vapor 클론 및 빌드하기

Vapor Toolbox 저장소를 클론하세요.

```sh
git clone https://github.com/vapor/toolbox.git
```

최신 릴리스로 체크아웃하세요.

```sh
cd toolbox
git checkout 18.6.0
```

Vapor를 빌드하고 바이너리를 path로 이동시키세요.

```sh
swift build -c release --disable-sandbox --enable-test-discovery
sudo mv .build/release/vapor /usr/local/bin
```

### Vapor 프로젝트 생성하기

Toolbox의 new project 명령어를 사용하여 프로젝트를 생성합니다.

```sh
vapor new HelloWorld -n
```

!!! tip
    `-n` 플래그는 모든 질문에 자동으로 아니오라고 답하여 기본적인 템플릿을 제공합니다.

![Vapor Splash](../images/vapor-splash.png)

명령어가 완료되면 새로 생성된 폴더로 이동하세요.

```sh
cd HelloWorld
``` 

### HTTP 포트 열기

서버에서 Vapor에 접속하려면 HTTP 포트를 열어야 합니다.

```sh
sudo ufw allow 8080
```

### 실행하기

Vapor가 설정되고 포트도 열었으니, 이제 실행해 보겠습니다. 

```sh
swift run App serve --hostname 0.0.0.0 --port 8080
```

브라우저나 로컬 터미널을 통해 서버의 IP 주소로 접속하면 "It works!"가 표시되어야 합니다. 이 예제에서 IP 주소는 `134.122.126.139`입니다.

```
$ curl http://134.122.126.139:8080
It works!
```

서버로 돌아가면 테스트 요청에 대한 로그가 표시됩니다.

```
[ NOTICE ] Server starting on http://0.0.0.0:8080
[ INFO ] GET /
```

`CTRL+C`를 사용해 서버를 종료하세요. 종료하는 데 약간의 시간이 걸릴 수 있습니다.

DigitalOcean Droplet에서 Vapor 앱을 실행하는 데 성공하신 것을 축하드립니다!

## 다음 단계

이 가이드의 나머지 부분에서는 배포를 개선하는 데 도움이 되는 추가 리소스를 안내합니다. 

### Supervisor

Supervisor는 Vapor 실행 파일을 실행하고 모니터링할 수 있는 프로세스 제어 시스템입니다. Supervisor를 설정하면 서버가 부팅될 때 앱이 자동으로 시작되고, 충돌이 발생했을 때 재시작될 수 있습니다. [Supervisor](../deploy/supervisor.md)에 대해 더 알아보세요.

### Nginx

Nginx는 매우 빠르고, 검증되었으며, 설정하기 쉬운 HTTP 서버이자 프록시입니다. Vapor는 HTTP 요청을 직접 처리하는 것을 지원하지만, Nginx 뒤에서 프록시를 사용하면 성능, 보안, 그리고 사용 편의성을 향상시킬 수 있습니다. [Nginx](../deploy/nginx.md)에 대해 더 알아보세요.
