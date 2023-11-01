# Presentación

Leaf es un potente lenguaje de plantillas con una sintaxis inspirada en Swift. Puedes usarlo para generar páginas HTML dinámicas destinadas a un portal web o generar correos electrónicos enriquecidos para enviar desde una API.

Esta guía te proporcionará una visión general de la sintaxis de Leaf y las etiquetas disponibles.

## Sintaxis de la plantilla

Aquí tienes un ejemplo de cómo se usa una etiqueta básica de Leaf.

```leaf
There are #count(users) users.
```

Las etiquetas de Leaf constan de cuatro elementos:

- Token `#`: Esto indica al analizador de Leaf que comience a buscar una etiqueta.
- Nombre `count`: identifica a la etiqueta.
- Parámetro `(users)`: Puede aceptar cero o más argumentos.
- Cuerpo: Algunas etiquetas pueden tener un cuerpo opcional, que se suministra usando dos puntos y una etiqueta de cierre.

Dependiendo de la implementación de la etiqueta, puede haber muchos usos diferentes de estos cuatro elementos. Veamos algunos ejemplos de cómo se podrían usar las etiquetas incorporadas de Leaf:

```leaf
#(variable)
#extend("template"): I'm added to a base template! #endextend
#export("title"): Welcome to Vapor #endexport
#import("body")
#count(friends)
#for(friend in friends): <li>#(friend.name)</li> #endfor
```

Leaf también admite muchas expresiones con las que estás familiarizado en Swift.

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

En el ejemplo de [Comenzando](getting-started.md), usamos un diccionario `[String: String]` para pasar datos a Leaf. Sin embargo, puedes pasar cualquier cosa conformada con `Encodable`. Es preferible usar estructuras `Encodable` ya que `[String: Any]` no está soportado. Esto significa que *no puedes* pasar un array directamente, y en su lugar deberías envolverlo en una estructura:

```swift
struct WelcomeContext: Encodable {
    var title: String
    var numbers: [Int]
}
return req.view.render("home", WelcomeContext(title: "Hello!", numbers: [42, 9001]))
```

Esto expondrá `title` y `numbers` a nuestra plantilla de Leaf, que luego se pueden usar dentro de las etiquetas. Por ejemplo:

```leaf
<h1>#(title)</h1>
#for(number in numbers):
    <p>#(number)</p>
#endfor
```

## Uso

Aquí hay algunos ejemplos comunes del uso de Leaf.

### Condiciones

Leaf puede evaluar una serie de condiciones usando su etiqueta `#if`. Por ejemplo, si proporcionas una variable, comprobará si esa variable existe en su contexto:

```leaf
#if(title):
    The title is #(title)
#else:
    No title was provided.
#endif
```

También puedes escribir comparaciones, por ejemplo:

```leaf
#if(title == "Welcome"):
    This is a friendly web page.
#else:
    No strangers allowed!
#endif
```

Si deseas usar otra etiqueta como parte de tu condición, debes omitir el `#` para la etiqueta interna. Por ejemplo:

```leaf
#if(count(users) > 0):
    You have users!
#else:
    There are no users yet :(
#endif
```

También puedes usar declaraciones `#elseif`:

```leaf
#if(title == "Welcome"):
    Hello new user!
#elseif(title == "Welcome back!"):
    Hello old user
#else:
    Unexpected page!
#endif
```

### Bucles

Si proporcionas un array de elementos, Leaf puede recorrerlos y te permite manipular cada elemento individualmente usando su etiqueta `#for`.

Por ejemplo, podríamos actualizar nuestro código Swift para proporcionar una lista de planetas:

```swift
struct SolarSystem: Codable {
    let planets = ["Venus", "Earth", "Mars"]
}

return req.view.render("solarSystem", SolarSystem())
```

Luego podríamos recorrerlos en Leaf de la siguiente manera:

```leaf
Planets:
<ul>
#for(planet in planets):
    <li>#(planet)</li>
#endfor
</ul>
```

Esto renderizaría una vista que se vería así:

```
Planets:
- Venus
- Earth
- Mars
```

### Extendiendo plantillas

La etiqueta `#extend` de Leaf te permite copiar el contenido de una plantilla en otra. Al usar esto, siempre debes omitir la extensión .leaf del archivo de la plantilla.

Extender es útil para copiar un fragmento estándar de contenido, por ejemplo, un pie de página, un código publicitario o una tabla que se comparte en varias páginas:

```leaf
#extend("footer")
```

Esta etiqueta también es útil para construir una plantilla sobre otra. Por ejemplo, podrías tener un archivo layout.leaf que incluya todo el código necesario para estructurar tu sitio web - estructura HTML, CSS y JavaScript - con algunos espacios en su lugar que representan dónde varía el contenido de la página.

Usando este enfoque, construirías una plantilla hija que completa con su contenido único, y luego extiende la plantilla padre que coloca el contenido de manera adecuada. Para hacer esto, puedes usar las etiquetas `#export` e `#import` para almacenar y luego recuperar contenido del contexto.

Por ejemplo, podrías crear una plantilla `child.leaf` de la siguiente manera:

```leaf
#extend("master"):
    #export("body"):
        <p>Welcome to Vapor!</p>
    #endexport
#endextend
```

Llamamos `#export` para almacenar algo de HTML y hacerlo disponible para la plantilla que estamos extendiendo actualmente. Luego renderizamos `master.leaf` y usamos los datos exportados cuando sea necesario, junto con cualquier otra variable de contexto pasada desde Swift. Por ejemplo, `master.leaf` podría verse así:

```leaf
<html>
    <head>
        <title>#(title)</title>
    </head>
    <body>#import("body")</body>
</html>
```

Aquí estamos usando `#import` para obtener el contenido pasado a la etiqueta `#extend`. Cuando se pasa `["title": "Hi there!"]` desde Swift, `child.leaf` se renderizará de la siguiente manera:

```html
<html>
    <head>
        <title>Hi there!</title>
    </head>
    <body><p>Welcome to Vapor!</p></body>
</html>
```

### Otras etiquetas

#### `#count`

La etiqueta `#count` devuelve el número de elementos en un array. Por ejemplo:

```leaf
Your search matched #count(matches) pages.
```

#### `#lowercased`

La etiqueta `#lowercased` convierte todas las letras de una cadena a minúsculas.

```leaf
#lowercased(name)
```

#### `#uppercased`

La etiqueta `#uppercased` convierte todas las letras de una cadena a mayúsculas.

```leaf
#uppercased(name)
```

#### `#capitalized`

La etiqueta `#capitalized` convierte a mayúsculas la primera letra de cada palabra de una cadena y el resto a minúsculas. Puedes ver [`String.capitalized`](https://developer.apple.com/documentation/foundation/nsstring/1416784-capitalized) para más información.

```leaf
#capitalized(name)
```

#### `#contains`

La etiqueta `#contains` acepta un array y un valor como sus dos parámetros y devuelve verdadero si el array en el primer parámetro contiene el valor en el segundo parámetro.

```leaf
#if(contains(planets, "Earth")):
    Earth is here!
#else:
    Earth is not in this array.
#endif
```

#### `#date`

La etiqueta `#date` formatea las fechas a una cadena legible. Por defecto utiliza el formato ISO8601.

```swift
render(..., ["now": Date()])
```

```leaf
The time is #date(now)
```

Puede pasar una cadena personalizada de formato de fecha como segundo argumento. Puedes ver [`DateFormatter`](https://developer.apple.com/documentation/foundation/dateformatter) de Swift para más información.

```leaf
The date is #date(now, "yyyy-MM-dd")
```

#### `#unsafeHTML`

La etiqueta `#unsafeHTML` actúa como una etiqueta variable - p. ej. `#(variable)`. Sin embargo, no escapa ningún HTML que `variable` pueda contener:

```leaf
The time is #unsafeHTML(styledTitle)
```

!!! note "Nota"
    Debes tener cuidado al usar esta etiqueta para asegurarte de que la variable proporcionada no exponga a sus usuarios a un ataque XSS.

#### `#dumpContext`

La etiqueta `#dumpContext` renderiza todo el contexto a una cadena legible por humanos. Usa esta etiqueta para depurar lo que se está proporcionando como contexto para el renderizado actual.

```leaf
Hello, world!
#dumpContext
```
