# Despliegue con Nginx

Nginx es un servidor y proxy HTTP extremadamente rápido, confiable, y fácil de configurar. Aunque Vapor soporta servir peticiones HTTP con o sin TLS directamente, hacer un proxy con Nginx puede proporcionar un aumento en rendimiento, seguridad y facilidad de uso. 

!!! note "Nota"
    Recomendamos hacer un proxy de los servidores HTTP de Vapor con Nginx.

## Descripción

¿Qué significa poner un proxy a un servidor HTTP? En pocas palabras, un proxy actúa como un intermediario entre el Internet público y tu servidor HTTP. Las peticiones llegan al proxy y éste las envía a Vapor. 

Una propiedad importante de este proxy intermediario es que puede alterar e inclusive redirigir las peticiones. Por ejemplo, el proxy puede requerir que el cliente use TLS (https), limitar la tasa de peticiones e incluso servir ficheros públicos sin comunicarse con tu aplicación de Vapor.

![nginx-proxy](https://cloud.githubusercontent.com/assets/1342803/20184965/5d9d588a-a738-11e6-91fe-28c3a4f7e46b.png)

### Más Detalles

El puerto por defecto para recibir peticiones HTTP es el puerto `80` (y `443` para HTTPS). Cuando enlazas un servidor de Vapor al puerto `80`, recibirá y responderá directamente a las peticiones HTTP que lleguen a tu servidor. Cuando añades un proxy como Nginx, enlazas Vapor a un puerto interno, como el puerto `8080`. 

!!! note "Nota"
    Puertos mayores que no necesitan `sudo` para enlazarse.

Cuando Vapor está enlazado a otro puerto además de `80` o `443`, no será accesible para el Internet externo. Entonces enlazas Nginx al puerto `80` y lo configuras para que enrute las peticiones a tu servidor de Vapor enlazado en el puerto `8080` (o el que hayas elegido).

Y eso es todo. Si Nginx está configurado correctamente, verás que tu aplicación de Vapor responde a las peticiones en el puerto `80`. Nginx actúa como proxy ante las peticiones y responde de manera invisible.

## Instalar Nginx

El primer paso es instalar Nginx. Una de las mejores cosas de Nginx es la enorme cantidad de recursos de la comunidad y documentación que tiene. Por ello, no entraremos en detalle sobre cómo instalar Nginx, pues seguramente hay un tutorial para tu plataforma, sistema operativo y proveedor.

Tutoriales:

- [How To Install Nginx on Ubuntu 20.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-20-04)
- [How To Install Nginx on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04)
- [How to Install Nginx on CentOS 8](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-centos-8)
- [How To Install Nginx on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-16-04)
- [How to Deploy Nginx on Heroku](https://blog.codeship.com/how-to-deploy-nginx-on-heroku/)

### Package Managers

Nginx puede instalarse mediante package managers en Linux.

#### Ubuntu

```sh
sudo apt-get update
sudo apt-get install nginx
```

#### CentOS y Amazon Linux

```sh
sudo yum install nginx
```

#### Fedora

```sh
sudo dnf install nginx
```

### Validar la Instalación

Comprueba que Nginx se ha instalado correctamente visitando la dirección IP de tu servidor en un navegador.

```
http://server_domain_name_or_IP
```

### Servicio

El servicio puede iniciarse o detenerse.

```sh
sudo service nginx stop
sudo service nginx start
sudo service nginx restart
```

## Arrancando Vapor

Nginx puede iniciarse y detenerse con los comandos `sudo service nginx ...`. Necesitarás algo parecido para iniciar y detener tu servidor de Vapor.

Existen muchas formas de hacerlo, dependiendo de la plataforma en la que vayas a desplegar. Revisa las instrucciones de [Supervisor](supervisor.md) para añadir comandos para iniciar y detener tu aplicación de Vapor.

## Configurar el Proxy

Los ficheros de configuración para los sitios habilitados pueden encontrarse en `/etc/nginx/sites-enabled/`.

Crea un nuevo fichero o copia la plantilla de ejemplo ubicada en `/etc/nginx/sites-available/` para empezar.

A continuación tienes un ejemplo de un fichero de configuración para un proyecto de Vapor llamado `Hello` en el directorio "home".

```sh
server {
    server_name hello.com;
    listen 80;

    root /home/vapor/Hello/Public/;

    location @proxy {
        proxy_pass http://127.0.0.1:8080;
        proxy_pass_header Server;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 3s;
        proxy_read_timeout 10s;
    }
}
```

Este fichero de configuración asume que el proyecto `Hello` se enlaza con el puerto `8080` al iniciarlo en el modo de producción.

### Servir Ficheros

Nginx también puede servir ficheros públicos sin preguntar a tu aplicación de Vapor. Esto puede mejorar el rendimiento liberando el proceso de Vapor para otras tareas más pesadas.

```sh
server {
	...

	# Sirve todos los ficheros públicos/estáticos via nginx y recurre a Vapor para el resto
	location / {
		try_files $uri @proxy;
	}

	location @proxy {
		...
	}
}
```

### TLS

Añadir TLS es relativamente sencillo siempre y cuando los certificados hayan sido generados correctamente. Para generar certificados TLS gratuitamente, echa un vistazo a [Let's Encrypt](https://letsencrypt.org/getting-started/).

```sh
server {
    ...

    listen 443 ssl;

    ssl_certificate /etc/letsencrypt/live/hello.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/hello.com/privkey.pem;

    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_dhparam /etc/ssl/certs/dhparam.pem;
    ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_stapling on;
    ssl_stapling_verify on;
    add_header Strict-Transport-Security max-age=15768000;

    ...

    location @proxy {
       ...
    }
}
```

La configuración de arriba son los ajustes relativamente estrictos para TLS con Nginx. Algunos ajustes no son necesarios, pero aumentan la seguridad.
