# Swift Package Manager

O [Swift Package Manager](https://swift.org/package-manager/) (SPM) é usado para compilar o código fonte e as dependências do seu projeto. Como o Vapor depende bastante do SPM, é uma boa ideia entender o básico de como ele funciona.

O SPM é similar ao Cocoapods, Ruby gems e NPM. Você pode usar o SPM pela linha de comando com comandos como `swift build` e `swift test` ou com IDEs compatíveis. No entanto, diferente de alguns outros gerenciadores de pacotes, não existe um índice central de pacotes para o SPM. O SPM utiliza URLs para repositórios Git e versiona as dependências usando [Git tags](https://git-scm.com/book/en/v2/Git-Basics-Tagging).

## Manifesto do Pacote

O primeiro lugar que o SPM procura no seu projeto é o manifesto do pacote. Ele deve estar sempre localizado no diretório raiz do seu projeto e nomeado como `Package.swift`.

Dê uma olhada neste exemplo de manifesto de pacote.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
```

Cada parte do manifesto é explicada nas seções a seguir.

### Versão das Ferramentas

A primeira linha de um manifesto de pacote indica a versão das ferramentas Swift necessária. Isso especifica a versão mínima do Swift que o pacote suporta. A API de descrição de pacotes também pode mudar entre versões do Swift, então essa linha garante que o Swift saberá como interpretar seu manifesto.

### Nome do Pacote

O primeiro argumento de `Package` é o nome do pacote. Se o pacote for público, você deve usar o último segmento da URL do repositório Git como nome.

### Plataformas

O array `platforms` especifica quais plataformas este pacote suporta. Ao especificar `.macOS(.v12)`, este pacote requer macOS 12 ou superior. Quando o Xcode carregar este projeto, ele automaticamente definirá a versão mínima de deployment para macOS 12 para que você possa usar todas as APIs disponíveis.

### Dependências

Dependências são outros pacotes SPM dos quais seu pacote depende. Todas as aplicações Vapor dependem do pacote Vapor, mas você pode adicionar quantas outras dependências quiser.

No exemplo acima, você pode ver que [vapor/vapor](https://github.com/vapor/vapor) versão 4.76.0 ou superior é uma dependência deste pacote. Quando você adiciona uma dependência ao seu pacote, deve em seguida indicar quais [targets](#targets) dependem dos módulos recém-disponíveis.

### Targets

Targets são todos os módulos, executáveis e testes que seu pacote contém. A maioria das aplicações Vapor terá dois targets, embora você possa adicionar quantos quiser para organizar seu código. Cada target declara de quais módulos ele depende. Você deve adicionar os nomes dos módulos aqui para poder importá-los no seu código. Um target pode depender de outros targets no seu projeto ou de quaisquer módulos expostos por pacotes que você adicionou ao array principal de [dependências](#dependências).

## Estrutura de Pastas

Abaixo está a estrutura de pastas típica para um pacote SPM.

```
.
├── Sources
│   └── App
│       └── (Source code)
├── Tests
│   └── AppTests
└── Package.swift
```

Cada `.target` ou `.executableTarget` corresponde a uma pasta na pasta `Sources`.
Cada `.testTarget` corresponde a uma pasta na pasta `Tests`.

## Package.resolved

Na primeira vez que você compilar seu projeto, o SPM criará um arquivo `Package.resolved` que armazena a versão de cada dependência. Na próxima vez que você compilar seu projeto, essas mesmas versões serão usadas mesmo se versões mais recentes estiverem disponíveis.

Para atualizar suas dependências, execute `swift package update`.

## Xcode

Se você está usando o Xcode 11 ou superior, alterações em dependências, targets, products, etc. acontecerão automaticamente sempre que o arquivo `Package.swift` for modificado.

Se você quiser atualizar para as dependências mais recentes, use File &rarr; Swift Packages &rarr; Update To Latest Swift Package Versions.

Você também pode querer adicionar o arquivo `.swiftpm` ao seu `.gitignore`. É onde o Xcode armazenará a configuração do seu projeto Xcode.
