# Supervisor

[Supervisor](http://supervisord.org) é um sistema de controle de processos que facilita iniciar, parar e reiniciar sua aplicação Vapor.

## Instalar

O Supervisor pode ser instalado através de gerenciadores de pacotes no Linux.

### Ubuntu

```sh
sudo apt-get update
sudo apt-get install supervisor
```

### CentOS e Amazon Linux

```sh
sudo yum install supervisor
```

### Fedora

```sh
sudo dnf install supervisor
```

## Configurar

Cada aplicação Vapor no seu servidor deve ter seu próprio arquivo de configuração. Para um projeto de exemplo `Hello`, o arquivo de configuração estaria localizado em `/etc/supervisor/conf.d/hello.conf`

```sh
[program:hello]
command=/home/vapor/hello/.build/release/App serve --env production
directory=/home/vapor/hello/
user=vapor
stdout_logfile=/var/log/supervisor/%(program_name)s-stdout.log
stderr_logfile=/var/log/supervisor/%(program_name)s-stderr.log
```

Como especificado no nosso arquivo de configuração, o projeto `Hello` está localizado na pasta home do usuário `vapor`. Certifique-se de que `directory` aponte para o diretório raiz do seu projeto onde o arquivo `Package.swift` está.

A flag `--env production` desabilitará o logging detalhado.

### Ambiente

Você pode exportar variáveis para sua aplicação Vapor com o supervisor. Para exportar múltiplos valores de ambiente, coloque-os todos em uma linha. De acordo com a [documentação do Supervisor](http://supervisord.org/configuration.html#program-x-section-values):

> Valores contendo caracteres não alfanuméricos devem ser citados (ex: KEY="val:123",KEY2="val,456"). Caso contrário, citar os valores é opcional, mas recomendado.

```sh
environment=PORT=8123,OUTROVALOR="/algum/outro/caminho"
```

Variáveis exportadas podem ser usadas no Vapor usando `Environment.get`

```swift
let port = Environment.get("PORT")
```

## Iniciar

Agora você pode carregar e iniciar sua aplicação.

```sh
supervisorctl reread
supervisorctl add hello
supervisorctl start hello
```

!!! note "Nota"
	O comando `add` pode já ter iniciado sua aplicação.
