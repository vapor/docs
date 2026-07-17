# Balises personnalisées

Vous pouvez créer vos balises Leaf personnalisées grâce au protocole [`LeafTag`](https://api.vapor.codes/leafkit/leaftag). 

Pour démontrer comment faire, voyons comment créer une balise `#now` qui afficherait le timestamp actuel. La balise acceptera un unique paramètre optionnel pour indiquer le format de date.

!!! Conseil
    Si votre balise personnalisée doit générer du HTML, vous devriez la conformer à `UnsafeUnescapedLeafTag` pour qu'il ne soit pas échappé. Faites attention à valider et sanitiser les entrées utilisateur.

## `LeafTag`

Commencez par créer une classe `NowTag` conforme au protocole `LeafTag`.

```swift
struct NowTag: LeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        ...
    }
}
```

Implémentons ensuite la méthode `render(_:)`. L'objet `LeafContext` qui lui est passé contient tout ce dont nous aurons besoin.

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

## Configuration de la balise

Maintenant que `NowTag` est implémenté, nous devons déclarer son existance à Leaf. Vous pouvez ajouter n'importe quelle balise de cette façon - même si elles viennent d'un autre package. Cela se fait généralement dans `configure.swift` :

```swift
app.leaf.tags["now"] = NowTag()
```

Et c'est tout ! Nous pouvons maintenant utiliser notre balise personnalisée dans Leaf.

```leaf
Timestamp actuel : #now()
```

## Propriétés du contexte

L'objet `LeafContext` possède deux propriétés importantes, `parameters` et `data`, qui contiennent tout ce dont nous avons besoin.

- `parameters`: Un tableau contenant les paramètres de la balise.
- `data`: Un dictionnaire contenant les données de la vue passées à la méthode `render(_:_:)`, qui constituent le contexte.

### Exemple : balise personnalisée Hello

Pour voir comment utiliser cela, implémentons une simple balise `hello` qui utilisera ces deux propriétés.

#### Utiliser les paramètres

Nous pouvons accéder au premier paramètre qui contiendrait le nom de l'utilisateur.

```swift
enum HelloTagError: Error {
    case missingNameParameter
}

struct HelloTag: UnsafeUnescapedLeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        guard let name = ctx.parameters[0].string else {
            throw HelloTagError.missingNameParameter
        }

        return LeafData.string("<p>Bonjour \(name)</p>")
    }
}
```

```leaf
#hello("Jean")
```

#### Utiliser les données du contexte

Nous pouvons accéder à la valeur du nom grâce à la clé "name" de la propriété `data`.

```swift
enum HelloTagError: Error {
    case nameNotFound
}

struct HelloTag: UnsafeUnescapedLeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        guard let name = ctx.data["name"]?.string else {
            throw HelloTagError.nameNotFound
        }

        return LeafData.string("<p>Bonjour \(name)</p>")
    }
}
```

```leaf
#hello()
```

_Controller_ :

```swift
return try await req.view.render("home", ["name": "Jean"])
```
