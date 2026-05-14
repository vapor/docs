# Tags Personalizadas

Você pode criar tags Leaf personalizadas usando o protocolo [`LeafTag`](https://api.vapor.codes/leafkit/documentation/leafkit/leaftag).

Para demonstrar isso, vamos criar uma tag personalizada `#now` que imprime o timestamp atual. A tag também suportará um único parâmetro opcional para especificar o formato da data.

!!! tip "Dica"
	Se a sua tag personalizada renderiza HTML, você deve conformar sua tag com `UnsafeUnescapedLeafTag` para que o HTML não seja escapado. Lembre-se de verificar ou sanitizar qualquer entrada do usuário.

## `LeafTag`

Primeiro, crie uma classe chamada `NowTag` e conforme-a com `LeafTag`.

```swift
struct NowTag: LeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        ...
    }
}
```

Agora vamos implementar o método `render(_:)`. O contexto `LeafContext` passado para este método tem tudo o que precisamos.

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

## Configurar Tag

Agora que implementamos `NowTag`, só precisamos informar o Leaf sobre ela. Você pode adicionar qualquer tag assim — mesmo que venham de um pacote separado. Você normalmente faz isso em `configure.swift`:

```swift
app.leaf.tags["now"] = NowTag()
```

E é isso! Agora podemos usar nossa tag personalizada no Leaf.

```leaf
A hora é #now()
```

## Propriedades do Contexto

O `LeafContext` contém duas propriedades importantes: `parameters` e `data`, que têm tudo o que precisamos.

- `parameters`: Um array que contém os parâmetros da tag.
- `data`: Um dicionário que contém os dados da view passados para `render(_:_:)` como contexto.

### Exemplo de Tag Hello

Para ver como usar isso, vamos implementar uma tag hello simples usando ambas as propriedades.

#### Usando Parâmetros

Podemos acessar o primeiro parâmetro que conteria o nome.

```swift
enum HelloTagError: Error {
    case missingNameParameter
}

struct HelloTag: UnsafeUnescapedLeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        guard let name = ctx.parameters[0].string else {
            throw HelloTagError.missingNameParameter
        }

        return LeafData.string("<p>Olá \(name)</p>")
    }
}
```

```leaf
#hello("John")
```

#### Usando Data

Podemos acessar o valor do nome usando a chave "name" dentro da propriedade data.

```swift
enum HelloTagError: Error {
    case nameNotFound
}

struct HelloTag: UnsafeUnescapedLeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        guard let name = ctx.data["name"]?.string else {
            throw HelloTagError.nameNotFound
        }

        return LeafData.string("<p>Olá \(name)</p>")
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
