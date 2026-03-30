# Arquivos

O Vapor oferece uma API simples para ler e escrever arquivos de forma assíncrona dentro de route handlers. Esta API é construída sobre o tipo [`NonBlockingFileIO`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio) do NIO.

## Leitura

O método principal para ler um arquivo entrega partes (chunks) a um callback handler conforme são lidas do disco. O arquivo a ser lido é especificado pelo seu caminho. Caminhos relativos procurarão no diretório de trabalho atual do processo.

```swift
// Lê um arquivo do disco de forma assíncrona.
let readComplete: EventLoopFuture<Void> = req.fileio.readFile(at: "/path/to/file") { chunk in
    print(chunk) // ByteBuffer
}

// Ou

try await req.fileio.readFile(at: "/path/to/file") { chunk in
    print(chunk) // ByteBuffer
}
// Leitura completa
```

Se estiver usando `EventLoopFuture`s, o future retornado sinalizará quando a leitura foi concluída ou quando um erro ocorreu. Se estiver usando `async`/`await`, uma vez que o `await` retornar, a leitura foi concluída. Se um erro ocorrer, ele lançará um erro.

### Stream

O método `streamFile` converte um arquivo em streaming para uma `Response`. Este método definirá headers apropriados como `ETag` e `Content-Type` automaticamente.

```swift
// Faz streaming de um arquivo como resposta HTTP de forma assíncrona.
req.fileio.streamFile(at: "/path/to/file").map { res in
    print(res) // Response
}

// Ou

let res = req.fileio.streamFile(at: "/path/to/file")
print(res)

```

O resultado pode ser retornado diretamente pelo seu route handler.

### Collect

O método `collectFile` lê o arquivo especificado em um buffer.

```swift
// Lê o arquivo em um buffer.
req.fileio.collectFile(at: "/path/to/file").map { buffer in
    print(buffer) // ByteBuffer
}

// ou

let buffer = req.fileio.collectFile(at: "/path/to/file")
print(buffer)
```

!!! warning "Aviso"
    Este método requer que o arquivo inteiro esteja na memória de uma vez. Use leitura por chunks ou streaming para limitar o uso de memória.

## Escrita

O método `writeFile` suporta escrever um buffer em um arquivo.

```swift
// Escreve buffer em um arquivo.
req.fileio.writeFile(ByteBuffer(string: "Hello, world"), at: "/path/to/file")
```

O future retornado sinalizará quando a escrita foi concluída ou quando um erro ocorreu.

## Middleware

Para mais informações sobre servir arquivos da pasta _Public_ do seu projeto automaticamente, veja [Middleware &rarr; FileMiddleware](middleware.md#file-middleware).

## Avançado

Para casos que a API do Vapor não suporta, você pode usar o tipo `NonBlockingFileIO` do NIO diretamente.

```swift
// Thread principal.
let fileHandle = try await app.fileio.openFile(
    path: "/path/to/file",
    eventLoop: app.eventLoopGroup.next()
).get()
print(fileHandle)

// Em um route handler.
let fileHandle = try await req.application.fileio.openFile(
    path: "/path/to/file",
    eventLoop: req.eventLoop)
print(fileHandle)
```

Para mais informações, visite a [referência de API](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio) do SwiftNIO.
