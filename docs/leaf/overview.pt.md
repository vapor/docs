# Visão Geral do Leaf

Leaf é uma linguagem de templates poderosa com sintaxe inspirada em Swift. Você pode usá-la para gerar páginas HTML dinâmicas para um site front-end ou gerar e-mails ricos para enviar a partir de uma API.

Este guia fornecerá uma visão geral da sintaxe do Leaf e das tags disponíveis.

## Sintaxe de Template

Aqui está um exemplo de uso básico de uma tag Leaf.

```leaf
There are #count(users) users.
```

As tags Leaf são compostas por quatro elementos:

- Token `#`: Sinaliza ao parser do Leaf para começar a procurar uma tag.
- Nome `count`: identifica a tag.
- Lista de Parâmetros `(users)`: Pode aceitar zero ou mais argumentos.
- Corpo: Um corpo opcional pode ser fornecido para algumas tags usando dois-pontos e uma tag de fechamento.

Pode haver muitos usos diferentes desses quatro elementos dependendo da implementação da tag. Vamos ver alguns exemplos de como as tags integradas do Leaf podem ser usadas:

```leaf
#(variable)
#extend("template"): I'm added to a base template! #endextend
#export("title"): Welcome to Vapor #endexport
#import("body")
#count(friends)
#for(friend in friends): <li>#(friend.name)</li> #endfor
```

O Leaf também suporta muitas expressões familiares do Swift.

- `+`
- `%`
- `>`
- `==`
- `||`
- etc.

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

## Contexto

No exemplo de [Primeiros Passos](getting-started.md), usamos um dicionário `[String: String]` para passar dados ao Leaf. No entanto, você pode passar qualquer coisa que conforme com `Encodable`. Na verdade, é preferível usar structs `Encodable`, já que `[String: Any]` não é suportado. Isso significa que você *não pode* passar um array diretamente, e deve envolvê-lo em uma struct:

```swift
struct WelcomeContext: Encodable {
    var title: String
    var numbers: [Int]
}
return req.view.render("home", WelcomeContext(title: "Hello!", numbers: [42, 9001]))
```

Isso expõe `title` e `numbers` ao nosso template Leaf, que podem então ser usados dentro de tags. Por exemplo:

```leaf
<h1>#(title)</h1>
#for(number in numbers):
    <p>#(number)</p>
#endfor
```

## Uso

Aqui estão alguns exemplos comuns de uso do Leaf.

### Condições

O Leaf é capaz de avaliar uma série de condições usando sua tag `#if`. Por exemplo, se você fornecer uma variável, ele verificará se essa variável existe no contexto:

```leaf
#if(title):
    The title is #(title)
#else:
    No title was provided.
#endif
```

Você também pode escrever comparações, por exemplo:

```leaf
#if(title == "Welcome"):
    This is a friendly web page.
#else:
    No strangers allowed!
#endif
```

Se você quiser usar outra tag como parte da sua condição, deve omitir o `#` da tag interna. Por exemplo:

```leaf
#if(count(users) > 0):
    You have users!
#else:
    There are no users yet :(
#endif
```

Você também pode usar declarações `#elseif`:

```leaf
#if(title == "Welcome"):
    Hello new user!
#elseif(title == "Welcome back!"):
    Hello old user
#else:
    Unexpected page!
#endif
```

### Loops

Se você fornecer um array de itens, o Leaf pode iterar sobre eles e permitir que você manipule cada item individualmente usando sua tag `#for`.

Por exemplo, poderíamos atualizar nosso código Swift para fornecer uma lista de planetas:

```swift
struct SolarSystem: Codable {
    let planets = ["Venus", "Earth", "Mars"]
}

return req.view.render("solarSystem", SolarSystem())
```

Poderíamos então iterar sobre eles no Leaf assim:

```leaf
Planets:
<ul>
#for(planet in planets):
    <li>#(planet)</li>
#endfor
</ul>
```

Isso renderizaria uma view assim:

```
Planets:
- Venus
- Earth
- Mars
```

### Estendendo Templates

A tag `#extend` do Leaf permite que você copie o conteúdo de um template para outro. Ao usar isso, você deve sempre omitir a extensão .leaf do arquivo de template.

Estender é útil para copiar um conteúdo padrão, por exemplo um rodapé de página, código de anúncio ou tabela compartilhada entre múltiplas páginas:

```leaf
#extend("footer")
```

Esta tag também é útil para construir um template em cima de outro. Por exemplo, você pode ter um arquivo layout.leaf que inclui todo o código necessário para o layout do seu site — estrutura HTML, CSS e JavaScript — com algumas lacunas onde o conteúdo da página varia.

Usando esta abordagem, você construiria um template filho que preenche seu conteúdo único e então estende o template pai que posiciona o conteúdo adequadamente. Para fazer isso, você pode usar as tags `#export` e `#import` para armazenar e posteriormente recuperar conteúdo do contexto.

Por exemplo, você pode criar um template `child.leaf` assim:

```leaf
#extend("main"):
    #export("body"):
        <p>Welcome to Vapor!</p>
    #endexport
#endextend
```

Chamamos `#export` para armazenar algum HTML e torná-lo disponível para o template que estamos estendendo. Então renderizamos `main.leaf` e usamos os dados exportados quando necessário, junto com quaisquer outras variáveis de contexto passadas pelo Swift. Por exemplo, `main.leaf` pode ser assim:

```leaf
<html>
    <head>
        <title>#(title)</title>
    </head>
    <body>#import("body")</body>
</html>
```

Aqui estamos usando `#import` para buscar o conteúdo passado para a tag `#extend`. Quando passamos `["title": "Hi there!"]` pelo Swift, `child.leaf` renderizará da seguinte forma:

```html
<html>
    <head>
        <title>Hi there!</title>
    </head>
    <body><p>Welcome to Vapor!</p></body>
</html>
```

### Outras Tags

#### `#count`

A tag `#count` retorna o número de itens em um array. Por exemplo:

```leaf
Your search matched #count(matches) pages.
```

#### `#lowercased`

A tag `#lowercased` converte todas as letras de uma string para minúsculas.

```leaf
#lowercased(name)
```

#### `#uppercased`

A tag `#uppercased` converte todas as letras de uma string para maiúsculas.

```leaf
#uppercased(name)
```

#### `#capitalized`

A tag `#capitalized` converte a primeira letra de cada palavra de uma string para maiúscula e as demais para minúsculas. Veja [`String.capitalized`](https://developer.apple.com/documentation/foundation/nsstring/1416784-capitalized) para mais informações.

```leaf
#capitalized(name)
```

#### `#contains`

A tag `#contains` aceita um array e um valor como seus dois parâmetros, e retorna verdadeiro se o array no primeiro parâmetro contém o valor do segundo parâmetro.

```leaf
#if(contains(planets, "Earth")):
    Earth is here!
#else:
    Earth is not in this array.
#endif
```

#### `#date`

A tag `#date` formata datas em uma string legível. Por padrão, usa a formatação ISO8601.

```swift
render(..., ["now": Date()])
```

```leaf
The time is #date(now)
```

Você pode passar uma string de formato de data personalizado como segundo argumento. Veja o [`DateFormatter`](https://developer.apple.com/documentation/foundation/dateformatter) do Swift para mais informações.

```leaf
The date is #date(now, "yyyy-MM-dd")
```

Você também pode passar um ID de fuso horário para o formatador de data como terceiro argumento. Veja [`DateFormatter.timeZone`](https://developer.apple.com/documentation/foundation/dateformatter/1411406-timezone) e [`TimeZone`](https://developer.apple.com/documentation/foundation/timezone) do Swift para mais informações.

```leaf
The date is #date(now, "yyyy-MM-dd", "America/New_York")
```

#### `#unsafeHTML`

A tag `#unsafeHTML` age como uma tag de variável — ex: `#(variable)`. No entanto, ela não escapa nenhum HTML que `variable` possa conter:

```leaf
The time is #unsafeHTML(styledTitle)
```

!!! note "Nota"
    Você deve ter cuidado ao usar esta tag para garantir que a variável fornecida não exponha seus usuários a um ataque XSS.

#### `#dumpContext`

A tag `#dumpContext` renderiza todo o contexto em uma string legível. Use esta tag para depurar o que está sendo fornecido como contexto para a renderização atual.

```leaf
Hello, world!
#dumpContext
```
