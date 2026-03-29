# Instalar no macOS

Para usar o Vapor no macOS, você precisará do Swift 5.9 ou superior. O Swift e todas as suas dependências vêm incluídos com o Xcode.

## Instalar o Xcode

Instale o [Xcode](https://itunes.apple.com/us/app/xcode/id497799835?mt=12) pela Mac App Store.

![Xcode na Mac App Store](../images/xcode-mac-app-store.png)

Após o download do Xcode, você deve abri-lo para concluir a instalação. Isso pode demorar um pouco.

Verifique se a instalação foi bem-sucedida abrindo o Terminal e imprimindo a versão do Swift.

```sh
swift --version
```

Você deverá ver as informações da versão do Swift.

```sh
swift-driver version: 1.75.2 Apple Swift version 5.8 (swiftlang-5.8.0.124.2 clang-1403.0.22.11.100)
Target: arm64-apple-macosx13.0
```

O Vapor 4 requer Swift 5.9 ou superior.

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
git checkout <desired version>
make install
```

Verifique se a instalação foi bem-sucedida imprimindo a ajuda.

```sh
vapor --help
```

Você deverá ver uma lista de comandos disponíveis.

## Próximo

Agora que você instalou o Swift e o Vapor Toolbox, crie sua primeira aplicação em [Primeiros Passos &rarr; Olá, mundo](../getting-started/hello-world.md).
