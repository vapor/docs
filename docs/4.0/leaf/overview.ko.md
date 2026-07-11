# Leaf 개요

Leaf는 Swift에서 영감을 받은 문법을 가진 강력한 템플릿 언어입니다. 프론트엔드 웹사이트를 위한 동적 HTML 페이지를 생성하거나, API에서 보낼 풍부한 이메일을 생성하는 데 사용할 수 있습니다.

이 가이드에서는 Leaf의 문법과 사용 가능한 태그에 대한 개요를 제공합니다.

## 템플릿 문법

다음은 기본적인 Leaf 태그 사용 예시입니다.

```leaf
There are #count(users) users.
```

Leaf 태그는 네 가지 요소로 구성됩니다.

- 토큰 `#`: Leaf 파서가 태그를 찾기 시작하도록 신호를 보냅니다.
- 이름 `count`: 태그를 식별합니다.
- 파라미터 목록 `(users)`: 0개 이상의 인자를 받을 수 있습니다.
- 본문: 일부 태그에는 콜론과 닫는 태그를 사용해서 선택적인 본문을 제공할 수 있습니다.

태그의 구현 방식에 따라 이 네 가지 요소를 다양하게 사용할 수 있습니다. Leaf의 내장 태그가 어떻게 사용될 수 있는지 몇 가지 예시를 살펴보겠습니다.

```leaf
#(variable)
#extend("template"): I'm added to a base template! #endextend
#export("title"): Welcome to Vapor #endexport
#import("body")
#count(friends)
#for(friend in friends): <li>#(friend.name)</li> #endfor
```

Leaf는 여러분이 Swift에서 익숙한 많은 표현식도 지원합니다.

- `+`
- `%`
- `>`
- `==`
- `||`
- 기타

```leaf
#if(1 + 1 == 2):
    Hello!
#endif

#if(index % 2 == 0):
    This is even index.
#else:
    This is odd index.
#endif
```

## 컨텍스트

[시작하기](getting-started.md)의 예제에서는 Leaf에 데이터를 전달하기 위해 `[String: String]` 딕셔너리를 사용했습니다. 그러나 `Encodable`을 준수하는 어떤 것이든 전달할 수 있습니다. 사실 `[String: Any]`는 지원되지 않으므로, `Encodable` 구조체를 사용하는 것이 선호됩니다. 이는 배열을 직접 전달할 수 *없으며*, 대신 구조체로 감싸야 한다는 것을 의미합니다.

```swift
struct WelcomeContext: Encodable {
    var title: String
    var numbers: [Int]
}
return req.view.render("home", WelcomeContext(title: "Hello!", numbers: [42, 9001]))
```

이렇게 하면 `title`과 `numbers`가 Leaf 템플릿에 노출되고, 이후 태그 안에서 사용할 수 있습니다. 예를 들면 다음과 같습니다.

```leaf
<h1>#(title)</h1>
#for(number in numbers):
    <p>#(number)</p>
#endfor
```

## 사용법

다음은 Leaf의 일반적인 사용 예시입니다.

### 조건문

Leaf는 `#if` 태그를 사용해서 다양한 조건을 평가할 수 있습니다. 예를 들어, 변수를 제공하면 해당 변수가 컨텍스트에 존재하는지 확인합니다.

```leaf
#if(title):
    The title is #(title)
#else:
    No title was provided.
#endif
```

다음과 같이 비교문을 작성할 수도 있습니다.

```leaf
#if(title == "Welcome"):
    This is a friendly web page.
#else:
    No strangers allowed!
#endif
```

조건의 일부로 다른 태그를 사용하려면, 내부 태그의 `#`은 생략해야 합니다. 예를 들면 다음과 같습니다.

```leaf
#if(count(users) > 0):
    You have users!
#else:
    There are no users yet :(
#endif
```

`#elseif` 문도 사용할 수 있습니다.

```leaf
#if(title == "Welcome"):
    Hello new user!
#elseif(title == "Welcome back!"):
    Hello old user
#else:
    Unexpected page!
#endif
```

### 반복문

항목의 배열을 제공하면, Leaf는 `#for` 태그를 사용해서 이를 반복하고 각 항목을 개별적으로 다룰 수 있게 해줍니다.

예를 들어, 행성의 목록을 제공하도록 Swift 코드를 업데이트할 수 있습니다.

```swift
struct SolarSystem: Codable {
    let planets = ["Venus", "Earth", "Mars"]
}

return req.view.render("solarSystem", SolarSystem())
```

그런 다음 Leaf에서 다음과 같이 반복할 수 있습니다.

```leaf
Planets:
<ul>
#for(planet in planets):
    <li>#(planet)</li>
#endfor
</ul>
```

이는 다음과 같은 뷰를 렌더링합니다.

```
Planets:
- Venus
- Earth
- Mars
```

### 템플릿 확장하기

Leaf의 `#extend` 태그는 한 템플릿의 내용을 다른 템플릿에 복사할 수 있게 해줍니다. 이를 사용할 때는 항상 템플릿 파일의 .leaf 확장자를 생략해야 합니다.

확장하기는 페이지 푸터, 광고 코드, 또는 여러 페이지에서 공유되는 테이블처럼 표준화된 콘텐츠를 복사하는 데 유용합니다.

```leaf
#extend("footer")
```

이 태그는 하나의 템플릿을 다른 템플릿 위에 구축하는 데도 유용합니다. 예를 들어, HTML 구조, CSS, JavaScript 등 웹사이트를 레이아웃하는 데 필요한 모든 코드를 포함하면서, 페이지 콘텐츠가 달라지는 부분을 빈 공간으로 남겨두는 layout.leaf 파일이 있을 수 있습니다.

이 방식을 사용하면, 고유한 콘텐츠를 채우는 자식 템플릿을 만든 다음, 해당 콘텐츠를 적절한 위치에 배치하는 부모 템플릿을 확장하게 됩니다. 이를 위해 `#export`와 `#import` 태그를 사용해서 컨텍스트에서 콘텐츠를 저장하고 나중에 가져올 수 있습니다.

예를 들어, 다음과 같은 `child.leaf` 템플릿을 만들 수 있습니다.

```leaf
#extend("main"):
    #export("body"):
        <p>Welcome to Vapor!</p>
    #endexport
#endextend
```

`#export`를 호출해서 일부 HTML을 저장하고, 현재 확장하고 있는 템플릿에서 사용할 수 있도록 합니다. 그런 다음 `main.leaf`를 렌더링하고, Swift에서 전달된 다른 컨텍스트 변수와 함께 필요할 때 내보낸(export) 데이터를 사용합니다. 예를 들어, `main.leaf`는 다음과 같을 수 있습니다.

```leaf
<html>
    <head>
        <title>#(title)</title>
    </head>
    <body>#import("body")</body>
</html>
```

여기서는 `#import`를 사용해서 `#extend` 태그에 전달된 콘텐츠를 가져옵니다. Swift에서 `["title": "Hi there!"]`가 전달되면, `child.leaf`는 다음과 같이 렌더링됩니다.

```html
<html>
    <head>
        <title>Hi there!</title>
    </head>
    <body><p>Welcome to Vapor!</p></body>
</html>
```

### 그 밖의 태그

#### `#count`

`#count` 태그는 배열에 포함된 항목의 개수를 반환합니다. 예를 들면 다음과 같습니다.

```leaf
Your search matched #count(matches) pages.
```

#### `#lowercased`

`#lowercased` 태그는 문자열의 모든 글자를 소문자로 변환합니다.

```leaf
#lowercased(name)
```

#### `#uppercased`

`#uppercased` 태그는 문자열의 모든 글자를 대문자로 변환합니다.

```leaf
#uppercased(name)
```

#### `#capitalized`

`#capitalized` 태그는 문자열의 각 단어의 첫 글자를 대문자로, 나머지 글자를 소문자로 변환합니다. 자세한 내용은 [`String.capitalized`](https://developer.apple.com/documentation/foundation/nsstring/1416784-capitalized)를 참고하세요.

```leaf
#capitalized(name)
```

#### `#contains`

`#contains` 태그는 배열과 값을 두 개의 파라미터로 받아서, 첫 번째 파라미터의 배열이 두 번째 파라미터의 값을 포함하는지 여부를 true로 반환합니다.

```leaf
#if(contains(planets, "Earth")):
    Earth is here!
#else:
    Earth is not in this array.
#endif
```

#### `#date`

`#date` 태그는 날짜를 읽기 쉬운 문자열로 포맷합니다. 기본적으로 ISO8601 포맷을 사용합니다.

```swift
render(..., ["now": Date()])
```

```leaf
The time is #date(now)
```

두 번째 인자로 사용자 지정 날짜 포맷터 문자열을 전달할 수 있습니다. 자세한 내용은 Swift의 [`DateFormatter`](https://developer.apple.com/documentation/foundation/dateformatter)를 참고하세요.

```leaf
The date is #date(now, "yyyy-MM-dd")
```

세 번째 인자로 날짜 포맷터의 타임 존 ID를 전달할 수도 있습니다. 자세한 내용은 Swift의 [`DateFormatter.timeZone`](https://developer.apple.com/documentation/foundation/dateformatter/1411406-timezone)과 [`TimeZone`](https://developer.apple.com/documentation/foundation/timezone)을 참고하세요.

```leaf
The date is #date(now, "yyyy-MM-dd", "America/New_York")
```

#### `#unsafeHTML`

`#unsafeHTML` 태그는 변수 태그(예: `#(variable)`)처럼 동작합니다. 그러나 `variable`이 포함할 수 있는 HTML을 이스케이프하지 않습니다.

```leaf
The time is #unsafeHTML(styledTitle)
```

!!! note
    이 태그를 사용할 때는 제공하는 변수가 사용자를 XSS 공격에 노출시키지 않도록 주의해야 합니다.

#### `#comment`

`#comment` 태그를 사용하면 렌더링된 출력물에는 나타나지 않는 주석을 템플릿에 추가할 수 있습니다. 이 태그는 문자열 파라미터를 받으며, 이는 렌더링 시 완전히 무시됩니다.

```leaf
#comment("This is a single-line comment")
<h1>#(title)</h1>
```

더 긴 주석의 경우, 여러 줄 문자열 문법을 사용할 수 있습니다.

```leaf
#comment("""
This template renders the home page.
It expects a "title" and "body" variable.
""")
<h1>#(title)</h1>
```

#### `#isEmpty`

`#isEmpty` 태그는 템플릿에 전달된 문자열 프로퍼티가 비어 있으면 true를 반환합니다. 일반적으로 `#if` 조건문 안에서 사용됩니다.

```leaf
#if(isEmpty(title)):
    No title was provided.
#else:
    The title is #(title)
#endif
```

#### `#dumpContext`

`#dumpContext` 태그는 전체 컨텍스트를 사람이 읽을 수 있는 문자열로 렌더링합니다. 현재 렌더링에 컨텍스트로 무엇이 제공되고 있는지 디버깅할 때 이 태그를 사용하세요.

```leaf
Hello, world!
#dumpContext
```
