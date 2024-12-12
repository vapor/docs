# Systemd

Systemd es el gestor de sistema y servicios por defecto en la mayoría de distribuciones de Linux. Normalmente está instalado por defecto, así que no se necesita ninguna instalación en las distribuciones de Swift soportadas.

## Configuración

Cada aplicación Vapor en tu servidor debería tener su propio fichero de servicio. Para un proyecto `Hello` de ejemplo, el fichero de configuración estaría localizado en `/etc/systemd/system/hello.service`. Este fichero debería tener lo siguiente:

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

Tal y como está especificado en nuestro fichero de configuración, el proyecto `Hello` se encuentra en la carpeta "home" del usuario `vapor`. Asegúrate de que `WorkingDirectory` apunta al directorio raíz de tu proyecto, que es donde el fichero `Package.swift` está.

La marca (flag) `--env production`deshabilitará el registro detallado.

### Entorno
De lo contrario, entrecomillar los valores es opcional pero recomendado.

Puedes exportar variables de dos maneras via systemd. Puedes crear un fichero de entorno con todas las variables establecidas en él:

```sh
EnvironmentFile=/path/to/environment/file1
EnvironmentFile=/path/to/environment/file2
```


O puedes añadirlas directamente al fichero de servicio bajo `[service]`:

```sh
Environment="PORT=8123"
Environment="ANOTHERVALUE=/something/else"
```
Las variables exportadas pueden usarse en Vapor mediante `Environment.get`

```swift
let port = Environment.get("PORT")
```

## Inicio

Ahora ya puedes cargar, habilitar, iniciar y apagar tu aplicación ejecutando lo siguiente como raíz.

```sh
systemctl daemon-reload
systemctl enable hello
systemctl start hello
systemctl stop hello
systemctl restart hello
```
