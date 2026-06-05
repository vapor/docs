# 환경설정(Environment)

Vapor의 환경설정 API는 앱을 동적으로 설정할 수 있도록 합니다. 앱은 기본적으로 `development` 환경을 사용합니다. `production`이나 `staging` 같은 유용한 다른 환경을 정의할 수 있고, 각 케이스마다 다르게 설정할 수 있습니다. 필요에 따라 프로세스의 환경이나 `.env` 파일의 변수들을 사용할 수 있습니다.

`app.environment`를 사용해서 현재 환경설정에 접근할 수 있습니다. `configure(_:)` 메서드 안에서 이 프로퍼티와 스위치를 사용하면 환경에 따라 다르게 설정할 수 있습니다.

```swift
switch app.environment {
case .production:
    app.databases.use(....)
default:
    app.databases.use(...)
}
```

## 환경설정 변경하기

기본으로 앱은 `development` 모드로 실행됩니다. 앱을 부팅할 때, `--env` (`-e`) 플래그를 전달해서 환경설정을 변경할 수 있습니다.

```swift
swift run App serve --env production
```

Vapor는 다음과 같은 환경이 있습니다.

|name|short|description|
|-|-|-|
|production|prod|사용자들에게 제공하기 위한 환경입니다|
|development|dev|로컬 개발을 위한 환경입니다.|
|testing|test|유닛 테스트를 위한 환경입니다.|

!!! info
    특별한 설정이 없다면 `production` 환경은 기본으로 `notice` 레벨로 로그를 기록합니다. 다른 환경들은 기본으로 `info` 레벨입니다. 

`--env` (`-e`) 플래그에 전체 또는 축약 이름을 전달해서 설정할 수 있습니다.

```swift
swift run App serve -e prod
```

## 프로세스 변수(Process Variables)

`Environment`는 프로세스의 환경 변수들에 접근할 수 있도록 간단한 문자열 기반의 API를 제공합니다.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

`get` 이외에도, `Environment`는 `process`를 통한 동적 멤버 조회 API도 제공합니다.

```swift
let foo = Environment.process.FOO
print(foo) // String?
```

터미널에서 앱을 실행하는 경우에는 `export`를 사용해서 환경 변수를 설정할 수 있습니다.

```sh
export FOO=BAR
swift run App serve
```

Xcode에서 앱을 실행하는 경우에는 `App` Scheme을 수정해서 환경 변수를 설정할 수 있습니다

## .env (dotenv) 파일

Dotenv 파일은 환경 변수를 자동으로 저장하기 위해서 Key-Value 형태의 리스트를 사용합니다. 이 파일은 수동으로 환경 변수를 설정할 필요가 없어서 쉽게 사용할 수 있습니다.

Vapor는 현재 작업 디렉토리에서 dotenv 파일을 검색합니다. 만약 Xcode를 사용한다면 `App` Scheme에서 작업 디렉토리를 지정해 줄 필요가 있습니다.

프로젝트 루트 폴더에 위치한 env 파일에 다음과 같은 내용이 있다고 가정하겠습니다.

```sh
FOO=BAR
```

어플리케이션이 부팅될 때, 다른 프로세스 환경 변수처럼 파일의 컨텐츠에 접근할 수 있습니다.

```swift
let foo = Environment.get("FOO")
print(foo) // String?
```

!!! info
    이미 프로세스 환경설정에 존재하는 변수들은 `.env` 파일에 명시되었더라도 재설정되지 않습니다.

Vapor는 `.env` 파일에 외에도 현재 환경을 위한 dotenv 파일을 로드하려고 합니다. 예를 들어 `development` 환경에서는 Vapor는 `.env.development` 파일을 로드할 것입니다. 특정 환경의 `.env` 파일 안의 값들은 일반 `.env` 파일보다 우선시 됩니다.

기본 값으로 구성된 템플릿으로서 `.env` 파일을 프로젝트에 포함하는 것은 일반적인 방식입니다. 특정 환경 파일은 `.gitignore`에서 다음 패턴을 사용해서 업로드되지 않도록 합니다.

```gitignore
.env.*
```

새로운 컴퓨터에 프로젝트를 클론(clone) 할 때, `.env` 템플릿 파일은 복사되고 올바른 값들을 입력할 수 있습니다.

```sh
cp .env .env.development
vim .env.development
```

!!! warning
    패스워드 같은 민감한 정보의 dotenv 파일들은 버전 관리에 절대로 커밋(commit) 되지 않도록 하세요.

만약 dotfile를 로드하는데 어려움이 있다면, 더 많은 정보를 위해서 `--log debug` 플래그를 사용해서 디버그 로깅을 시도해 보세요.

## 커스텀 환경설정

`Environment`을 확장해서 커스텀 환경설정 이름을 정의할 수 있습니다.

```swift
extension Environment {
    static var staging: Environment {
        .custom(name: "staging")
    }
}
```

어플리케이션의 환경설정은 보통 `entrypoint.swift`에서 `Environment.detect()`를 사용해서 설정합니다.

```swift
@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = Application(env)
        defer { app.shutdown() }
        
        try await configure(app)
        try await app.runFromAsyncMainEntrypoint()
    }
}
```

`detect` 메서드는 프로세스의 명령 줄 인자와 `--env` 플래그를 자동으로 사용합니다. 커스텀 `Environment` 구조체를 초기화하는 작업으로 이를 재설정할 수 있습니다.

```swift
let env = Environment(name: "testing", arguments: ["vapor"])
```

arguments 배열에는 최소한 하나의 실행 가능한 이름을 나타내는 인자를 포함해야 합니다. 명령 줄에 인자를 제공하는 것 같은 시뮬레이션을 하기 위해서, 추가적인 인자들을 제공할 수 있습니다. 특히 테스트를 위해서 사용할 때 유용합니다.
