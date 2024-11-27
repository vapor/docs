# Ficheros

Vapor ofrece una API sencilla para leer y escribir archivos de forma asíncrona dentro de los controladores de rutas. Esta API se construye sobre el tipo [`NonBlockingFileIO`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio) de NIO.

## Lectura

El método principal para leer un archivo entrega fragmentos al controlador de devolución de llamadas a medida que se leen del disco. El archivo a leer se especifica mediante su ruta. Las rutas relativas buscarán en el directorio de trabajo actual del proceso.

```swift
// Lee un archivo del disco de forma asíncrona.
let readComplete: EventLoopFuture<Void> = req.fileio.readFile(at: "/path/to/file") { chunk in
    print(chunk) // ByteBuffer
}

// O
try await req.fileio.readFile(at: "/path/to/file") { chunk in
    print(chunk) // ByteBuffer
}
// La lectura ha finalizado
```

Si se utiliza `EventLoopFuture`, el futuro devuelto indicará cuándo ha completado la lectura o si ha ocurrido un error. Si se utiliza `async`/`await`, cuando regresa del `await`, la lectura se ha completado. En caso de error, se lanzará una excepción.

### Flujo

El método `streamFile` convierte un archivo de transmisión en una respuesta `Response`. Este método establecerá automáticamente los encabezados apropiados, como `ETag` y `Content-Type`.

```swift
// Ttransmite el archivo como una respuesta HTTP de forma asíncrona.
req.fileio.streamFile(at: "/path/to/file").map { res in
    print(res) // Response
}

// O
let res = req.fileio.streamFile(at: "/path/to/file")
print(res)
```

El resultado puede ser devuelto directamente por su controlador de ruta. 

### Recolector

El método `collectFile` lee el archivo especificado en un buffer.

```swift
// Lee el archivo en un buffer.
req.fileio.collectFile(at: "/path/to/file").map { buffer in 
    print(buffer) // ByteBuffer
}

// o
let buffer = req.fileio.collectFile(at: "/path/to/file")
print(buffer)
```

!!! Warning "Advertencia"
    Este método requiere que el archivo entero esté en la memoria desde el inicio. Utilice una lectura por fragmentos (chunked) o flujo contínuo (streaming) para limitar el uso de memoria.

## Escritura

El método `writeFile` permite escribir un buffer a un archivo.

```swift
// Escribe un buffer a un archivo.
req.fileio.writeFile(ByteBuffer(string: "Hello, world"), at: "/path/to/file")
```

El futuro devuelto indicará cuándo se ha completado la escritura o si se ha producido un error.

## Middleware

Para más información acerca de cómo enviar archivos automáticamente desde la carpeta _Public_ de su projecto, visite [Middleware &rarr; FileMiddleware](middleware.md#file-middleware).

## Avanzado

En casos donde la API de vapor no de asistencia, puede utilizar directamente el tipo `NonBlockingFileIO` de NIO.

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
Para más información, visite la [API reference](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio) de SwiftNIO.
