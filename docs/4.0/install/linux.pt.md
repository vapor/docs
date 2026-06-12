# Instalar no Linux

Para usar o Vapor, você precisará do Swift 5.9 ou superior. Ele pode ser instalado usando a ferramenta CLI [Swiftly](https://swiftlang.github.io/swiftly/) fornecida pelo Swift Server Workgroup (recomendado), ou os toolchains disponíveis em [Swift.org](https://swift.org/download/).

## Distribuições e Versões Suportadas

O Vapor suporta as mesmas versões de distribuições Linux que o Swift 5.9 ou versões mais recentes suportam. Consulte a [página oficial de suporte](https://www.swift.org/platform-support/) para encontrar informações atualizadas sobre quais sistemas operacionais são oficialmente suportados.

Distribuições Linux não oficialmente suportadas também podem executar o Swift compilando o código fonte, mas o Vapor não pode garantir estabilidade. Saiba mais sobre compilar o Swift a partir do [repositório do Swift](https://github.com/apple/swift#getting-started).

## Instalar o Swift

### Instalação automatizada usando a ferramenta CLI Swiftly (recomendado)

Visite o [site do Swiftly](https://swiftlang.github.io/swiftly/) para instruções sobre como instalar o Swiftly e o Swift no Linux. Após isso, instale o Swift com o seguinte comando:

#### Uso básico

```sh
$ swiftly install latest

Fetching the latest stable Swift release...
Installing Swift 5.9.1
Downloaded 488.5 MiB of 488.5 MiB
Extracting toolchain...
Swift 5.9.1 installed successfully!

$ swift --version

Swift version 5.9.1 (swift-5.9.1-RELEASE)
Target: x86_64-unknown-linux-gnu
```

### Instalação manual com o toolchain

Visite o guia [Using Downloads](https://swift.org/download/#using-downloads) do Swift.org para instruções sobre como instalar o Swift no Linux.

### Fedora

Usuários do Fedora podem simplesmente usar o seguinte comando para instalar o Swift:

```sh
sudo dnf install swift-lang
```

Se você está usando o Fedora 35, precisará adicionar o EPEL 8 para obter o Swift 5.9 ou versões mais recentes.

## Docker

Você também pode usar as imagens Docker oficiais do Swift que já vêm com o compilador pré-instalado. Saiba mais no [Docker Hub do Swift](https://hub.docker.com/_/swift).

## Instalar o Toolbox

Agora que você tem o Swift instalado, vamos instalar o [Vapor Toolbox](https://github.com/vapor/toolbox). Essa ferramenta de linha de comando não é obrigatória para usar o Vapor, mas ajuda a criar novos projetos Vapor.

### Homebrew

O Toolbox é distribuído via Homebrew. Se você ainda não tem o Homebrew, visite <a href="https://brew.sh" target="_blank">brew.sh</a> para instruções de instalação.

```sh
brew install vapor
```

Verifique se a instalação foi bem-sucedida imprimindo a ajuda.

```sh
vapor --help
```

Você deverá ver uma lista de comandos disponíveis.

### Makefile

Se preferir, você também pode compilar o Toolbox a partir do código fonte. Veja os <a href="https://github.com/vapor/toolbox/releases" target="_blank">releases</a> do Toolbox no GitHub para encontrar a versão mais recente.

```sh
git clone https://github.com/vapor/toolbox.git
cd toolbox
git checkout <versão desejada>
make install
```

Verifique se a instalação foi bem-sucedida imprimindo a ajuda.

```sh
vapor --help
```

Você deverá ver uma lista de comandos disponíveis.

## Próximo

Agora que você instalou o Swift e o Vapor Toolbox, crie sua primeira aplicação em [Primeiros Passos &rarr; Olá, mundo](../getting-started/hello-world.md).
