# Validación

La API Validation de Vapor te ayuda a validar peticiones entrantes antes de usar la API [Content](content.md) para decodificar datos. 

## Introducción 

La profunda integración del protocolo de tipado seguro `Codable` de Swift en Vapor hace que no tengas que preocuparte tanto por la validación de datos como lo harías en un lenguaje de tipado dinámico. Sin embargo, existen varias razones por las que puedas querer validación explícita usando la API Validation.

### Errores legibles por humanos

Decodificar struct usando la API [Content](content.md) dará errores si alguno de los datos no es válido. Sin embargo, a veces estos mensajes de error pueden carecer de legibilidad para un humano. Por ejemplo, teniendo el siguiente enum respaldado por cadenas:

```swift
enum Color: String, Codable {
    case red, blue, green
}
```

Si un usuario trata de pasar la cadena `"purple"` a una propiedad de tipo `Color`, recibirán un error similar al siguiente:

```
Cannot initialize Color from invalid String value purple for key favoriteColor
```

Aunque este error es técnicamente correcto y ha protegido con éxito el endpoint ante un valor no válido, podría informar de una mejor forma al usuario acerca del error, indicándole las opciones disponibles. Usando la API de validación (Validation), puedes generar errores como el siguiente:

```
favoriteColor is not red, blue, or green
```

Es más, `Codable` interrumpirá la decodificación de un tipo en cuanto reciba el primer error. Esto implica que, aunque varias de las propiedades de la petición sean inválidas, el usuario solo verá el primer error.La API Validation informará sobre todos los errores de validación en una única petición.

### Validación específica

`Codable` controla bien la validación de tipos, pero a veces puedes querer más que eso. Por ejemplo, validar el contenido de una cadena o el tamaño de un número entero. La API Validation posee validadores para ayudar en la validación de datos como emails, conjuntos de caracteres, rangos de números enteros y más.

## Validatable

Para validar una petición, deberás generar una colección de `Validations`. La manera más común de hacerlo es conformar un tipo existente a `Validatable`. 

Echemos un vistazo a cómo podrías añadir validación a este simple endpoint de `POST /users`. Está guí asume que ya estás familiarizado con la API [Content](content.md).

```swift
enum Color: String, Codable {
    case red, blue, green
}

struct CreateUser: Content {
    var name: String
    var username: String
    var age: Int
    var email: String
    var favoriteColor: Color?
}

app.post("users") { req -> CreateUser in
    let user = try req.content.decode(CreateUser.self)
    // Haz algo con user.
    return user
}
```

### Añadiendo Validaciones

El primer paso es conformar el tipo que estás decodificando, en este caso `CreateUser`, a `Validatable`. Esto puede hacerse en una extensión.

```swift
extension CreateUser: Validatable {
    static func validations(_ validations: inout Validations) {
        // Aquí van las validaciones.
    }
}
```

El método estático `validations(_:)` se llamará cuando `CreateUser` sea validado. Cualquier validación que quieras llevar a cabo deberá ser añadida a la colección `Validations` proporcionada. Veamos como añadir una simple validación que requiera que el email del usuario sea válido.

```swift
validations.add("email", as: String.self, is: .email)
```

El primer parámetro es la clave esperada del valor, en este caso, `"email"`. Esta clave debería ser igual al nombre de la propiedad del tipo que se está validando. El segundo parámetro, `as`, es el tipo esperado, en este caso, `String`. Suele coincidir con el tipo de la propiedad, pero no siempre. Finalmente, pueden añadirse uno o más validadores después del tercer parámetro, `is`. En este caso,estamos añadiendo un único validador que comprueba si el valor es una dirección de email.

### Validando contenido de peticiones

Una vez hayas conformado tu tipo a `Validatable`, la función estática `validate(content:)` puede usarse para validar el contenido de una petición. Antes de `req.content.decode(CreateUser.self)`, añade la línea a continuación en el controlador de ruta:

```swift
try CreateUser.validate(content: req)
```

Ahora, prueba a enviar la siguiente petición con un email no válido:

```http
POST /users HTTP/1.1
Content-Length: 67
Content-Type: application/json

{
    "age": 4,
    "email": "foo",
    "favoriteColor": "green",
    "name": "Foo",
    "username": "foo"
}
```

Deberías recibir el siguiente error:

```
email is not a valid email address
```

### Validando la consulta (query) de una petición

Los tipos conformados con `Validatable` también disponen de `validate(query:)`, que puede usarse para validar la cadena de consulta (query string) de una petición. Añade las siguientes líneas al controlador de ruta:

```swift
try CreateUser.validate(query: req)
req.query.decode(CreateUser.self)
```

Ahora, prueba a enviar la siguiente petición con un email no válido en la cadena de consulta.

```http
GET /users?age=4&email=foo&favoriteColor=green&name=Foo&username=foo HTTP/1.1

```

Deberías recibir el siguiente error:

```
email is not a valid email address
```

### Validación de números enteros

Genial, ahora probemos a añadir una validación para `age`.

```swift
validations.add("age", as: Int.self, is: .range(13...))
```

La validación de edad requiere que `age` sea igual o superior a `13`. Si pruebas la petición mencionada arriba, deberías ver un nuevo error:

```
age is less than minimum of 13, email is not a valid email address
```

### Validación de cadenas (string)

A continuación, añadiremos validaciones para `name` y `username`. 

```swift
validations.add("name", as: String.self, is: !.empty)
validations.add("username", as: String.self, is: .count(3...) && .alphanumeric)
```

La validación de `name` usa el operador `!` para invertir la validación de `.empty`, requiriendo que la cadena no sea vacía.

La validación de `username` combina dos validadores mediante el uso de `&&`, requiriendo que la cadena tenga una longitud de, al menos, 3 caracteres _y_ que contenga únicamente caracteres alfanuméricos.

### Validación de Enums

Finalmente, veremos una validación ligeramente más avanzada para comprobar que el `favoriteColor` proporcionado es válido.

```swift
validations.add(
    "favoriteColor", as: String.self,
    is: .in("red", "blue", "green"),
    required: false
)
```

Como no es posible decodificar un `Color` desde un valor no válido, esta validación usa `String` como tipo base. Utiliza en validador `.in` para verificar que el valor es una opción válida: red, blue, o green. Como este valor es opcional, `required` se establece a `false` para indicar que la validación no debería fallar si esta clave no se encuentra en los datos de la petición.

Ten en cuenta que, aunque la validación de `favoriteColor` pasará si la clave falta, no pasará si se proporciona `null` (nulo). Si quieres soportar `null`, cambia el tipo de la validación a `String?` y usa el operador de conveniencia `.nil ||` (leer como: "es nil (nulo) o ...").

```swift
validations.add(
    "favoriteColor", as: String?.self,
    is: .nil || .in("red", "blue", "green"),
    required: false
)
```

### Errores Personalizados

Puede que quieras añadir errores personalizados que sean legibles por humanos a tus `Validations` o `Validator`. Para hacerlo, simplemente proporciona el parámetro adicional `customFailureDescription`, que sobrescribirá el error por defecto.

```swift
validations.add(
	"name",
	as: String.self,
	is: !.empty,
	customFailureDescription: "Provided name is empty!"
)
validations.add(
	"username",
	as: String.self,
	is: .count(3...) && .alphanumeric,
	customFailureDescription: "Provided username is invalid!"
)
```


## Validadores (Validators)

Debajo tienes una lista de los validadores soportados actualmente y una breve explicación de lo que hacen.

|Validación|Descripción|
|-|-|
|`.ascii`|Contiene únicamente caracteres ASCII.|
|`.alphanumeric`|Contiene únicamente caracteres alfanuméricos.|
|`.characterSet(_:)`|Contiene únicamente caracteres del `CharacterSet` (conjunto de caracteres) proporcionado.|
|`.count(_:)`|El número de elementos (count) de una colección está entre los límites proporcionados.|
|`.email`|Contiene un email válido.|
|`.empty`|La colección está vacía.|
|`.in(_:)`|El valor se encuentra en la `Collection` (colección) proporcionada.|
|`.nil`|El valor es `null` (nulo).|
|`.range(_:)`|El valor se encuentra en el `Range` (rango) proporcionado.|
|`.url`|Contiene una URL válida.|

Los validadores también pueden combinarse mediante operadores para construir validaciones complejas. 

|Operador|Posición|Descripción|
|-|-|-|
|`!`|prefijo|Invierte un validador, requiriendo lo opuesto.|
|`&&`|infijo|Combina dos validadores, requiere ambos.|
|`||`|infijo|Combina dos validadores, requiere al menos uno.|
