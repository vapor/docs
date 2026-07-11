# 사용자 정의 태그

[`LeafTag`](https://api.vapor.codes/leafkit/documentation/leafkit/leaftag) 프로토콜을 사용해서 사용자 정의 Leaf 태그를 만들 수 있습니다.

이를 보여주기 위해, 현재 타임스탬프를 출력하는 사용자 정의 태그 `#now`를 만들어 보겠습니다. 이 태그는 날짜 포맷을 지정하기 위한 단일 선택적 파라미터도 지원합니다.

!!! tip
    사용자 정의 태그가 HTML을 렌더링한다면, HTML이 이스케이프되지 않도록 사용자 정의 태그를 `UnsafeUnescapedLeafTag`에 준수시켜야 합니다. 사용자 입력은 반드시 확인하거나 살균 처리(sanitize)하는 것을 잊지 마세요.

## `LeafTag`

먼저 `NowTag`라는 클래스를 만들고 이를 `LeafTag`에 준수시킵니다.

```swift
struct NowTag: LeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        ...
    }
}
```

이제 `render(_:)` 메서드를 구현해 보겠습니다. 이 메서드에 전달되는 `LeafContext` 컨텍스트에는 우리에게 필요한 모든 것이 담겨 있습니다.

```swift
enum NowTagError: Error {
    case invalidFormatParameter
    case tooManyParameters
}

struct NowTag: LeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        let formatter = DateFormatter()
        switch ctx.parameters.count {
        case 0: formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        case 1:
            guard let string = ctx.parameters[0].string else {
                throw NowTagError.invalidFormatParameter
            }

            formatter.dateFormat = string
        default:
            throw NowTagError.tooManyParameters
        }
    
        let dateAsString = formatter.string(from: Date())
        return LeafData.string(dateAsString)
    }
}
```

## 태그 설정하기

이제 `NowTag`를 구현했으니, Leaf에게 이 태그에 대해 알려주기만 하면 됩니다. 별도의 패키지에서 온 태그라 하더라도, 어떤 태그든 이렇게 추가할 수 있습니다. 일반적으로는 `configure.swift`에서 이 작업을 수행합니다.

```swift
app.leaf.tags["now"] = NowTag()
```

이제 끝입니다! Leaf에서 우리의 사용자 정의 태그를 사용할 수 있습니다.

```leaf
The time is #now()
```

## 컨텍스트 프로퍼티

`LeafContext`는 두 가지 중요한 프로퍼티를 포함합니다. 우리에게 필요한 모든 것을 담고 있는 `parameters`와 `data`입니다.

- `parameters`: 태그의 파라미터를 포함하는 배열입니다.
- `data`: 컨텍스트로서 `render(_:_:)`에 전달된 뷰의 데이터를 포함하는 딕셔너리입니다.

### Hello 태그 예제

이를 사용하는 방법을 알아보기 위해, 두 프로퍼티를 모두 사용하는 간단한 hello 태그를 구현해 보겠습니다.

#### 파라미터 사용하기

이름을 포함하는 첫 번째 파라미터에 접근할 수 있습니다.

```swift
enum HelloTagError: Error {
    case missingNameParameter
}

struct HelloTag: UnsafeUnescapedLeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        guard let name = ctx.parameters[0].string else {
            throw HelloTagError.missingNameParameter
        }

        return LeafData.string("<p>Hello \(name)</p>")
    }
}
```

```leaf
#hello("John")
```

#### 데이터 사용하기

data 프로퍼티 안의 "name" 키를 사용해서 이름 값에 접근할 수 있습니다.

```swift
enum HelloTagError: Error {
    case nameNotFound
}

struct HelloTag: UnsafeUnescapedLeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        guard let name = ctx.data["name"]?.string else {
            throw HelloTagError.nameNotFound
        }

        return LeafData.string("<p>Hello \(name)</p>")
    }
}
```

```leaf
#hello()
```

_컨트롤러_:

```swift
return try await req.view.render("home", ["name": "John"])
```
