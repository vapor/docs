# Relaciones

La [API de modelo](model.md) de Fluent te ayuda a crear y mantener referencias entre tus modelos mediante relaciones. Estos son los tres tipos de relaciones soportados:

- [Parent](#parent) / [Child](#optional-child) (Uno a uno)
- [Parent](#parent) / [Children](#children) (Uno a muchos)
- [Siblings](#siblings) (Muchos a muchos)

## Parent

La relación `@Parent` guarda una referencia a la propiedad `@ID` de otro modelo.

```swift
final class Planet: Model {
    // Ejemplo de relación parent.
    @Parent(key: "star_id")
    var star: Star
}
```

`@Parent` contiene un `@Field` llamado `id` usado para establecer y actualizar la relación.

```swift
// Establece el id de la relación parent
earth.$star.id = sun.id
```

Por ejemplo, el inicializador de `Planet` se vería de la siguiente manera:

```swift
init(name: String, starID: Star.IDValue) {
    self.name = name
    // ...
    self.$star.id = starID
}
```

El parámetro `key` define la clave del campo en el que se guarda el identificador del parent. Asumiendo que `Star` tiene un identificador `UUID`, esta relación `@Parent` es compatible con la siguiente [definición de campo](schema.md#field).

```swift
.field("star_id", .uuid, .required, .references("star", "id"))
```

Cabe destacar que la restricción (constraint) [`.references`](schema.md#field-constraint) es opcional. Ver [schema](schema.md) para más información.

### Optional Parent

La relación `@OptionalParent` guarda una referencia opcional a la propiedad `@ID` de otro modelo. Funciona de manera similar a `@Parent` pero permite que la relación sea `nil`.

```swift
final class Planet: Model {
    // Ejemplo de una relación parent opcional.
    @OptionalParent(key: "star_id")
    var star: Star?
}
```

La definición del campo es similar a la de `@Parent`, excepto la constraint `.required`, que debe ser omitida.

```swift
.field("star_id", .uuid, .references("star", "id"))
```

## Optional Child

La propiedad `@OptionalChild` crea una relación uno a uno entre dos modelos. No guarda ningún valor en el modelo raíz. 

```swift
final class Planet: Model {
    // Ejemplo de una relación optional child.
    @OptionalChild(for: \.$planet)
    var governor: Governor?
}
```

El parámetro `for` acepta un key path hacia una relación `@Parent` o `@OptionalParent` referenciando el modelo raíz.

Puede añadirse un nuevo modelo a esta relación usando el método `create`.

```swift
// Ejemplo de añadir un nuevo modelo a una relación.
let jane = Governor(name: "Jane Doe")
try await mars.$governor.create(jane, on: database)
```

Esto establecerá de manera automática el identificador (id) del parent en el modelo child.

Dado que esta relación no guarda valores, no se necesita especificar un esquema de base de datos para el modelo raíz.

La naturaleza "uno a uno" de la relación debe hacerse patente en el esquema del modelo child usando una constraint `.unique` en la columna que haga referencia al modelo parent.

```swift
try await database.schema(Governor.schema)
    .id()
    .field("name", .string, .required)
    .field("planet_id", .uuid, .required, .references("planets", "id"))
    // Ejemplo de una restricción única
    .unique(on: "planet_id")
    .create()
```
!!! warning "Advertencia"
    Omitir la restricción de unicidad en el campo del identificador del parent en el esquema del cliente puede ocasionar resultados impredecibles.
    Si no hay una restricción de unicidad, la tabla child puede llegar a contener más de una fila child para un solo parent; en este caso, una propiedad `@OptionalChild` seguirá pudiendo acceder a un único child, sin manera de controlar cuál de ellos carga. Si necesitaras guardas varias filas child para un único parent, usa `@Children`.

## Children

La propiedad `@Children` crea una relación uno a muchos entre dos modelos. No guarda ningún valor en el modelo raíz. 

```swift
final class Star: Model {
    // Ejemplo de una relación children.
    @Children(for: \.$star)
    var planets: [Planet]
}
```

El parámetro `for` acepta un key path a una relación `@Parent` o `@OptionalParent` referenciando el modelo raíz. En este caso, estamos referenciando la relación `@Parent` del anterior [ejemplo](#parent). 

Puede añadirse un nuevo modelo a esta relación usando el método `create`.

```swift
// Ejemplo de añadir un nuevo modelo a una relación.
let earth = Planet(name: "Earth")
try await sun.$planets.create(earth, on: database)
```

Esto establecerá de manera automática el identificador (id) del parent en el modelo child.

Dado que esta relación no guarda valores, no se necesita especificar un esquema de base de datos.

## Siblings

La propiedad `@Siblings` crea una relación muchos a muchos entre dos modelos. Lo hace mediante un modelo terciario llamado pivote.

Echemos un vistazo a un ejemplo de relación muchos a muchos entre un `Planet` y una `Tag`.

```swift
enum PlanetTagStatus: String, Codable { case accepted, pending }

// Ejemplo de modelo pivote.
final class PlanetTag: Model {
    static let schema = "planet+tag"
    
    @ID(key: .id)
    var id: UUID?

    @Parent(key: "planet_id")
    var planet: Planet

    @Parent(key: "tag_id")
    var tag: Tag

    @OptionalField(key: "comments")
    var comments: String?

    @OptionalEnum(key: "status")
    var status: PlanetTagStatus?

    init() { }

    init(id: UUID? = nil, planet: Planet, tag: Tag, comments: String?, status: PlanetTagStatus?) throws {
        self.id = id
        self.$planet.id = try planet.requireID()
        self.$tag.id = try tag.requireID()
        self.comments = comments
        self.status = status
    }
}
```

Cualquier modelo que incluya al menos dos relaciones `@Parent` referenciando a sus respectivos modelos puede usarse como pivote. El modelo puede contener propiedades adicionales como su propio ID, e inclusive otras relaciones `@Parent`.

Añadir una restricción de [unicidad](schema.md#unique) al modelo pivote puede ayudar a prevenir entradas redundantes. Ver [schema](schema.md) para más información.

```swift
// No permite relaciones duplicadas.
.unique(on: "planet_id", "tag_id")
```

Una vez el pivote está creado, usa la propiedad `@Siblings` para crear la relación. 

```swift
final class Planet: Model {
    // Ejemplo de relación sibling.
    @Siblings(through: PlanetTag.self, from: \.$planet, to: \.$tag)
    public var tags: [Tag]
}
```

La propiedad `@Siblings` requiere de tres parámetros:

- `through`: El tipo del modelo pivote.
- `from`: El key path del pivote a la relación parent referenciando el modelo raíz.
- `to`: El key path el pivote a la relación parent referenciando el modelo conectado.

La propiedad `@Siblings` inversa en el modelo conectado completa la relación.

```swift
final class Tag: Model {
    // Example of a siblings relation.
    @Siblings(through: PlanetTag.self, from: \.$tag, to: \.$planet)
    public var planets: [Planet]
}
```

### Vincular Siblings

La propiedad `@Siblings` tiene métodos para añadir o quitar modelos de la relación. 

Usa el método `attach()` para añadir un modelo o una colección (array) de modelos a la relación. Los modelos pivote son creados y guardados de manera automática según sea necesario. Un closure de callback puede especificarse para poblar propiedades adicionales de cada pivote creado:

```swift
let earth: Planet = ...
let inhabited: Tag = ...
// Añadir el modelo a la relación.
try await earth.$tags.attach(inhabited, on: database)
// Poblar los atributos del pivote al establecer la relación.
try await earth.$tags.attach(inhabited, on: database) { pivot in
    pivot.comments = "This is a life-bearing planet."
    pivot.status = .accepted
}
// Añadir varios modelos con atributos a la relación.
let volcanic: Tag = ..., oceanic: Tag = ...
try await earth.$tags.attach([volcanic, oceanic], on: database) { pivot in
    pivot.comments = "This planet has a tag named \(pivot.$tag.name)."
    pivot.status = .pending
}
```

Si estás añadiendo un solo modelo, puedes usar el parámetro `method` para indicar si la relación debería ser revisada o no antes del guardado.

```swift
// Solo añade si la relación no es ya existente.
try await earth.$tags.attach(inhabited, method: .ifNotExists, on: database)
```

Usa el método `detach` para eliminar un modelo de la relación. Esto borra el modelo pivote correspondiente.

```swift
// Elimina el modelo de la relación.
try await earth.$tags.detach(inhabited, on: database)
```

Puedes comprobar que un modelo esté conectado o no usando el método `isAttached`.

```swift
// Comprueba que los modelos estén conectados.
earth.$tags.isAttached(to: inhabited)
```

## Get

Usa el método `get(on:)` para recuperar el valor de una relación. 

```swift
// Recupera todos los planetas del sol.
sun.$planets.get(on: database).map { planets in
    print(planets)
}

// O

let planets = try await sun.$planets.get(on: database)
print(planets)
```

Usa el parámetro `reload` para indicar si la relación debería ser recuperada de nuevo o no de la base de datos si ya ha sido cargada. 

```swift
try await sun.$planets.get(reload: true, on: database)
```

## Query

Usa el método `query(on:)` en una relación para crear un constructor de consulta para los modelos conectados. 

```swift
// Recupera todos los planetas del sol cuyo nombre empiece con M.
try await sun.$planets.query(on: database).filter(\.$name =~ "M").all()
```

Ver [query](query.md) para más información.

## Eager Loading

El constructor de consultas (query builder) de Fluent te permite precargar las relaciones de un modelo cuando es recuperado de la base de datos. Esto se conoce como "eager loading" y te permite acceder a las relaciones de manera sincrónica sin la necesidad de llamar previamente a [`load`](#lazy-eager-loading) o [`get`](#get) . 

Para hacer un "eager load" de una relación, pasa un key path a la relación con el método `with` en el constructor de consultas. 

```swift
// Ejemplo de eager loading.
Planet.query(on: database).with(\.$star).all().map { planets in
    for planet in planets {
        // `star` es accesible de manera sincrónica aquí 
        // dado que ha sido precargada.
        print(planet.star.name)
    }
}

// O

let planets = try await Planet.query(on: database).with(\.$star).all()
for planet in planets {
    // `star` es accesible de manera sincrónica aquí 
    // dado que ha sido precargada.
    print(planet.star.name)
}
```

En el ejemplo anterior,se le ha pasado un key path a la relación [`@Parent`](#parent) llamada `star` con `with`. Esto provoca que el constructor de consultas haga una consulta adicional después de cargar todos los planetas para recuperar todas las estrellas conectadas a éstos. Las estrellas son accesibles de manera sincrónica mediante la propiedad `@Parent`. 

Cada relación precargada (eager loaded) necesita una única consulta adicional, sin importar cuántos modelos se hayan devuelto. La precarga (eager loading) sólo es posible con los métodos de constructor de consultas `all` y `first`. 


### Nested Eager Load

El método de constructor de consultas `with` te permite precargar relaciones en el modelo que está siendo consultado. Sin embargo, también puedes precargar relaciones en los modelos conectados. 

```swift
let planets = try await Planet.query(on: database).with(\.$star) { star in
    star.with(\.$galaxy)
}.all()
for planet in planets {
    // `star.galaxy` es accesible de manera sincrónica aquí 
    // dado que ha sido precargada.
    print(planet.star.galaxy.name)
}
```

El método `with` acepta un closure opcional como segundo parámetro. Este closure acepta un constructor de precarga para la relación elegida. No hay límite de profundidad en el anidado de precargas. 

## Lazy Eager Loading

En caso de que ya hayas recuperado el modelo del parent y quieres cargar una de sus relaciones, puedes usar el método `load(on:)` para hacerlo. Esto recuperará el modelo conectado de la base de datps y permitirá acceder a él como una propiedad local.

```swift
planet.$star.load(on: database).map {
    print(planet.star.name)
}

// O

try await planet.$star.load(on: database)
print(planet.star.name)
```

Para comprobar si una relación se ha cargado, usa la propiedad `value`.

```swift
if planet.$star.value != nil {
    // La relación se ha cargado.
    print(planet.star.name)
} else {
    // La relación no se ha cargado.
    // Intentar acceder a planet.star fallará.
}
```

Si ya tienes el modelo conectado en una variable, puedes establecer la relación manualmente usando la propiedad `value` mencionada anteriormente.

```swift
planet.$star.value = star
```

Esto unirá el modelo conectado al modelo parent como si hubiera sido "eager loaded" o "lazy loaded", sin necesitar una consulta extra a la base de datos.
