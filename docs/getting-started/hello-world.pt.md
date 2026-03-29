# Olá, mundo

Este guia vai te levar passo a passo pela criação de um novo projeto Vapor, compilação e execução do servidor.

Se você ainda não instalou o Swift ou o Vapor Toolbox, confira a seção de instalação.

- [Instalação &rarr; macOS](../install/macos.md)
- [Instalação &rarr; Linux](../install/linux.md)

!!! tip
	O template usado pelo Vapor Toolbox requer Swift 6.0 ou superior

## Novo Projeto

O primeiro passo é criar um novo projeto Vapor no seu computador. Abra o terminal e use o comando de novo projeto do Toolbox. Isso criará uma nova pasta no diretório atual contendo o projeto.

```sh
vapor new hello -n
```

!!! tip
	A flag `-n` fornece um template básico respondendo automaticamente não para todas as perguntas.

!!! tip
    Você também pode obter o template mais recente do GitHub sem o Vapor Toolbox clonando o [repositório do template](https://github.com/vapor/template-bare)

!!! tip
	O Vapor e o template agora usam `async`/`await` por padrão.
	Se você não pode atualizar para o macOS 12 e/ou precisa continuar usando `EventLoopFuture`s,
	use a flag `--branch macos10-15`.

Quando o comando finalizar, entre na pasta recém-criada:

```sh
cd hello
```

## Compilar & Executar

### Xcode

Primeiro, abra o projeto no Xcode:

```sh
open Package.swift
```

Ele começará automaticamente a baixar as dependências do Swift Package Manager. Isso pode demorar um pouco na primeira vez que você abre um projeto. Quando a resolução de dependências estiver completa, o Xcode vai popular os schemes disponíveis.

No topo da janela, à direita dos botões Play e Stop, clique no nome do seu projeto para selecionar o Scheme do projeto e selecione um destino de execução apropriado — provavelmente, "My Mac". Clique no botão play para compilar e executar seu projeto.

Você deverá ver o Console aparecer na parte inferior da janela do Xcode.

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

### Linux

No Linux e outros sistemas operacionais (e até no macOS se você não quiser usar o Xcode), você pode editar o projeto no seu editor de código favorito, como Vim ou VSCode. Veja os [Swift Server Guides](https://github.com/swift-server/guides/blob/main/docs/setup-and-ide-alternatives.md) para detalhes atualizados sobre como configurar outras IDEs.

!!! tip
    Se você está usando o VSCode como editor de código, recomendamos instalar a extensão oficial do Vapor: [Vapor for VS Code](https://marketplace.visualstudio.com/items?itemName=Vapor.vapor-vscode).

Para compilar e executar seu projeto, no Terminal execute:

```sh
swift run
```

Isso vai compilar e executar o projeto. A primeira vez que você executar, pode demorar um pouco para buscar e resolver as dependências. Quando estiver rodando, você deverá ver o seguinte no seu console:

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

## Visitar o Localhost

Abra seu navegador web e visite <a href="http://localhost:8080/hello" target="_blank">localhost:8080/hello</a> ou <a href="http://127.0.0.1:8080" target="_blank">http://127.0.0.1:8080</a>

Você deverá ver a seguinte página.

```html
Hello, world!
```

Parabéns por criar, compilar e executar sua primeira aplicação Vapor! 🎉
