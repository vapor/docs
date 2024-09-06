# 폴더 구조

이제 첫 번째 Vapor 앱을 만들고 빌드하고 실행했으니, Vapor의 폴더 구조에 익숙해지는 시간을 가져보겠습니다. 이 구조는 SPM의 폴더 구조를 기반으로 하기 때문에, 이전에 [SPM](spm.ko.md)을 사용한 적이 있다면 익숙할 것입니다.

```
.
├── Public
├── Sources
│   ├── App
│   │   ├── Controllers
│   │   ├── Migrations
│   │   ├── Models
│   │   ├── configure.swift 
│   │   ├── entrypoint.swift
│   │   └── routes.swift
│       
├── Tests
│   └── AppTests
└── Package.swift
```

아래의 섹션에서는 폴더 구조의 각 부분을 자세히 설명합니다.

## Public

이 폴더에는 `FileMiddleware`가 활성화된 경우 앱에서 제공되는 공개 파일이 포함됩니다. 일반적으로 이미지, 스타일 시트 및 브라우저 스크립트가 여기에 포함됩니다. 예를 들어, `localhost:8080/favicon.ico`로의 요청은 `Public/favicon.ico` 파일의 존재 여부를 확인하고 해당 파일을 반환합니다. 
해당 [https://design.vapor.codes/favicons/favicon.ico](https://design.vapor.codes/favicons/favicon.ico)에 접속하면 Vapor로고 이미지를 확인할 수 있습니다. 

Vapor가 공개 파일을 제공하기 위해선 `configure.swift` 파일에서 `FileMiddleware`를 활성화해야 합니다.


```swift
// Serves files from `Public/` directory
let fileMiddleware = FileMiddleware(
    publicDirectory: app.directory.publicDirectory
)
app.middleware.use(fileMiddleware)
```

## Sources

이 폴더에는 프로젝트의 모든 Swift 소스 파일이 포함됩니다.
최상위 폴더인 `App`은 [SwiftPM](spm.ko.md) 매니페스트에서 선언된 패키지 모듈을 반영합니다.

### App

이 폴더는 애플리케이션 로직이 모두 들어가는 곳입니다.

#### Controllers

컨트롤러는 애플리케이션 로직을 그룹화하는 좋은 방법입니다. 대부분의 컨트롤러에는 요청을 받아들이고 어떤 형태의 응답을 반환하는 많은 함수가 있습니다.

#### Migrations

마이그레이션 폴더는 Fluent를 사용하는 경우 데이터베이스 마이그레이션을 위한 곳입니다.

#### Models

모델 폴더는 `Content` 구조체나 Fluent `Model`을 저장하기 좋은 장소입니다.

#### configure.swift

이 파일에는 `configure(_:)` 함수가 포함되어 있습니다. 이 메서드는 `entrypoint.swift`에 의해 호출되어 새로 생성된 `Application`을 구성합니다. 여기에서 라우트, 데이터베이스, 프로바이더 등과 같은 서비스를 등록해야 합니다.

#### entrypoint.swift

이 파일에는 Vapor 애플리케이션을 설정, 구성 및 실행하는 `@main` 진입점이 포함되어 있습니다.

#### routes.swift

이 파일에는 `routes(_:)` 함수가 포함되어 있습니다. 이 메서드는 `configure(_:)`의 마지막 부분에서 `Application`에 라우트를 등록하는 데 사용됩니다.

## Tests

`Sources` 폴더의 각 비실행(non-executable) 모듈은 `Tests`에 해당하는 폴더를 가질 수 있습니다. 이 폴더에는 패키지를 테스트하기 위해 `XCTest` 모듈을 기반으로 작성된 코드가 포함됩니다. 테스트는 명령줄에서 `swift test`를 사용하거나 Xcode에서 ⌘+U를 눌러 실행할 수 있습니다. 

### AppTests

이 폴더에는 `App` 모듈의 코드를 위한 단위 테스트가 포함되어 있습니다.

## Package.swift

마지막으로 [SPM](spm.ko.md)의 패키지 매니페스트가 있습니다.
