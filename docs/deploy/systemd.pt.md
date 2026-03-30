# Systemd

Systemd é o gerenciador de sistema e serviços padrão na maioria das distribuições Linux. Geralmente já vem instalado por padrão, então nenhuma instalação é necessária nas distribuições Swift suportadas.

## Configurar

Cada aplicação Vapor no seu servidor deve ter seu próprio arquivo de serviço. Para um projeto de exemplo `Hello`, o arquivo de configuração estaria localizado em `/etc/systemd/system/hello.service`. Este arquivo deve se parecer com o seguinte:

```sh
[Unit]
Description=Hello
Requires=network.target
After=network.target

[Service]
Type=simple
User=vapor
Group=vapor
Restart=always
RestartSec=3
WorkingDirectory=/home/vapor/hello
ExecStart=/home/vapor/hello/.build/release/App serve --env production
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=vapor-hello

[Install]
WantedBy=multi-user.target
```

Como especificado no nosso arquivo de configuração, o projeto `Hello` está localizado na pasta home do usuário `vapor`. Certifique-se de que `WorkingDirectory` aponte para o diretório raiz do seu projeto onde o arquivo `Package.swift` está.

A flag `--env production` desabilitará o logging detalhado.

### Ambiente

Você pode exportar variáveis de duas formas via systemd. Criando um arquivo de ambiente com todas as variáveis definidas:

```sh
EnvironmentFile=/path/to/environment/file1
EnvironmentFile=/path/to/environment/file2
```


Ou você pode adicioná-las diretamente ao arquivo de serviço em `[service]`:

```sh
Environment="PORT=8123"
Environment="ANOTHERVALUE=/something/else"
```
Variáveis exportadas podem ser usadas no Vapor usando `Environment.get`

```swift
let port = Environment.get("PORT")
```

## Iniciar

Agora você pode carregar, habilitar, iniciar, parar e reiniciar sua aplicação executando os seguintes comandos como root.

```sh
systemctl daemon-reload
systemctl enable hello
systemctl start hello
systemctl stop hello
systemctl restart hello
```
