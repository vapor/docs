# 리눅스에 Vapor 설치하기

Vapor를 사용하려면 Swift 5.9 이상이 필요합니다. Swift Server Workgroup에서 제공하는 CLI 도구인 [Swiftly](https://swiftlang.github.io/swiftly/)를 사용하여 설치하는 것을 권장하며, [Swift.org](https://swift.org/download/)에서 제공하는 툴체인을 사용하여 설치할 수도 있습니다.

## 지원되는 배포판 및 버전

Vapor는 Swift 5.9 이상의 버전이 지원하는 것과 동일한 Linux 배포판 버전을 지원합니다. 공식적으로 지원되는 운영 체제에 대한 최신 정보는 [공식 지원 페이지](https://www.swift.org/platform-support/)를 참조하세요.

공식적으로 지원되지 않는 Linux 배포판도 소스 코드를 컴파일하여 Swift를 실행할 수 있지만, Vapor는 안정성을 보장할 수 없습니다. Swift 컴파일 방법에 대해서는 [Swift 저장소](https://github.com/apple/swift#getting-started)에서 자세히 알아보세요.

## Swift 설치하기

### Swiftly CLI 도구를 사용한 자동 설치 (권장)

Linux에 Swiftly와 Swift를 설치하는 방법은 [Swiftly 웹사이트](https://swiftlang.github.io/swiftly/)를 참조하세요. 설치 후, 다음 명령어로 Swift를 설치합니다.

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

### 툴체인을 사용한 수동 설치

Swift를 Linux에 설치하는 방법은 Swift.org의 [다운로드 및 사용하기](https://swift.org/download/#using-downloads) 가이드를 참조하세요.

### Fedora

Fedora 사용자는 다음 명령어를 사용하여 Swift를 설치할 수 있습니다.

```sh
sudo dnf install swift-lang
```

Fedora 35를 사용하는 경우, Swift 5.9 이상 버전을 얻기 위해 EPEL 8을 추가해야 합니다.

## Docker

Swift의 공식 Docker 이미지를 사용하여 미리 컴파일된 컴파일러를 사용할 수도 있습니다. [Swift's Docker Hub](https://hub.docker.com/_/swift)에서 더 자세한 내용을 알아보세요.

## Toolbox 설치하기

이제 Swift가 설치되었으므로 [Vapor Toolbox](https://github.com/vapor/toolbox)를 설치해봅시다. 이 CLI 도구는 Vapor를 사용하는 데 필수적이지는 않지만, 새 Vapor 프로젝트를 생성하는 데 도움을 줍니다.

### Homebrew

Toolbox는 Homebrew를 통해 배포됩니다. Homebrew를 아직 설치하지 않았다면, <a href="https://brew.sh" target="_blank">brew.sh</a>에서 설치 방법을 확인하세요.

```sh
brew install vapor
```

도움말을 출력하여 설치가 성공적으로 이루어졌는지 다시 한번 확인하세요.

```sh
vapor --help
```

사용 가능한 명령어 목록이 표시되어야 합니다.

### Makefile

원한다면 Toolbox를 소스 코드로부터 빌드할 수도 있습니다. GitHub에서 Toolbox의 <a href="https://github.com/vapor/toolbox/releases" target="_blank">releases</a>를 확인하여 최신 버전을 찾아보세요.

```sh
git clone https://github.com/vapor/toolbox.git
cd toolbox
git checkout <desired version>
make install
```

Toolbox 설치가 성공적으로 이루어졌는지 확인하기 위해 도움말을 출력해보세요.

```sh
vapor --help
```

사용 가능한 명령어 목록이 표시되어야 합니다.

## 다음 단계

이제 Swift와 Vapor Toolbox를 설치했으므로, [시작하기 &rarr; Hello, world](../getting-started/hello-world.ko.md)에서 첫 번째 앱을 생성해보세요.
