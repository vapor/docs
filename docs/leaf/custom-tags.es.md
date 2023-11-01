# Etiquetas Personalizadas

Puedes crear etiquetas personalizadas de Leaf utilizando el protocolo [`LeafTag`](https://api.vapor.codes/leafkit/documentation/leafkit/leaftag).

Para demostrarlo, vamos a crear una etiqueta personalizada `#now` que muestra la marca de tiempo actual. La etiqueta también soportará un único parámetro opcional para especificar el formato de fecha.

!!! tip "Consejo"
	Si tu etiqueta personalizada muestra HTML, deberías hacer que tu etiqueta personalizada cumpla con `UnsafeUnescapedLeafTag` para que el HTML no se escape. Recuerda verificar o sanitizar cualquier entrada del usuario.

## `LeafTag`

First create a class called `NowTag` and conform it to `LeafTag`.
Primero, crea una clase llamada `NowTag` y hazla cumplir con `LeafTag`.

```swift
struct NowTag: LeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        ...
    }
}
```

Ahora implementemos el método `render(_:)`. El contexto `LeafContext` pasado a este método tiene todo lo que deberíamos necesitar.

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

## Configurar la Etiqueta

Ahora que hemos implementado `NowTag`, sólo necesitamos informar a Leaf sobre ella. Puedes añadir cualquier etiqueta de esta manera - incluso si provienen de un paquete separado. Típicamente haces esto en `configure.swift`:

```swift
app.leaf.tags["now"] = NowTag()
```

¡Y eso es todo! Ahora podemos usar nuestra etiqueta personalizada en Leaf.

```leaf
The time is #now()
```

## Propiedades de Contexto

El `LeafContext` contiene dos propiedades importantes. `parameters` y `data` que tienen todo lo que deberíamos necesitar.

- `parameters`: Un array que contiene los parámetros de la etiqueta.
- `data`: Un diccionario que contiene los datos de la vista pasados a `render(_:_:)` como contexto.

### Ejemplo de Etiqueta Hello

Para ver cómo usar esto, implementemos una simple etiqueta hello usando ambas propiedades.

#### Usando Parámetros

Podemos acceder al primer parámetro que contendría `name`.

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

#### Usando Data

Podemos acceder al valor `name` usando la clave "name" dentro de la propiedad data.

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

_Controlador_:

```swift
return try await req.view.render("home", ["name": "John"])
```
