# 리눅스에 Vapor 설치하기

Vapor를 사용하려면 Swift 5.6 이상이 필요합니다. 리눅스에 Swift를 설치하려면, [Swift.org](https://swift.org/download/)에서 제공하는 툴체인을 사용하여 설치할 수 있습니다.

## 지원되는 배포판 및 버전

Vapor는 Swift 5.6 이상을 지원하는 Linux 배포판의 동일한 버전을 지원합니다.

!!! 노트
    아래에 나열된 지원되는 버전은 언제든지 최신 정보가 아닐 수 있습니다. 공식적으로 지원되는 운영 체제는 [Swift Releases](https://swift.org/download/#releases) 페이지에서 확인할 수 있습니다.

|배포판|버전|Swift 버전|
|-|-|-|
|Ubuntu|20.04|>= 5.6|
|Fedora|>= 30|>= 5.6|
|CentOS|8|>= 5.6|
|Amazon Linux|2|>= 5.6|

공식적으로 지원되지 않는 Linux 배포판은 소스 코드를 컴파일하여 Swift를 실행할 수 있지만, Vapor는 안정성을 보장할 수 없습니다. Swift의 컴파일 방법에 대해서는 [Swift 저장소](https://github.com/apple/swift#getting-started)에서 자세히 알아보세요.

## Swift 설치하기

Swift를 Linux에 설치하는 방법은 Swift.org의 [다운로드 및 사용하기](https://swift.org/download/#using-downloads) 가이드를 참조하세요.

### Fedora

Fedora 사용자는 다음 명령어를 사용하여 Swift를 설치할 수 있습니다.

```sh
sudo dnf install swift-lang
```

Fedora 30을 사용하는 경우, Swift 5.6 이상 버전을 얻기 위해 EPEL 8을 추가해야 합니다.

## Docker

Swift의 공식 Docker 이미지를 사용하여 미리 컴파일된 컴파일러를 사용할 수도 있습니다. [Swift's Docker Hub](https://hub.docker.com/_/swift)에서 더 자세한 내용을 알아보세요.

## Toolbox 설치하기

이제 Swift가 설치되었으므로 [Vapor Toolbox](https://github.com/vapor/toolbox)를 설치해봅시다. 이 CLI 도구는 Vapor를 사용하는 데 필수적이지는 않지만, 유용한 유틸리티를 제공합니다.

Linux에서는 Toolbox를 소스 코드로부터 빌드해야 합니다. GitHub에서 toolbox의 <a href="https://github.com/vapor/toolbox/releases" target="_blank">releases</a>를 확인하여 최신 버전을 찾아보세요.

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

Swift를 설치한 후 [시작하기 &rarr; Hello, world](../getting-started/hello-world.kr.md)에서 첫 번째 앱을 생성하세요.
