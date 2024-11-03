# Ficheros


Vapor ofrece una API sencilla para lectura y escritura de archivos de forma asincronica dentro de los controladores de ruta. Esta API está construida sobre el tipo [`NonBlockingFileIO`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio) de NIO's

## Lectura

El método principal para leer un archivo envia fragmentos a  un controlador de devolucion de llamadas a medida que se leen del disco. El archivo a leer se especifica por su ruta. Las rutas relativas buscarán en el directorio de trabajo actual del proceso.

```swift
// Lee asincronicamente un archivo desde el disco.
let readComplete: EventLoopFuture<Void> = req.fileio.readFile(at: "/path/to/file") { chunk in
    print(chunk) // ByteBuffer
}

// O

try await req.fileio.readFile(at: "/path/to/file") { chunk in
    print(chunk) // ByteBuffer
}
// Lectura completada
```
Si utiliza `EventLoopFuture`, el futuro devuelto indicará cuando la lectura ha finalizado o si ha ocurrido un error. Si utiliza `async`/`await` entonces una vez que el `await` regrese, la lectura ha sido completada. Si un error ha ocurrido, arrojará una excepción.

### Flujo

El método `streamFile` convierte un archivo de transmisión en una respuesta. Este método establecerá automáticamente los encabezados apropiados, como `ETag` y `Content-Type`.

The `streamFile` method converts a streaming file to a `Response`. This method will set appropriate headers such as `ETag` and `Content-Type` automatically.

```swift
// Transmite archivos de forma asincrónica como respuesta HTTP.
req.fileio.streamFile(at: "/path/to/file").map { res in
    print(res) // Respuesta
}

// O

let res = req.fileio.streamFile(at: "/path/to/file")
print(res)

```
El resultado puede ser devuelto directamente por su controlador de ruta. 

### Recolector

El método `collectFile` lee el archivo especificado en un búfer.

```swift
// Lee el archivo en un búfer.
req.fileio.collectFile(at: "/path/to/file").map { buffer in 
    print(buffer) // ByteBuffer
}

// O

let buffer = req.fileio.collectFile(at: "/path/to/file")
print(buffer)
```

!!! Warning "Advertencia"
    Este método requiere que el archivo entero este en la memoria a la vez. Utilice lectura fragmentada o en flujo para limitar el uso de memoria.

## Escritura

El método `writeFile` permite escribir un búfer en un archivo 
The `writeFile` method supports writing a buffer to a file.

```swift
// Escribe el búfer en el archivo.
req.fileio.writeFile(ByteBuffer(string: "Hello, world"), at: "/path/to/file")
```
El futuro devuelto indicará cuando se haya completado la escritura o se haya producido un error.


## Middleware

Para más información en cómo enviar archivos automáticamente desde la carpeta pública de su projecto, visite [Middleware &rarr; FileMiddleware](middleware.md#file-middleware).

## Avanzado

Para los casos que la API de vapor no es compatible, puede utilizar el tipo `NonBlockingFileIO` de NIO's directamente.

```swift
// Hilo principal
let fileHandle = try await app.fileio.openFile(
    path: "/path/to/file", 
    eventLoop: app.eventLoopGroup.next()
).get()
print(fileHandle)

// En un controlador de ruta.
let fileHandle = try await req.application.fileio.openFile(
    path: "/path/to/file", 
    eventLoop: req.eventLoop)
print(fileHandle)
```
Para más información, visite SwiftNIO's [API reference](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio).


