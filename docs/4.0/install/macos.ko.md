# macOS에 Vapor 설치하기

macOS에서 Vapor를 사용하려면 Swift 5.9 이상이 필요합니다. Swift와 그에 필요한 종속성은 Xcode와 함께 번들로 제공됩니다.

## Xcode 설치하기

Mac App Store에서 [Xcode](https://itunes.apple.com/us/app/xcode/id497799835?mt=12)를 설치하세요.

![Xcode in Mac App Store](../images/xcode-mac-app-store.png)

Xcode가 다운로드되면 설치를 완료하기 위해 Xcode를 열어야 합니다. 이 작업은 시간이 걸릴 수 있습니다.

터미널을 열고 Swift 버전을 출력하여 설치가 성공적으로 이루어졌는지 다시 한 번 확인하세요.

```sh
swift --version
```

Swift의 버전 정보가 출력되어야 합니다.

```sh
swift-driver version: 1.75.2 Apple Swift version 5.8 (swiftlang-5.8.0.124.2 clang-1403.0.22.11.100)
Target: arm64-apple-macosx13.0
```

Vapor 4는 Swift 5.9 이상을 필요로 합니다.

## Toolbox 설치하기

Swift 설치가 완료된 후, [Vapor Toolbox](https://github.com/vapor/toolbox)를 설치해 봅니다. 이 CLI 도구는 Vapor를 사용하는 데 필요하지는 않지만, 새 프로젝트를 생성하는 등 유용한 유틸리티를 포함하고 있습니다.

Toolbox는 Homebrew를 통해 배포됩니다. Homebrew를 아직 설치하지 않았다면, <a href="https://brew.sh" target="_blank">brew.sh</a>에서 설치를 합니다.

```sh
brew install vapor
```

Toolbox 설치가 성공적으로 이루어졌는지 확인하기 위해 도움말을 출력해보세요.

```sh
vapor --help
```

사용 가능한 명령어 목록이 표시되어야 합니다.

## 다음 단계

이제 Swift와 Vapor Toolbox를 설치했으므로, [시작하기 &rarr; Hello, world](../getting-started/hello-world.ko.md)에서 첫 번째 앱을 생성해보세요.
