# Hello, world

해당 가이드문서에서는 새로운 Vapor 프로젝트를 만들고, 빌드하고, 서버를 실행하는 단계별 절차를 안내합니다.

아직 Swift 또는 Vapor Toolbox를 설치하지 않았다면 하단에 운영체제에 맞게 설치하기 문서를 확인하세요.

- [Install &rarr; macOS](../install/macos.kr.md)
- [Install &rarr; Linux](../install/linux.kr.md)

## 새 프로젝트 생성하기

첫 번째 단계는 컴퓨터에 새로운 Vapor 프로젝트를 만드는 것입니다. 터미널을 열고 Toolbox의 새 프로젝트 명령을 사용하세요. 이렇게 하면 현재 디렉토리에 새 폴더가 생성되며 프로젝트가 포함됩니다.

```sh
vapor new hello -n
```

!!! 팁
	`-n` 플래그를 사용하면 모든 질문에 자동으로 "no"로 대답하여 기본 템플릿을 얻을 수 있습니다.

!!! 팁
    Vapor Toolbox 없이도 [템플릿 저장소](https://github.com/vapor/template-bare)를 클론하여 GitHub에서 최신 템플릿을 사용할 수 있습니다.

!!! 팁
  Vapor와 템플릿은 이제 기본적으로 `async`/`await`을 사용합니다. macOS 12로 업데이트할 수 없거나 EventLoopFuture를 계속 사용해야 하는 경우 `--branch macos10-15` 플래그를 사용하세요.
  
명령이 완료되면 새로 생성된 폴더로 이동하세요.


```sh
cd hello
```

## 빌드 & 실행

### Xcode

먼저, Xcode에서 프로젝트를 엽니다.

```sh
open Package.swift
```

Swift Package Manager 종속성을 자동으로 다운로드하기 시작합니다. 이는 프로젝트를 처음 열 때는 시간이 걸릴 수 있습니다. 종속성 해결이 완료되면 Xcode에서 사용 가능한 스키마가 표시됩니다.

창 상단에서 재생 및 정지 버튼 오른쪽에 프로젝트 이름을 클릭하여 프로젝트의 스키마를 선택하고 적절한 실행 대상(아마도 "My Mac")을 선택하세요. 재생 버튼을 클릭하여 프로젝트를 빌드하고 실행합니다.

Xcode 창 하단에 콘솔이 아래처럼 보일 것입니다.

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

### Linux

Linux 및 다른 운영 체제(또는 macOS에서 Xcode를 사용하지 않을 경우)에서는 Vim이나 VSCode와 같은 즐겨찾는 편집기에서 프로젝트를 편집할 수 있습니다. 다른 IDE를 설정하는 방법에 대한 최신 정보는 [Swift Server Guides](https://github.com/swift-server/guides/blob/main/docs/setup-and-ide-alternatives.md)를 참조하세요.

프로젝트를 빌드하고 실행하려면 터미널에서 다음 명령을 실행합니다.

```sh
swift run
```

이 명령은 프로젝트를 빌드하고 실행합니다. 처음 실행할 때는 종속성을 가져오고 해결하는 데 시간이 걸립니다. 실행 중에는 콘솔에서 다음과 같은 출력을 볼 수 있어야 합니다.

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

## Localhost 접속해보기

웹 브라우저를 열고, <a href="http://localhost:8080/hello" target="_blank">localhost:8080/hello</a> 또는 <a href="http://127.0.0.1:8080" target="_blank">http://127.0.0.1:8080</a>을 접속해봅니다.

해당 웹페이지에서는 다음과 같이 표시되어야 합니다.

```html
Hello, world!
```

첫 번째 Vapor앱을 만들고 빌드하고 실행한 것을 축하드립니다! 🎉
