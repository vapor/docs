# Aperçu de Leaf

Leaf est un puissant langage de templates dont la syntaxe s'inspire de Swift. Vous pouvez l'utiliser pour générer des pages HTML dynamiques pour un site front-end ou générer des e-mails au contenu enrichi.

Ce guide vous présentera la syntaxe de Leaf ainsi que les balises disponibles.

## Syntaxe de template

Voici un exemple de balise Leaf basique :

```leaf
There are #count(users) users.
```

Les balises de Leaf sont constituées de quatre éléments :

- Le symbole `#` : ceci indique le début d'une balise au parseur de Leaf.
- Un nom comme `count` : ceci identifie la balise.
- Une liste de paramètres comme `(users)` : peut recevoir 0 ou plusieurs arguments.
- Un corps : un corps optionnel peut être passé à certaines balises avec le caractère deux-points `:` et une balise de fermeture.

Ces quatre éléments peuvent avoir différents usages variés en fonction de l'implémentation de la balise. Voyons quelques exemples d'usage de balises fournies par Leaf :

```leaf
#(variable)
#extend("template"): Je suis ajouté à un template ! #endextend
#export("title"): Bienvenue sur Vapor #endexport
#import("body")
#count(friends)
#for(friend in friends): <li>#(friend.name)</li> #endfor
```

Leaf supporte aussi différentes expressions qui vous seront familières en Swift.

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
    Index est pair.
#else:
    Index est impair.
#endif
```

## Contexte

Dans l'exemple du chapitre précédent [Premiers pas](getting-started.md), nous avons utilisé un dictionnaire `[String: String]` pour envoyer des données à Leaf. Cependant, vous pouvez passer n'importe quel type conforme à `Encodable`. Il est en fait préferrable d'utiliser une struct `Encodable` puisque `[String: Any]` n'est pas supporté. Cela signifie que vous *ne pouvez pas* envoyer un tableau, et devriez plutôt l'encapsuler dans une struct :

```swift
struct WelcomeContext: Encodable {
    var title: String
    var numbers: [Int]
}
return req.view.render("home", WelcomeContext(title: "Hello!", numbers: [42, 9001]))
```

Cela exposera `title` et `numbers` à notre template Leaf, qui pourront alors être utilisés dans des balises. Par exemple :

```leaf
<h1>#(title)</h1>
#for(number in numbers):
    <p>#(number)</p>
#endfor
```

## Utilisation

Voici des exemples de cas d'usage communs.

### Conditions

Leaf peut évaluer de nombreuses conditions via la balise `#if`. Par exemple, si vous lui passez une variable, il vérifiera qu'elle existe dans son contexte :

```leaf
#if(title):
    Le titre est #(title)
#else:
    Aucun titre renseigné.
#endif
```

Vous pouvez aussi écrire des comparaisons, par exemple :

```leaf
#if(title == "Bienvenue"):
    Voici une page accueillante.
#else:
    Les inconnus ne sont pas autorisés !
#endif
```

Pour utiliser une autre balise dans votre condition, n'ajoutez pas le signe `#` à la balise intérieure. Par exemple :

```leaf
#if(count(users) > 0):
    Vous avez des utilisateurs !
#else:
    Aucun utilisateur pour le moment :(
#endif
```

Vous pouvez aussi utiliser `#elseif` :

```leaf
#if(title == "Bienvenue"):
    Bienvenue, nouvel utilisateur !
#elseif(title == "Bon retour parmi nous !"):
    Bonjour cher utilisateur habitué.
#else:
    Page inattendue !
#endif
```

### Boucles

Si vous fournissez un tableau d'éléments, Leaf peut boucler dessus et vous permettre de manipuler chaque élément séparément grâce à la balise `#for`.

Par exemple, nous pourrions modifier notre code Swift pour passer une liste de planètes :

```swift
struct SolarSystem: Codable {
    let planets = ["Vénus", "Terre", "Mars"]
}

return req.view.render("solarSystem", SolarSystem())
```

Nous pourrions ensuite boucler dessus avec Leaf comme ceci :

```leaf
Planètes:
<ul>
#for(planet in planets):
    <li>#(planet)</li>
#endfor
</ul>
```

Ce qui génèrerait une vue similaire à celle-ci :

```
Planètes:
- Vénus
- Terre
- Mars
```

### Étendre des templates

La balise `#extend` de Leaf vous permet de copier le contenu d'un template dans un autre. Lorsque vous l'utilisez, vous devrez toujours omettre l'extension .leaf du fichier.

Étendre un template est particulièrement utile pour copier un bout de contenu standard, tel qu'un pied de page, un encart de mise en avant, ou un tableau partagé par plusieurs pages :

```leaf
#extend("footer")
```

Cette balise est également utile pour construire un template à partir d'un autre. Par exemple, vous pourriez avoir un fichier layout.leaf qui définit tout le code nécessaire à la mise en page de votre site – structure HTML, CSS et JavaScript – avec des emplacements vides représentant les zones où votre contenu pourra changer.

Avec cette approche, vous construiriez un template enfant qui ne définirait que le contenu manquant, puis étendriez le template parent qui positionnerait ce contenu au bon endroit. Pour cela, vous pouvez utiliser les balises `#export` et `#import` pour définir puis retrouver le contenu du contexte.

Par exemple, vous pourriez créer un template `child.leaf` comme ceci :

```leaf
#extend("main"):
    #export("body"):
        <p>Bienvenue sur Vapor !</p>
    #endexport
#endextend
```

Nous appelons `#export` pour stoquer du HTML et le rendre disponible au template que nous étendons. Nous générons ensuite `main.leaf` en utilisant les données exportées là où elles sont nécessaires, avec toute variable de contexte reçue depuis le code Swift. Par exemple, `main.leaf` pourrait ressembler à ceci :

```leaf
<html>
    <head>
        <title>#(title)</title>
    </head>
    <body>#import("body")</body>
</html>
```

Nous utilisons ici `#import` pour récupérer le contenu passé à la balise `#extend`. Si l'on passe `["title": "Salut !"]` depuis Swift, `child.leaf` génèrera ceci :

```html
<html>
    <head>
        <title>Salut !</title>
    </head>
    <body><p>Bienvenue sur Vapor !</p></body>
</html>
```

### Autres balises

#### `#count`

La balise `#count` retourne le nombre d'éléments d'un tableau. Par exemple :

```leaf
Votre recherche à trouvé #count(results) résultats.
```

#### `#lowercased`

La balise `#lowercased` convertit toute une chaîne en minuscules.

```leaf
#lowercased(name)
```

#### `#uppercased`

La balise `#uppercased` convertit toute une chaîne en majuscules.

```leaf
#uppercased(name)
```

#### `#capitalized`

La balise `#capitalized` met en majuscules la première lettre de chaque mot d'une chaîne, et met en minuscules toutes les autres. Voir [`String.capitalized`](https://developer.apple.com/documentation/foundation/nsstring/1416784-capitalized) pour plus de détails.

```leaf
#capitalized(name)
```

#### `#contains`

La balise `#contains` accepte deux paramètres, un tableau et une valeur, et retourne vrai si le tableau contient la valeur.

```leaf
#if(contains(planets, "Terre")):
    La Terre est présente !
#else:
    La Terre n'est pas dans ce tableau.
#endif
```

#### `#date`

La balise `#date` formatte des objets dates en chaînes lisibles. Le format ISO8601 est utilisé par défaut.

```swift
render(..., ["now": Date()])
```

```leaf
Date du jour : #date(now)
```

Vous pouvez passer une chaîne de format de date personnalisée en deuxième argument. Voir le [`DateFormatter`](https://developer.apple.com/documentation/foundation/dateformatter) de Swift pour plus d'informations.

```leaf
Date du jour : #date(now, "yyyy-MM-dd")
```

Vous pouvez aussi indiquer un ID de TimeZone en troisième argument du formateur. Voir [`DateFormatter.timeZone`](https://developer.apple.com/documentation/foundation/dateformatter/1411406-timezone) et [`TimeZone`](https://developer.apple.com/documentation/foundation/timezone) pour plus d'informations.

```leaf
Date du jour : #date(now, "yyyy-MM-dd", "America/New_York")
```

#### `#unsafeHTML`

La balise `#unsafeHTML` fonctionne comme une balide de variable - `#(variable)`. Sa différence réside dans le fait qu'elle n'échappera aucun code HTML que `variable` pourrait contenir :

```leaf
Date du jour : #unsafeHTML(styledTitle)
```

!!! Note
    Vous devriez rester prudent en utilisant cette balise et vous assurer que la variable que vous lui passez n'expose pas vos utilisateurs à des attaques XSS.

#### `#comment`

La balise `#comment` vous permet d'ajouter des commentaires à vos templates, qui ne feront pas parti du résultat généré. Cette balise accepte une chaîne en paramètre, qui sere complètement ignorée lors du rendu.

```leaf
#comment("Voici un commentaire sur une seule ligne.")
<h1>#(title)</h1>
```

Pour des commentaires plus longs, vous pouvez utiliser la syntaxe multi-ligne :

```leaf
#comment("""
Ce template génère la page d'accueil.
Il a besoin des variables "title" et "body".
""")
<h1>#(title)</h1>
```

#### `#isEmpty`

La balise `#isEmpty` retourne vrai si une propriété string passée au template est vide. On l'utilise généralement dans une condition `#if` :

```leaf
#if(isEmpty(title)):
    Aucun titre renseigné.
#else:
    Le titre est #(title)
#endif
```

#### `#dumpContext`

La balise `#dumpContext` affiche tout le contexte dans un format lisible par des humains. Utilisez cette balise pour débuguer les données fournies en contexte de la vue à générer.

```leaf
Hello, world!
#dumpContext
```
