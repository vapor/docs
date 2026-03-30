# Deploy com Nginx

Nginx é um servidor HTTP e proxy extremamente rápido, testado em batalha e fácil de configurar. Embora o Vapor suporte servir requisições HTTP diretamente com ou sem TLS, usar um proxy como o Nginx pode oferecer maior performance, segurança e facilidade de uso.

!!! note "Nota"
    Recomendamos colocar servidores HTTP Vapor atrás do Nginx como proxy.

## Visão Geral

O que significa usar um proxy para um servidor HTTP? Em resumo, um proxy atua como intermediário entre a internet pública e seu servidor HTTP. As requisições chegam ao proxy e ele as encaminha para o Vapor.

Uma funcionalidade importante desse proxy intermediário é que ele pode alterar ou até redirecionar as requisições. Por exemplo, o proxy pode exigir que o cliente use TLS (https), limitar a taxa de requisições, ou até servir arquivos públicos sem precisar se comunicar com sua aplicação Vapor.

![nginx-proxy](https://cloud.githubusercontent.com/assets/1342803/20184965/5d9d588a-a738-11e6-91fe-28c3a4f7e46b.png)

### Mais Detalhes

A porta padrão para receber requisições HTTP é a porta `80` (e `443` para HTTPS). Quando você vincula um servidor Vapor à porta `80`, ele receberá e responderá diretamente às requisições HTTP que chegam ao seu servidor. Ao adicionar um proxy como o Nginx, você vincula o Vapor a uma porta interna, como a porta `8080`.

!!! note "Nota"
    Portas maiores que 1024 não requerem `sudo` para vincular.

Quando o Vapor está vinculado a uma porta diferente de `80` ou `443`, ele não será acessível pela internet externa. Você então vincula o Nginx à porta `80` e o configura para rotear requisições para seu servidor Vapor vinculado à porta `8080` (ou qualquer porta que você tenha escolhido).

E é isso. Se o Nginx estiver configurado corretamente, você verá sua aplicação Vapor respondendo requisições na porta `80`. O Nginx faz o proxy das requisições e respostas de forma invisível.

## Instalar Nginx

O primeiro passo é instalar o Nginx. Uma das grandes vantagens do Nginx é a enorme quantidade de recursos e documentação da comunidade ao seu redor. Por isso, não entraremos em grandes detalhes aqui sobre a instalação do Nginx, já que quase certamente existe um tutorial para sua plataforma, sistema operacional e provedor específicos.

Tutoriais:

- [How To Install Nginx on Ubuntu 20.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-20-04)
- [How To Install Nginx on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04)
- [How to Install Nginx on CentOS 8](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-centos-8)
- [How To Install Nginx on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-16-04)
- [How to Deploy Nginx on Heroku](https://blog.codeship.com/how-to-deploy-nginx-on-heroku/)

### Gerenciadores de Pacotes

O Nginx pode ser instalado através de gerenciadores de pacotes no Linux.

#### Ubuntu

```sh
sudo apt-get update
sudo apt-get install nginx
```

#### CentOS e Amazon Linux

```sh
sudo yum install nginx
```

#### Fedora

```sh
sudo dnf install nginx
```

### Verificar Instalação

Verifique se o Nginx foi instalado corretamente visitando o endereço IP do seu servidor em um navegador

```
http://server_domain_name_or_IP
```

### Serviço

O serviço pode ser iniciado ou parado.

```sh
sudo service nginx stop
sudo service nginx start
sudo service nginx restart
```

## Iniciando o Vapor

O Nginx pode ser iniciado e parado com os comandos `sudo service nginx ...`. Você precisará de algo similar para iniciar e parar seu servidor Vapor.

Existem várias formas de fazer isso, e elas dependem de qual plataforma você está fazendo o deploy. Confira as instruções do [Supervisor](supervisor.md) para adicionar comandos para iniciar e parar sua aplicação Vapor.

## Configurar Proxy

Os arquivos de configuração para sites habilitados podem ser encontrados em `/etc/nginx/sites-enabled/`.

Crie um novo arquivo ou copie o template de exemplo de `/etc/nginx/sites-available/` para começar.

Aqui está um exemplo de arquivo de configuração para um projeto Vapor chamado `Hello` no diretório home.

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

Este arquivo de configuração assume que o projeto `Hello` está vinculado à porta `8080` quando iniciado no modo de produção.

### Servindo Arquivos

O Nginx também pode servir arquivos públicos sem precisar consultar sua aplicação Vapor. Isso pode melhorar a performance ao liberar o processo do Vapor para outras tarefas sob carga pesada.

```sh
server {
	...

	# Serve all public/static files via nginx and then fallback to Vapor for the rest
	location / {
		try_files $uri @proxy;
	}

	location @proxy {
		...
	}
}
```

### TLS

Adicionar TLS é relativamente simples desde que os certificados tenham sido gerados corretamente. Para gerar certificados TLS gratuitamente, confira o [Let's Encrypt](https://letsencrypt.org/getting-started/).

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

A configuração acima contém opções relativamente rígidas para TLS com Nginx. Algumas das configurações aqui não são obrigatórias, mas aumentam a segurança.
