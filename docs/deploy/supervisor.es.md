# Supervisor

[Supervisor](http://supervisord.org) es un sistema de control de procesos que facilita iniciar, parar y reiniciar tu aplicación de Vapor.

## Instalación

Supervisor puede instalarse en Linux mediante los manejadores de paquetes.

### Ubuntu

```sh
sudo apt-get update
sudo apt-get install supervisor
```

### CentOS y Amazon Linux

```sh
sudo yum install supervisor
```

### Fedora

```sh
sudo dnf install supervisor
```

## Configuración

Cada aplicación de Vapor en tu servidor debería tener su propio fichero de configuración. Para un proyecto `Hello` de ejemplo, el fichero de configuración estaría localizado en `/etc/supervisor/conf.d/hello.conf`

```sh
[program:hello]
command=/home/vapor/hello/.build/release/App serve --env production
directory=/home/vapor/hello/
user=vapor
stdout_logfile=/var/log/supervisor/%(program_name)-stdout.log
stderr_logfile=/var/log/supervisor/%(program_name)-stderr.log
```

Tal y como hemos especificado en nuestro fichero de configuración, el proyecto `Hello` se encuentra en la carpeta "home" del usuario `vapor`. Asegúrate de que `directory` apunta al directorio raíz de tu proyecto, donde el fichero `Package.swift` está.

La marca (flag) `--env production` deshabilitará el registro detallado.

### Entorno

Puedes exportar variables a tu aplicación de Vapor con Supervisor. Para exportar varios valores de entorno, ponlos todos en una línea. Según [Supervisor documentation](http://supervisord.org/configuration.html#program-x-section-values):

> Los valores que contengan caracteres no alfanuméricos deberán ir entrecomillados (p.ej. KEY="val:123",KEY2="val,456"). De lo contrario, entrecomillar los valores es opcional pero recomendado.

```sh
environment=PORT=8123,ANOTHERVALUE="/something/else"
```

Las variables exportadas pueden usarse en Vapor mediante `Environment.get`

```swift
let port = Environment.get("PORT")
```

## Inicio

Ahora ya puedes cargar e iniciar tu aplicación.

```sh
supervisorctl reread
supervisorctl add hello
supervisorctl start hello
```

!!! note "Nota"
	El comando `add` puede haber iniciado ya tu aplicación.
