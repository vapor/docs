# Leaf

Leaf는 Swift에서 영감을 받은 문법을 가진 강력한 템플릿 언어입니다. 프론트엔드 웹사이트를 위한 동적 HTML 페이지를 생성하거나 API에서 보낼 풍부한 이메일을 생성하는 데 사용할 수 있습니다.

## 패키지

Leaf를 사용하기 위한 첫 단계는 SPM 패키지 매니페스트 파일에 종속성으로 추가하는 것입니다.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        /// Any other dependencies ...
        .package(url: "https://github.com/vapor/leaf.git", from: "4.4.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "Leaf", package: "leaf"),
            // Any other dependencies
        ]),
        // Other targets
    ]
)
```

## 설정

패키지를 프로젝트에 추가했다면, Vapor가 이를 사용하도록 설정할 수 있습니다. 이는 보통 [`configure.swift`](../getting-started/folder-structure.md#configureswift)에서 수행됩니다.

```swift
import Leaf

app.views.use(.leaf)
```

이렇게 하면 코드에서 `req.view`를 호출할 때 Vapor가 `LeafRenderer`를 사용하도록 지시합니다.

!!! warning 
    Xcode에서 실행할 때 Leaf가 템플릿을 찾을 수 있으려면, Xcode 워크스페이스에 대해 [사용자 지정 작업 디렉토리](../getting-started/xcode.md#custom-working-directory)를 설정해야 합니다.

### 페이지 렌더링을 위한 캐시

Leaf는 페이지 렌더링을 위한 내부 캐시를 가지고 있습니다. `Application`의 환경이 `.development`로 설정되면, 템플릿에 대한 변경 사항이 즉시 적용되도록 이 캐시는 비활성화됩니다. `.production` 및 그 밖의 모든 환경에서는 기본적으로 캐시가 활성화됩니다. 템플릿에 대한 모든 변경 사항은 애플리케이션이 재시작될 때까지 적용되지 않습니다.

Leaf의 캐시를 비활성화하려면 다음과 같이 하세요.

```swift
app.leaf.cache.isEnabled = false
```

!!! warning
    캐시를 비활성화하는 것은 디버깅에는 도움이 되지만, 모든 요청마다 템플릿을 다시 컴파일해야 하므로 성능에 상당한 영향을 미칠 수 있어 프로덕션 환경에는 권장되지 않습니다.

## 폴더 구조

Leaf를 설정했다면, `.leaf` 파일을 저장할 `Views` 폴더가 있는지 확인해야 합니다. 기본적으로 Leaf는 views 폴더가 프로젝트 루트를 기준으로 `./Resources/Views`일 것으로 예상합니다.

또한 예를 들어 Javascript 및 CSS 파일을 제공할 계획이라면, `/Public` 폴더에서 파일을 제공하기 위해 Vapor의 [`FileMiddleware`](https://api.vapor.codes/vapor/documentation/vapor/filemiddleware)를 활성화하고 싶을 것입니다.

```
VaporApp
├── Package.swift
├── Resources
│   ├── Views
│   │   └── hello.leaf
├── Public
│   ├── images (images resources)
│   ├── styles (css resources)
└── Sources
    └── ...
```

## 뷰 렌더링

이제 Leaf가 설정되었으니, 첫 번째 템플릿을 렌더링해 보겠습니다. `Resources/Views` 폴더 안에, 다음 내용으로 `hello.leaf`라는 새 파일을 만드세요.

```leaf
Hello, #(name)!
```

!!! tip
    코드 에디터로 VSCode를 사용하는 경우, 구문 강조를 활성화하기 위해 Vapor 확장 프로그램을 설치하는 것을 권장합니다: [Vapor for VS Code](https://marketplace.visualstudio.com/items?itemName=Vapor.vapor-vscode).

그런 다음, 뷰를 렌더링하기 위한 라우트를 등록합니다(보통 `routes.swift`나 컨트롤러에서 수행됩니다).

```swift
app.get("hello") { req -> EventLoopFuture<View> in
    return req.view.render("hello", ["name": "Leaf"])
}

// or

app.get("hello") { req async throws -> View in
    return try await req.view.render("hello", ["name": "Leaf"])
}
```

이는 Leaf를 직접 호출하는 대신 `Request`의 일반적인 `view` 속성을 사용합니다. 이를 통해 테스트에서 다른 렌더러로 전환할 수 있습니다.


브라우저를 열고 `/hello`를 방문하세요. `Hello, Leaf!`가 표시되어야 합니다. 첫 번째 Leaf 뷰 렌더링을 축하합니다!
