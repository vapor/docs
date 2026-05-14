# 로깅(Logging) 

Vapor의 로깅 API은 [SwiftLog](https://github.com/apple/swift-log)을 기반으로 구성되었습니다. 따라서, Vapor는 모든 SwiftLog의 [backend implementations](https://github.com/apple/swift-log#backends)와 호환됩니다.

## 로거(Logger)

`Logger`의 인스턴스는 로그 메시지를 출력하는 데 사용됩니다. Vapor는 logger에 접근할 수 있는 몇 가지 방법을 제공합니다.

### 요청(Request)

각각 들어오는 `Request`은 고유의 로거를 가지고 있습니다. 해당 요청과 관련된 모든 로그를 위해서 로거를 사용할 수 있습니다.

```swift
app.get("hello") { req -> String in
    req.logger.info("Hello, logs!")
    return "Hello, world!"
}
```

요청 로거는 들어오는 요청을 식별하기 위한 유니크한 UUID를 가지고 있습니다. 로그를 쉽게 추적할 수 있습니다.

```
[ INFO ] Hello, logs! [request-id: C637065A-8CB0-4502-91DC-9B8615C5D315] (App/routes.swift:10)
```

!!! info
	로거 메타데이터는 디버그 레벨 또는 그 이하에서만 출력됩니다.

### Application

앱이 부팅되고 설정되는 동안에는 `Application`의 로거를 사용해서 로그 메시지를 출력할 수 있습니다.

```swift
app.logger.info("Setting up migrations...")
app.migrations.use(...)
```

### 커스텀 로거(Custom Logger)

`Application`이나 `Request`에 접근할 수 없는 상황에서는 새로운 `Logger`를 생성할 수 있습니다.

```swift
let logger = Logger(label: "dev.logger.my")
logger.info(...)
```

커스텀 로거도 설정된 데로 로그를 출력하지만, 요청 UUID 같은 중요한 메타데이터는 포함되지 않습니다. 가능한 request나 application의 고유 로거를 사용하세요.

## 레벨(Level)

SwiftLog는 여러 단계의 로깅 레벨을 지원합니다.

|name|description|
|-|-|
|trace|프로그램의 실행을 추적하기 위한 정보를 포함하는 메시지에 적합합니다.|
|debug|프로그램을 디버깅하기 위한 정보를 포함하는 메시지에 적합합니다.|
|info|정보를 제공하는 메시지에 적합합니다.|
|notice|에러가 발생한 상태는 아니지만, 특별한 작업이 필요할 수 있는 상태에 적합합니다.|
|warning|에러가 발생한 상태는 아니지만,  notice보다 심각한 상태에 적합합니다.|
|error|에러가 발생한 상태에 적합합니다.|
|critical|즉각적인 주의 조치가 필요한 치명적인 에러 상황에 적합합니다.|

`critical` 메시지가 기록될 때, 로깅 백엔드 시스템은 디버깅을 위해서 시스템 상태를 기록하는 무거운 작업(Stack Traces를 기록하는 것 같은)을 자유롭게 수행할 수 있습니다.

Vapor는 기본적으로 `info` 레벨의 로깅을 사용합니다. `production` 환경에서는 향상된 성능을 위해 `notice` 레벨이 사용됩니다. 

### 로그 레벨 변경

환경 모드에 상관없이, 생성되는 로그의 양을 늘리거나 줄이기 위해서 로깅 레벨을 재설정할 수 있습니다.

첫 번째 방법은 어플리케이션을 부팅할 때, `--log` 옵셔널 플래그를 전달하는 것입니다.

```sh
swift run App serve --log debug
```

두 번째 방법은 환경 변수로 `LOG_LEVEL`을 설정하는 것입니다.

```sh
export LOG_LEVEL=debug
swift run App serve
```

두 가지 방법 모두 Xcode에서 `App` scheme을 수정해서 설정할 수 있습니다.

## 설정(Configuration)

SwiftLog는 프로세스당 한번 `LoggingSystem`을 초기화(bootstrapping) 해서 설정됩니다. Vapor 프로젝트는 일반적으로 `entrypoint.swift`에서 이 작업을 수행합니다.

```swift
var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
```

`bootstrap(from:)` 메서드를 사용하면 명령행(command-line) 인자와 환경 변수를 기반으로 기본 로그 핸들러를 설정할 수 있습니다. 기본 로그 핸들러는  터미널에서 ANSI 색상이 적용된 로그를 제공합니다.

### 커스텀 핸들러(Custom Handler)

Vapor의 기본 로그 핸들러를 사용자의 핸들러로 재설정 할 수 있습니다.

```swift
import Logging

LoggingSystem.bootstrap { label in
    StreamLogHandler.standardOutput(label: label)
}
```

SwiftLog가 지원하는 모든 로그 백엔드는 Vapor에서 사용할 수 있습니다. 그러나, 로그 레벨을 명령행 인자와 환경 변수로 설정하는 것은 오직 Vapor의 기본 로그 핸들러에서만 적용됩니다.
