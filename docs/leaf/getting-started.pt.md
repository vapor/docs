# Leaf

Leaf é uma linguagem de templates poderosa com sintaxe inspirada em Swift. Você pode usá-la para gerar páginas HTML dinâmicas para um site front-end ou gerar e-mails ricos para enviar a partir de uma API.

## Pacote

O primeiro passo para usar o Leaf é adicioná-lo como dependência ao seu projeto no arquivo de manifesto do pacote SPM.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        /// Quaisquer outras dependências ...
        .package(url: "https://github.com/vapor/leaf.git", from: "4.4.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "Leaf", package: "leaf"),
            // Quaisquer outras dependências
        ]),
        // Outros targets
    ]
)
```

## Configuração

Depois de adicionar o pacote ao seu projeto, você pode configurar o Vapor para usá-lo. Isso geralmente é feito em [`configure.swift`](../getting-started/folder-structure.md#configureswift).

```swift
import Leaf

app.views.use(.leaf)
```

Isso diz ao Vapor para usar o `LeafRenderer` quando você chamar `req.view` no seu código.

!!! warning "Aviso"
    Para que o Leaf consiga encontrar os templates ao executar a partir do Xcode, você deve configurar o [diretório de trabalho personalizado](../getting-started/xcode.md#custom-working-directory) no seu workspace do Xcode.

### Cache para Renderização de Páginas

O Leaf possui um cache interno para renderização de páginas. Quando o ambiente da `Application` está definido como `.development`, esse cache é desabilitado, para que as alterações nos templates tenham efeito imediatamente. Em `.production` e todos os outros ambientes, o cache é habilitado por padrão. Quaisquer alterações feitas nos templates não terão efeito até que a aplicação seja reiniciada.

Para desabilitar o cache do Leaf, faça o seguinte:

```swift
app.leaf.cache.isEnabled = false
```

!!! warning "Aviso"
    Embora desabilitar o cache seja útil para depuração, não é recomendado para ambientes de produção, pois pode impactar significativamente o desempenho devido à necessidade de recompilar os templates a cada requisição.

## Estrutura de Pastas

Depois de configurar o Leaf, você precisará garantir que tenha uma pasta `Views` para armazenar seus arquivos `.leaf`. Por padrão, o Leaf espera que a pasta de views esteja em `./Resources/Views` relativo à raiz do seu projeto.

Você provavelmente também vai querer habilitar o [`FileMiddleware`](https://api.vapor.codes/vapor/documentation/vapor/filemiddleware) do Vapor para servir arquivos da sua pasta `/Public`, caso planeje servir arquivos Javascript e CSS, por exemplo.

```
VaporApp
├── Package.swift
├── Resources
│   ├── Views
│   │   └── hello.leaf
├── Public
│   ├── images (recursos de imagens)
│   ├── styles (recursos css)
└── Sources
    └── ...
```

## Renderizando uma View

Agora que o Leaf está configurado, vamos renderizar seu primeiro template. Dentro da pasta `Resources/Views`, crie um novo arquivo chamado `hello.leaf` com o seguinte conteúdo:

```leaf
Olá, #(name)!
```

!!! tip "Dica"
    Se você estiver usando o VSCode como editor de código, recomendamos instalar a extensão do Vapor para habilitar o destaque de sintaxe: [Vapor for VS Code](https://marketplace.visualstudio.com/items?itemName=Vapor.vapor-vscode).

Então, registre uma rota (geralmente feito em `routes.swift` ou em um controller) para renderizar a view.

```swift
app.get("hello") { req -> EventLoopFuture<View> in
    return req.view.render("hello", ["name": "Leaf"])
}

// ou

app.get("hello") { req async throws -> View in
    return try await req.view.render("hello", ["name": "Leaf"])
}
```

Isso usa a propriedade genérica `view` no `Request` em vez de chamar o Leaf diretamente. Isso permite que você troque para um renderizador diferente nos seus testes.

Abra seu navegador e acesse `/hello`. Você deverá ver `Olá, Leaf!`. Parabéns por renderizar sua primeira view com Leaf!
