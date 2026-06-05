# Swift Package Manager

[Swift Package Manager](https://swift.org/package-manager/) (SPM)은 프로젝트의 소스 코드 및 종속성을 빌드하는 데 사용됩니다. Vapor는 SPM을 강력하게 활용하므로 SPM의 기본 원리를 이해하는 것이 좋습니다.

SPM은 Cocoapods, Ruby Gems 및 NPM과 유사합니다. `swift build` 및 `swift test`와 같은 명령어로 command line(커맨드라인)에서 SPM을 사용할 수 있으며, 호환되는 IDE에서도 사용할 수 있습니다. 그러나 다른 일부 패키지 관리자와는 달리 SPM은 중앙 패키지 인덱스가 없습니다. 대신 SPM은 Git 저장소의 URL을 활용하며, [Git tags](https://git-scm.com/book/en/v2/Git-Basics-Tagging)를 사용하여 버전 의존성을 관리합니다.

## Package Manifest

SPM이 프로젝트에서 먼저 찾는 곳은 Package Manifest입니다. 이는 프로젝트의 루트 디렉토리에 있어야 하며 `Package.swift`로 이름이 지정되어야 합니다.

다음은 Package Manifest의 예입니다.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
```

각 부분에 대한 Package Manifest의 설명은 다음 섹션에서 설명됩니다.

### Tools Version

패키지 매니페스트의 맨 첫 줄은 필요한 Swift tool 버전을 나타냅니다. 이는 패키지가 지원하는 Swift의 최소 버전을 지정합니다. 패키지 설명 API도 Swift 버전에 따라 변경될 수 있으므로, 이 줄은 Swift가 매니페스트를 올바르게 구문 분석할 수 있도록 합니다.

### Package Name

`Package`의 첫 번째 인자는 패키지의 이름입니다. 패키지가 공개된 경우, 이름으로 Git 저장소 URL의 마지막 세그먼트를 사용해야 합니다.

### Platforms

`platforms` 배열은 이 패키지가 지원하는 플랫폼을 지정합니다. .macOS(.v12)를 지정함으로써 이 패키지는 macOS 12 이상을 필요로 합니다. Xcode가 이 프로젝트를 로드할 때, 사용 가능한 모든 API를 사용할 수 있도록 macOS 12의 최소 배포 버전을 자동으로 설정합니다.

### Dependencies

종속성은 패키지가 의존하는 다른 SPM 패키지입니다. 모든 Vapor 애플리케이션은 Vapor 패키지에 의존하지만, 원하는 만큼 많은 종속성을 추가할 수 있습니다.

위의 예제에서는 [vapor/vapor](https://github.com/vapor/vapor) 버전 4.76.0 이상이 이 패키지의 종속성으로 지정되어 있습니다. 패키지에 종속성을 추가할 때, 새로 추가된 모듈에 의존하는 [타겟](#targets)을 알려줘야 합니다.

### Targets

타겟은 패키지에 포함된 모듈, 실행 파일 및 테스트입니다. 대부분의 Vapor 앱은 두 개의 타겟을 가지지만, 코드를 구성하기 위해 필요에 따라 원하는 만큼 추가할 수 있습니다. 각 타겟은 어떤 모듈에 의존하는지를 선언해야 합니다. 코드에서 모듈을 가져오려면 여기에 모듈 이름을 추가해야 합니다. 타겟은 프로젝트 내의 다른 타겟이나 추가한 패키지에서 노출된 모듈에 의존할 수 있습니다.

타겟은 패키지에 포함된 모든 모듈, 실행 파일 및 테스트입니다. 대부분의 Vapor 앱은 두 개의 타겟을 가지지만, 코드를 구성하기 위해 필요에 따라 원하는 만큼 추가할 수 있습니다. 각 타겟은 어떤 모듈에 의존하는지를 선언해야 합니다. 모듈을 코드에서 가져오려면 여기에 모듈 이름을 추가해야 합니다. 타겟은 프로젝트 내의 다른 타겟이나 [main dependencies](#dependencies)배열에 추가한 패키지의 모듈에 의존할 수 있습니다.

## Folder Structure

아래는 SPM 패키지의 전형적인 폴더 구조입니다.

```
.
├── Sources
│   └── App
│       └── (Source code)
├── Tests
│   └── AppTests
└── Package.swift
```

각 `.target` 또는 `.executableTarget`은 `Sources` 폴더의 하위 폴더와 대응합니다.
각 `.testTarget`은 `Tests` 폴더의 하위 폴더와 대응합니다.

## Package.resolved

프로젝트를 처음 빌드할 때 SPM은 각 종속성의 버전을 저장하는 `Package.resolved` 파일을 생성합니다. 프로젝트를 다음으로 빌드할 때에도 새로운 버전이 있더라도 동일한 버전이 사용됩니다.

종속성을 업데이트하려면 `swift package update` 명령을 실행하세요.

## Xcode

Xcode 11 이상을 사용하는 경우 `Package.swift` 파일이 수정될 때마다 종속성, 타겟, products 등의 변경이 자동으로 반영됩니다.

최신 종속성으로 업데이트하려면 File &rarr; Swift Packages &rarr; Update To Latest Swift Package Versions을 사용하세요.

또한 `.swiftpm` 파일을 `.gitignore`에 추가하는 것이 좋습니다. 이곳에는 Xcode가 Xcode 프로젝트 구성을 저장합니다.
