# Panoramica di Leaf

Leaf è un potente linguaggio di templating con la sintassi ispirata a Swift. Puoi usarlo per generare pagine HTML dinamiche per un sito front-end o per generare email abbellite da inviare con una API.

Questa guida ti darà una panoramica della sintassi di Leaf e dei tag disponibili.

## Sintassi del template

Questo è un esempio dell'utilizzo di un tag Leaf base.

```leaf
There are #count(users) users.
```

I tag Leaf sono composti da quattro elementi:

- Token `#`: Questo indica al parser di Leaf di iniziare a cercare un tag.
- Nome `count`: identifica il tag.
- Lista dei Parametri `(users)`: Può accettare zero o più argomenti.
- Corpo: A certi tag può essere fornito un corpo opzionale usando due punti e un tag di chiusura

Possono esserci molti utilizzi diversi di questi quattro elementi in base all'implementazione del tag. Diamo un'occhiata a qualche esempio di come i tag predefiniti di Leaf possono essere usati:

```leaf
#(variable)
#extend("template"): I'm added to a base template! #endextend
#export("title"): Welcome to Vapor #endexport
#import("body")
#count(friends)
#for(friend in friends): <li>#(friend.name)</li> #endfor
```

Leaf supporta anche molte espressioni che conosci in Swift.

- `+`
- `%`
- `>`
- `==`
- `||`
- ecc.

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

## Contesto

Nell'esempio in [Inizio](getting-started.md), abbiamo usato un dizionario `[String: String]` per passare dati a Leaf. In ogni caso, puoi passargli qualsiasi cosa conforme a `Encodable`. In realtà è preferibile usare strutture `Encodable` in quanto `[String: Any]` non è supportato. Questo significa che *non puoi* passargli un array, e dovresti invece impacchettarlo in una struct:

```swift
struct WelcomeContext: Encodable {
    var title: String
    var numbers: [Int]
}
return req.view.render("home", WelcomeContext(title: "Hello!", numbers: [42, 9001]))
```

Questo mostrerà `title` e `numbers` al nostro template Leaf, che potrà poi essere usato dentro i tag. Per esempio:

```leaf
<h1>#(title)</h1>
#for(number in numbers):
    <p>#(number)</p>
#endfor
```

## Utilizzo

Ecco alcuni esempi di utilizzo comune di Leaf.

### Condizioni

Leaf è capace di valutare una serie di condizioni usando il suo tag `#if`. Per esempio, se gli fornisci una variabile controllerà che la variabile esista nel suo contesto:

```leaf
#if(title):
    The title is #(title)
#else:
    No title was provided.
#endif
```

Puoi anche utilizzare confronti, per esempio:

```leaf
#if(title == "Welcome"):
    This is a friendly web page.
#else:
    No strangers allowed!
#endif
```

Se vuoi usare un altro tag come parte della tua condizione, dovresti omettere il `#` per il tag interno. Per esempio:

```leaf
#if(count(users) > 0):
    You have users!
#else:
    There are no users yet :(
#endif
```

Puoi usare anche dichiarazioni `#elseif`:

```leaf
#if(title == "Welcome"):
    Hello new user!
#elseif(title == "Welcome back!"):
    Hello old user
#else:
    Unexpected page!
#endif
```

### Cicli

Se fornisci un array di oggetti, Leaf può iterare su di essi e permetterti di manipolare ciascun oggetto individualmente usando il suo tag `#for`.

Per esempio, possiamo aggiornare il nostro codice Swift per fornire una lista di pianeti:

```swift
struct SolarSystem: Codable {
    let planets = ["Venus", "Earth", "Mars"]
}

return req.view.render("solarSystem", SolarSystem())
```

In Leaf, possiamo iterare su di essi così:

```leaf
Planets:
<ul>
#for(planet in planets):
    <li>#(planet)</li>
#endfor
</ul>
```

Questo creerebbe una view con questo aspetto:

```
Planets:
- Venus
- Earth
- Mars
```

### Estendere i template

Il tag di Leaf `#extend` ti permette di copiare il contenuto di un template in un altro. Quando lo usi, dovresti sempre omettere l'estensione del file di template .leaf.

Estendere è utile per copiare un pezzo di contenuto standard, per esempio un piè di pagina, codice per la pubblicità o una tabella condivisi su più pagine:

```leaf
#extend("footer")
```

Questo tag è utile anche per costruire un template sulla base di un altro. Per esempio, potresti avere un file layout.leaf che include tutto il codice richiesto per disporre il tuo sito – struttura HTML, CSS e JavaScript – con dei vuoti nei posti in cui il contenuto della pagina cambia.

Usando questo approccio, potresti costruire un template figlio che compila il suo contenuto particolare, poi estende il template padre che posiziona il contenuto in modo appropriato. Per fare questo, puoi usare i tag `#export` e `#import` per salvare e dopo recuperare il contenuto dal contesto.

Per esempio, potresti creare un template `child.leaf` così:

```leaf
#extend("master"):
    #export("body"):
        <p>Welcome to Vapor!</p>
    #endexport
#endextend
```

Chiamiamo `#export` per salvare dell'HTML e renderlo disponibile al template che stiamo estendendo al momento. Poi renderizziamo `master.leaf` e usiamo i dati esportati quando richiesto insieme a qualsiasi altra variabile di contesto passata da Swift. Per esempio, `master.leaf` potrebbe essere così:

```leaf
<html>
    <head>
        <title>#(title)</title>
    </head>
    <body>#import("body")</body>
</html>
```

Qui stiamo usando `#import` per recuperare il contenuto passato al tag `#extend`. Quando viene passato `["title": "Hi there!"]` da Swift, `child.leaf` verrà renderizzato così:

```html
<html>
    <head>
        <title>Hi there!</title>
    </head>
    <body><p>Welcome to Vapor!</p></body>
</html>
```

### Altri tag

#### `#count`

Il tag `#count` ritorna il numero di oggetti in un array. Per esempio:

```leaf
Your search matched #count(matches) pages.
```

#### `#lowercased`

Il tag `#lowercased` mette in minuscolo tutte le lettere in una stringa.

```leaf
#lowercased(name)
```

#### `#uppercased`

Il tag `#uppercased` mette in maiuscolo tutte le lettere in una stringa.

```leaf
#uppercased(name)
```

#### `#capitalized`

Il tag `#capitalized` mette in maiuscolo la prima lettera in ogni parola di una stringa e mette in minuscolo le altre. Guarda [`String.capitalized`](https://developer.apple.com/documentation/foundation/nsstring/1416784-capitalized) per più informazioni.

```leaf
#capitalized(name)
```

#### `#contains`

Il tag `#contains` accetta un array e un valore come parametri, e ritorna true se l'array nel primo parametro contiene il valore nel secondo parametro.

```leaf
#if(contains(planets, "Earth")):
    Earth is here!
#else:
    Earth is not in this array.
#endif
```

#### `#date`

Il tag `#date` formatta le date in una stringa leggibile. Di default usa il formato ISO8601.

```swift
render(..., ["now": Date()])
```

```leaf
The time is #date(now)
```

Puoi passare una stringa in un formato di data personalizzato come secondo argomento. Guarda il [`DateFormatter`](https://developer.apple.com/documentation/foundation/dateformatter) di Swift per più informazioni.

```leaf
The date is #date(now, "yyyy-MM-dd")
```

Puoi anche passare l'ID di un fuso orario come terzo argomento. Guarda [`DateFormatter.timeZone`](https://developer.apple.com/documentation/foundation/dateformatter/1411406-timezone) e [`TimeZone`](https://developer.apple.com/documentation/foundation/timezone) di Swift per più informazioni.

```leaf
The date is #date(now, "yyyy-MM-dd", "America/New_York")
```

#### `#unsafeHTML`

Il tag `#unsafeHTML` agisce come un tag di variabile - p.es. `#(variable)`. Però non evade nessun HTML che `variable` potrebbe contenere:

```leaf
The time is #unsafeHTML(styledTitle)
```

!!! note
    Dovresti fare attenzione quando usi questo tag per assicurarti che la variabile che gli fornisci non esponga i tuoi utenti a un attacco XSS.

#### `#dumpContext`

Il tag `#dumpContext` renderizza l'intero contesto in una stringa leggibile. Usa questo tag per debuggare cosa viene fornito come contesto al rendering corrente.

```leaf
Hello, world!
#dumpContext
```