# Query

La API de consultas (query) de Fluent te permite crear, leer, actualizar y borrar modelos de la base de datos. Soporta el filtrado de resultados, uniones (joins), fragmentaciones (chunking), agregados y más. 

```swift
// Un ejemplo de la API de consultas de Fluent.
let planets = try await Planet.query(on: database)
    .filter(\.$type == .gasGiant)
    .sort(\.$name)
    .with(\.$star)
    .all()
```

Los constructores de consultas (query builders) están ligados a un único tipo de modelo y pueden crearse con el método estático [`query`](model.md#query). También pueden crearse pasando el tipo del modelo al método `query` en un objeto de base de datos (database).

```swift
// También crea un constructor de consultas.
database.query(Planet.self)
```

!!! note "Nota"
    Debes indicar `import Fluent` en el archivo con tus consultas para que el compilador pueda ver las funciones de ayuda (helpers) de Fluent.

## All

El método `all()` devuelve una colección (array) de modelos.

```swift
// Recupera todos los planetas.
let planets = try await Planet.query(on: database).all()
```

El método `all` también soporta recuperar un solo campo del conjunto de resultados. 

```swift
// Recupera todos los nombres de los planetas.
let names = try await Planet.query(on: database).all(\.$name)
```

### First

El método `first()` devuelve un único modelo opcional. Si el resultado de la consulta es más de un modelo, solo se devuelve el primero. Si la consulta no tiene resultados, se devuelve `nil`. 

```swift
// Recupera el primer planeta llamado Earth.
let earth = try await Planet.query(on: database)
    .filter(\.$name == "Earth")
    .first()
```

!!! tip "Consejo"
    Si estás usando `EventLoopFuture`s, este método puede combinarse con [`unwrap(or:)`](../basics/errors.md#abort) para devolver un modelo no opcional o lanzar un error. 

## Filtrado

El método `filter` te permite restringir los modelos incluidos en el conjunto de resultados. Exiten varias sobrecargas para este método. 

### Filtrado por Valor

El método `filter` más común acepta una expresión de operador con un valor.

```swift
// Un ejemplo de filtrado por valor de campo.
Planet.query(on: database).filter(\.$type == .gasGiant)
```

Estas expresiones de operador aceptan un keypath de campo en el lado izquierdo y un valor en el derecho. El valor suministrado debe ser del mismo tipo que el del lado izquierdo, y queda atado a la consulta resultante. Las expresiones de filtrado son de tipado estricto, permitiendo el uso de sintaxis "leaning-dot".

Debajo hay una lista con todos los operadores de valor soportados. 

|Operador|Descripción|
|-|-|
|`==`|Igual que.|
|`!=`|Distinto de.|
|`>=`|Mayor o igual que.|
|`>`|Mayor que.|
|`<`|Menor que.|
|`<=`|Menor o igual que.|

### Filtrado por Campo

El método `filter` soporta comparar dos campos. 

```swift
// Todos los usuarios con el mismo nombre y apellido.
User.query(on: database)
    .filter(\.$firstName == \.$lastName)
```

El filtrado por campo soporta los mismos operadores que el [filtrado por valor](#value-filter).

### Filtrado por Subconjunto

El método `filter` soporta comprobar si el valor de un campo existe dentro de un conjunto de valores dados. 

```swift
// Todos los planetas de tipo gas giant o small rocky.
Planet.query(on: database)
    .filter(\.$type ~~ [.gasGiant, .smallRocky])
```

El conjunto de valores suministrado puede ser cualquier `Collection` de Swift cuyo tipo `Element` sea igual al tipo de valor del campo.

Debajo hay una lista con todos los operadores de subconjuntos soportados. 

|Operador|Descripción|
|-|-|
|`~~`|Valor en el conjunto.|
|`!~`|Valor fuera del conjunto.|

### Filtro "Contiene"

El método `filter` soporta comprobar cuando el valor de un campo de tipo cadena (string) contiene una subcadena dada. 

```swift
// Todos los planetas que empiecen por M
Planet.query(on: database)
    .filter(\.$name =~ "M")
```

Estos operadores solo están disponibles en campos con valores de cadena. 

Debajo hay una lista con todos los operadores "contiene" soportados. 

|Operator|Description|
|-|-|
|`~~`|Contiene subcadena.|
|`!~`|No contiene subcadena.|
|`=~`|Coinciden los prefijos.|
|`!=~`|No coinciden los prefijos.|
|`~=`|Coinciden los sufijos.|
|`!~=`|No coinciden los sufijos.|

### Grupo

Por defecto, todos los filtros añadidos a una consulta necesitarán coincidir. Los constructores de consultas soportan crear un grupo de filtros donde solo uno necesitará coincidir. 

```swift
// Todos los planetas cuyo nombre sea Earth o Mars
Planet.query(on: database).group(.or) { group in
    group.filter(\.$name == "Earth").filter(\.$name == "Mars")
}.all()
```

El método `group` soporta combinar filtros mediante lógica de `and` o `or`. Estos grupos pueden anidarse indefinidamente. Los filtros de nivel superior ("top-level") pueden considerarse como si estuvieran en un grupo `and`.

## Agregados

Los constructores de consultas soportan varios métodos para realizar cálculos en un conjunto de valores, como contar o hacer la media. 

```swift
// Número de planetas en la base de datos. 
Planet.query(on: database).count()
```

Todos los métodos de agregación, salvo `count`, requieren de un "key path" a un campo.

```swift
// Nombre más bajo en orden alfabético.
Planet.query(on: database).min(\.$name)
```

Debajo hay una lista con todos los operadores de agregación disponibles.

|Agregado|Descripción|
|-|-|
|`count`|Número de resultados.|
|`sum`|Suma de los valores resultado.|
|`average`|Media de los valores resultado.|
|`min`|Valor de resultado mínimo.|
|`max`|Valor de resultado máximo.|

Todos los métodos de agregación excepto `count` devuelven el tipo de valor del campo como resultado. `count` siempre devuelve un entero.

## Fragmentos

Los constructores de consultas soportan devolver un conjunto de valores como fragmentos (chunks) separados. Esto puede ayudarte a controlar el uso de memoria al manejar grandes lecturas de bases de datos.

```swift
// Recupera todos los planetas en fragmentos de, como máximo, 64 a la vez.
Planet.query(on: self.database).chunk(max: 64) { planets in
    // Handle chunk of planets.
}
```

El closure suministrado será llamado cero o más veces dependiendo del número total de resultados. Cada ítem devuelto es un `Result` que contiene, bien el modelo, bien un error devuelto al intentar decodificar la entrada de la base de datos. 

## Campos

Por defecto, una consulta leerá todos los campos de un modelo de la base de datos. Puedes seleccionar únicamente un subconjunto de los campos del modelo mediante el método `field`.

```swift
// Solo selecciona los campos id y nombre del planeta
Planet.query(on: database)
    .field(\.$id).field(\.$name)
    .all()
```

Cualquier modelo no seleccionado durante una consulta quedará como no inicializado. Intentar acceder a campos no inicializados directamente dará lugar a un error fatal. Para comprobar si el valor de un campo del modelo está establecido, usa la propiedad `value`. 

```swift
if let name = planet.$name.value {
    // Name se recuperó.
} else {
    // Name no fue recuperado.
    // Acceder a `planet.name` fallará.
}
```

## Unique

El método de constructor de consultas `unique` causa la devolución de valores no duplicados. 

```swift
// Devuelve todos los nombres de usuario únicos. 
User.query(on: database).unique().all(\.$firstName)
```

`unique` es especialmente útil al recuperar un sólo campo con `all`. Sin embargo, también puedes seleccionar múltiples campos usando el método [`field`](#field). Como los identificadores del modelo son siempre únicos,deberías evitar seleccionarlos al usar `unique`. 

## Rangos

Los métodos de constructor de consultas `range` te permiten seleccionar un subconjunto de resultados usando rangos de Swift.

```swift
// Recupera los 5 primeros planetas.
Planet.query(on: self.database)
    .range(..<5)
```

Los valores de los rangos son enteros positivos empezando desde cero. Ver más sobre los [rangos de Swift](https://developer.apple.com/documentation/swift/range).

```swift
// Salta los 2 primeros resultados.
.range(2...)
```

## Uniones

El método de constructor de consultas `join` te permite incluir los campos de otro modelo en tu conjunto de resultados. Puedes unir a tu consulta más de un modelo. 

```swift
// Recupera todos los planetas con una estrella llamada Sun.
Planet.query(on: database)
    .join(Star.self, on: \Planet.$star.$id == \Star.$id)
    .filter(Star.self, \.$name == "Sun")
    .all()
```

El parámetro `on` acepta una expresión de igualdad entre dos campos. Uno de los campos debe existir ya en el conjunto de resultados actual. El otro campo debe existir en el modelo que se está uniendo. Estos campos deben tener el mismo tipo de valor.

La mayoría de métodos de constructores de consultas, como `filter` y `sort`, soportan modelos unidos. Si un método soporta modelos unidos, aceptará el modelo unido como el primer parámetro. 

```swift
// Ordenado por el campo "name" unido al modelo Star.
.sort(Star.self, \.$name)
```

Las consultas que usan uniones seguirán devolviendo una colección (array) del modelo base. Para acceder al modelo unido, usa el metodo `joined`.

```swift
// Accediendo al modelo unido desde el resultado de la consulta.
let planet: Planet = ...
let star = try planet.joined(Star.self)
```

### Alias de Modelo

Los alias de modelo te permiten unir el mismo modelo a una consulta varias veces. Para declarar alias de modelo, crea uno o más tipos conformados a `ModelAlias`. 

```swift
// Ejemplo de alias de modelo.
final class HomeTeam: ModelAlias {
    static let name = "home_teams"
    let model = Team()
}
final class AwayTeam: ModelAlias {
    static let name = "away_teams"
    let model = Team()
}
```

Estos tipos referencian al modelo al que se le ha dado el alias mediante la propiedad `model`. Una vez creados, puedes usar los alias de modelo como modelos normales en un constructor de consultas.

```swift
// Recupera todas las coincidencias donde el nombre del equipo local es Vapor
// y ordena por el nombre del equipo invitado.
let matches = try await Match.query(on: self.database)
    .join(HomeTeam.self, on: \Match.$homeTeam.$id == \HomeTeam.$id)
    .join(AwayTeam.self, on: \Match.$awayTeam.$id == \AwayTeam.$id)
    .filter(HomeTeam.self, \.$name == "Vapor")
    .sort(AwayTeam.self, \.$name)
    .all()
```

Todos los campos del modelo son accesibles por el tipo del alias de modelo mediante `@dynamicMemberLookup`.

```swift
// Accede al modelo unido desde el resultado.
let home = try match.joined(HomeTeam.self)
print(home.name)
```

## Actualizar

Los constructores de consultas soportan actualizar más de un modelo a la vez usando el método `update`.

```swift
// Actualiza todos los planetas llamados "Pluto"
Planet.query(on: database)
    .set(\.$type, to: .dwarf)
    .filter(\.$name == "Pluto")
    .update()
```

`update` soporta los métodos `set`, `filter` y `range`. 

## Borrar

Los constructores de consultas soportan borrar más de un modelo a la vez usando el método `delete`

```swift
// Borra todos los planetas llamados "Vulcan"
Planet.query(on: database)
    .filter(\.$name == "Vulcan")
    .delete()
```

`delete` soporta el método `filter`.

## Paginar

La API de consultas de Fluent soporta la paginación automática de resultados usando el método `paginate`. 

```swift
// Ejemplo de paginación basada en peticiones.
app.get("planets") { req in
    try await Planet.query(on: req.db).paginate(for: req)
}
```

El método `paginate(for:)` usará los parámetros `page` y `per` disponibles en el URI de la petición para devolver el conjunto de resultados deseados. Los metadatos acerca de la página actual y el número total de resultados están incluidos en la clave `metadata`.

```http
GET /planets?page=2&per=5 HTTP/1.1
```

La petición de arriba produciría una respuesta estructurada de la siguiente manera.

```json
{
    "items": [...],
    "metadata": {
        "page": 2,
        "per": 5,
        "total": 8
    }
}
```

El número de página empieza en `1`. También puedes hacer una petición de página de forma manual.

```swift
// Ejemplo de paginación manual.
.paginate(PageRequest(page: 1, per: 2))
```

## Ordenar

Los resultados de una consulta pueden ordenarse según los valores de los campos usando el método `sort`.

```swift
// Recupera los planetas ordenados por su nombre.
Planet.query(on: database).sort(\.$name)
```

Pueden requerirse ordenaciones adicionales como recurso ("fallback") en caso de empate. Los fallbacks se usarán en el orden en que se añadieron al constructor de consultas.

```swift
// Recupera los usuarios ordenados por su nombre. Si dos usuarios tienen el mismo nombre, se ordenan por su edad.
User.query(on: database).sort(\.$name).sort(\.$age)
```
