# Podsumowanie Leaf

Leaf to wszechstronny język szablonów ze składnią inspirowaną językiem programowania Swift. Możesz go używać do generowania dynamicznych stron HTML dla stron front-endowych lub do generowania rozbudowanych maili wysyłanych z poziomu API.

Ten przewodnik przedstawi Ci składnię Leaf oraz dostępne tagi.

## Składnia szablonu

Oto przykład podstawowego użycia tagu Leaf.

```leaf
There are #count(users) users.
```

Tagi Leaf składają się z czterech elementów:

- Token `#`: Sygnalizuje parserowi Leaf, aby zaczął szukać tagu.
- Nazwa `count`: identyfikuje tag.
- Lista parametrów `(users)`: Może przyjmować zero lub więcej argumentów.
- Ciało: Niektóre tagi mogą przyjmować opcjonalne ciało, podane za pomocą dwukropka i tagu zamykającego

Te cztery elementy mogą być wykorzystywane na wiele różnych sposobów, w zależności od implementacji danego tagu. Przyjrzyjmy się kilku przykładom użycia wbudowanych tagów Leaf:

```leaf
#(variable)
#extend("template"): I'm added to a base template! #endextend
#export("title"): Welcome to Vapor #endexport
#import("body")
#count(friends)
#for(friend in friends): <li>#(friend.name)</li> #endfor
```

Leaf obsługuje również wiele wyrażeń znanych ze Swifta.

- `+`
- `%`
- `>`
- `==`
- `||`
- itd.

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

## Kontekst

W przykładzie z [Pierwszych kroków](getting-started.md) użyliśmy słownika `[String: String]`, aby przekazać dane do Leaf. Możesz jednak przekazać cokolwiek, co jest zgodne z `Encodable`. W rzeczywistości preferowane jest użycie struktur zgodnych z `Encodable`, ponieważ `[String: Any]` nie jest wspierane. Oznacza to, że *nie możesz* przekazać tablicy i zamiast tego powinieneś opakować ją w strukturę:

```swift
struct WelcomeContext: Encodable {
    var title: String
    var numbers: [Int]
}
return req.view.render("home", WelcomeContext(title: "Hello!", numbers: [42, 9001]))
```

To udostępni `title` i `numbers` naszemu szablonowi Leaf, które będzie można później wykorzystać wewnątrz tagów. Na przykład:

```leaf
<h1>#(title)</h1>
#for(number in numbers):
    <p>#(number)</p>
#endfor
```

## Zastosowanie

Poniżej znajdziesz kilka typowych przykładów użycia Leaf.

### Warunki

Leaf potrafi ewaluować szereg warunków za pomocą tagu `#if`. Na przykład, jeśli podasz zmienną, sprawdzi ona, czy ta zmienna istnieje w kontekście:

```leaf
#if(title):
    The title is #(title)
#else:
    No title was provided.
#endif
```

Możesz również zapisywać porównania, na przykład:

```leaf
#if(title == "Welcome"):
    This is a friendly web page.
#else:
    No strangers allowed!
#endif
```

Jeśli chcesz użyć innego tagu jako części swojego warunku, powinieneś pominąć `#` dla wewnętrznego tagu. Na przykład:

```leaf
#if(count(users) > 0):
    You have users!
#else:
    There are no users yet :(
#endif
```

Możesz też używać instrukcji `#elseif`:

```leaf
#if(title == "Welcome"):
    Hello new user!
#elseif(title == "Welcome back!"):
    Hello old user
#else:
    Unexpected page!
#endif
```

### Pętle

Jeśli podasz tablicę elementów, Leaf może przejść przez nią w pętli i pozwolić Ci manipulować każdym elementem indywidualnie za pomocą tagu `#for`.

Na przykład, moglibyśmy zaktualizować nasz kod Swift, aby dostarczał listę planet:

```swift
struct SolarSystem: Codable {
    let planets = ["Venus", "Earth", "Mars"]
}

return req.view.render("solarSystem", SolarSystem())
```

Następnie moglibyśmy przejść po nich w pętli w Leaf w ten sposób:

```leaf
Planets:
<ul>
#for(planet in planets):
    <li>#(planet)</li>
#endfor
</ul>
```

To wyrenderowałoby widok wyglądający tak:

```
Planets:
- Venus
- Earth
- Mars
```

### Rozszerzanie szablonów

Tag `#extend` w Leaf pozwala skopiować zawartość jednego szablonu do innego. Używając go, powinieneś zawsze pomijać rozszerzenie pliku szablonu .leaf.

Rozszerzanie jest przydatne do kopiowania standardowego fragmentu treści, na przykład stopki strony, kodu reklamowego lub tabeli współdzielonej między wieloma stronami:

```leaf
#extend("footer")
```

Ten tag jest również przydatny do budowania jednego szablonu na bazie innego. Na przykład możesz mieć plik layout.leaf, który zawiera cały kod potrzebny do rozplanowania Twojej strony internetowej – strukturę HTML, CSS i JavaScript – z pewnymi lukami wskazującymi miejsca, w których zmienia się treść strony.

Stosując to podejście, tworzysz szablon podrzędny, który wypełnia swoją unikalną treść, a następnie rozszerza szablon nadrzędny, który umieszcza tę treść we właściwym miejscu. Aby to zrobić, możesz użyć tagów `#export` i `#import`, aby zapisać, a następnie później pobrać treść z kontekstu.

Na przykład, mógłbyś stworzyć szablon `child.leaf` w ten sposób:

```leaf
#extend("main"):
    #export("body"):
        <p>Welcome to Vapor!</p>
    #endexport
#endextend
```

Wywołujemy `#export`, aby zapisać fragment HTML i udostępnić go szablonowi, który obecnie rozszerzamy. Następnie renderujemy `main.leaf` i wykorzystujemy wyeksportowane dane, kiedy są potrzebne, wraz z innymi zmiennymi kontekstu przekazanymi ze Swifta. Na przykład `main.leaf` mógłby wyglądać tak:

```leaf
<html>
    <head>
        <title>#(title)</title>
    </head>
    <body>#import("body")</body>
</html>
```

Tutaj używamy `#import`, aby pobrać treść przekazaną do tagu `#extend`. Gdy ze Swifta przekazane zostanie `["title": "Hi there!"]`, `child.leaf` wyrenderuje się następująco:

```html
<html>
    <head>
        <title>Hi there!</title>
    </head>
    <body><p>Welcome to Vapor!</p></body>
</html>
```

### Inne tagi

#### `#count`

Tag `#count` zwraca liczbę elementów w tablicy. Na przykład:

```leaf
Your search matched #count(matches) pages.
```

#### `#lowercased`

Tag `#lowercased` zamienia wszystkie litery w ciągu znaków na małe litery.

```leaf
#lowercased(name)
```

#### `#uppercased`

Tag `#uppercased` zamienia wszystkie litery w ciągu znaków na wielkie litery.

```leaf
#uppercased(name)
```

#### `#capitalized`

Tag `#capitalized` zamienia pierwszą literę każdego słowa w ciągu znaków na wielką, a pozostałe na małe. Zobacz [`String.capitalized`](https://developer.apple.com/documentation/foundation/nsstring/1416784-capitalized), aby uzyskać więcej informacji.

```leaf
#capitalized(name)
```

#### `#contains`

Tag `#contains` przyjmuje tablicę i wartość jako swoje dwa parametry i zwraca `true`, jeśli tablica w parametrze pierwszym zawiera wartość z parametru drugiego.

```leaf
#if(contains(planets, "Earth")):
    Earth is here!
#else:
    Earth is not in this array.
#endif
```

#### `#date`

Tag `#date` formatuje daty do postaci czytelnego ciągu znaków. Domyślnie używa formatowania ISO8601.

```swift
render(..., ["now": Date()])
```

```leaf
The time is #date(now)
```

Możesz przekazać niestandardowy ciąg formatujący datę jako drugi argument. Zobacz [`DateFormatter`](https://developer.apple.com/documentation/foundation/dateformatter) w Swift, aby uzyskać więcej informacji.

```leaf
The date is #date(now, "yyyy-MM-dd")
```

Możesz również przekazać identyfikator strefy czasowej dla formatera dat jako trzeci argument. Zobacz [`DateFormatter.timeZone`](https://developer.apple.com/documentation/foundation/dateformatter/1411406-timezone) i [`TimeZone`](https://developer.apple.com/documentation/foundation/timezone) w Swift, aby uzyskać więcej informacji.

```leaf
The date is #date(now, "yyyy-MM-dd", "America/New_York")
```

#### `#unsafeHTML`

Tag `#unsafeHTML` zachowuje się jak tag zmiennej - np. `#(variable)`. Jednak nie escape'uje żadnego kodu HTML, który może zawierać `variable`:

```leaf
The time is #unsafeHTML(styledTitle)
```

!!! note
    Powinieneś zachować ostrożność, używając tego tagu, aby upewnić się, że zmienna, którą podajesz, nie naraża Twoich użytkowników na atak XSS.

#### `#comment`

Tag `#comment` pozwala dodawać w szablonach adnotacje, które nie pojawią się w wyrenderowanym wyniku. Tag przyjmuje parametr będący ciągiem znaków, który jest całkowicie ignorowany podczas renderowania.

```leaf
#comment("This is a single-line comment")
<h1>#(title)</h1>
```

W przypadku dłuższych komentarzy możesz użyć składni wieloliniowego ciągu znaków:

```leaf
#comment("""
This template renders the home page.
It expects a "title" and "body" variable.
""")
<h1>#(title)</h1>
```

#### `#isEmpty`

Tag `#isEmpty` zwraca `true`, jeśli właściwość typu string przekazana do szablonu jest pusta. Zwykle jest używany wewnątrz warunku `#if`:

```leaf
#if(isEmpty(title)):
    No title was provided.
#else:
    The title is #(title)
#endif
```

#### `#dumpContext`

Tag `#dumpContext` renderuje cały kontekst do postaci czytelnego dla człowieka ciągu znaków. Użyj tego tagu, aby zdebugować,
co jest przekazywane jako kontekst do bieżącego renderowania.

```leaf
Hello, world!
#dumpContext
```
