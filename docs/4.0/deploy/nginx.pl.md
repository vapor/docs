# Wdrażanie z Nginx

Nginx to niezwykle szybki, sprawdzony w boju i łatwy w konfiguracji serwer HTTP oraz proxy. Chociaż Vapor obsługuje bezpośrednią obsługę żądań HTTP z TLS lub bez niego, umieszczenie proxy za Nginx może zapewnić zwiększoną wydajność, bezpieczeństwo i łatwość użycia.

!!! note
    Zalecamy umieszczanie serwerów HTTP Vapor za proxy Nginx.

## Przegląd

Co oznacza umieszczenie serwera HTTP za proxy? Krótko mówiąc, proxy działa jako pośrednik między publicznym internetem a Twoim serwerem HTTP. Żądania trafiają do proxy, które następnie przesyła je do Vapor.

Ważną cechą tego pośredniczącego proxy jest to, że może ono zmieniać, a nawet przekierowywać żądania. Na przykład proxy może wymagać, aby klient używał TLS (https), ograniczać liczbę żądań (rate limiting), a nawet serwować pliki publiczne bez komunikacji z Twoją aplikacją Vapor.

![nginx-proxy](https://cloud.githubusercontent.com/assets/1342803/20184965/5d9d588a-a738-11e6-91fe-28c3a4f7e46b.png)

### Więcej szczegółów

Domyślnym portem do odbierania żądań HTTP jest port `80` (oraz `443` dla HTTPS). Gdy powiążesz serwer Vapor z portem `80`, będzie on bezpośrednio odbierał żądania HTTP i odpowiadał na nie. Dodając proxy takie jak Nginx, wiążesz Vapor z wewnętrznym portem, na przykład portem `8080`.

!!! note
    Porty większe niż 1024 nie wymagają `sudo`, aby je powiązać.

Gdy Vapor jest powiązany z portem innym niż `80` lub `443`, nie będzie dostępny z zewnętrznego internetu. Następnie wiążesz Nginx z portem `80` i konfigurujesz go tak, aby przekierowywał żądania do Twojego serwera Vapor powiązanego z portem `8080` (lub innym wybranym portem).

I to wszystko. Jeśli Nginx jest poprawnie skonfigurowany, zobaczysz, że Twoja aplikacja Vapor odpowiada na żądania na porcie `80`. Nginx przekazuje żądania i odpowiedzi w sposób niewidoczny.

## Instalacja Nginx

Pierwszym krokiem jest zainstalowanie Nginx. Jedną z wspaniałych cech Nginx jest ogromna ilość zasobów społeczności i dokumentacji na jego temat. Z tego powodu nie będziemy tutaj szczegółowo opisywać instalacji Nginx, ponieważ niemal na pewno istnieje samouczek dla Twojej konkretnej platformy, systemu operacyjnego i dostawcy.

Samouczki:

- [How To Install Nginx on Ubuntu 20.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-20-04)
- [How To Install Nginx on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04)
- [How to Install Nginx on CentOS 8](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-centos-8)
- [How To Install Nginx on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-16-04)
- [How to Deploy Nginx on Heroku](https://blog.codeship.com/how-to-deploy-nginx-on-heroku/)

### Menedżery pakietów

Nginx można zainstalować za pomocą menedżerów pakietów na Linuxie.

#### Ubuntu

```sh
sudo apt-get update
sudo apt-get install nginx
```

#### CentOS i Amazon Linux

```sh
sudo yum install nginx
```

#### Fedora

```sh
sudo dnf install nginx
```

### Sprawdzenie instalacji

Sprawdź, czy Nginx został poprawnie zainstalowany, odwiedzając adres IP Twojego serwera w przeglądarce

```
http://server_domain_name_or_IP
```

### Usługa

Usługę można uruchomić lub zatrzymać.

```sh
sudo service nginx stop
sudo service nginx start
sudo service nginx restart
```

## Uruchamianie Vapor

Nginx można uruchomić i zatrzymać za pomocą poleceń `sudo service nginx ...`. Będziesz potrzebować czegoś podobnego, aby uruchamiać i zatrzymywać swój serwer Vapor.

Istnieje wiele sposobów, aby to zrobić, i zależą one od platformy, na którą wdrażasz aplikację. Sprawdź instrukcje dotyczące [Supervisor](supervisor.md), aby dodać polecenia do uruchamiania i zatrzymywania aplikacji Vapor.

## Konfiguracja proxy

Pliki konfiguracyjne dla włączonych witryn znajdują się w `/etc/nginx/sites-enabled/`.

Utwórz nowy plik lub skopiuj przykładowy szablon z `/etc/nginx/sites-available/`, aby zacząć.

Oto przykładowy plik konfiguracyjny dla projektu Vapor o nazwie `Hello` w katalogu domowym.

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

Ten plik konfiguracyjny zakłada, że projekt `Hello` wiąże się z portem `8080` po uruchomieniu w trybie produkcyjnym.

### Serwowanie plików

Nginx może również serwować pliki publiczne bez pytania Twojej aplikacji Vapor. Może to poprawić wydajność, zwalniając proces Vapor do innych zadań przy dużym obciążeniu.

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

Dodanie TLS jest stosunkowo proste, o ile certyfikaty zostały prawidłowo wygenerowane. Aby wygenerować certyfikaty TLS za darmo, sprawdź [Let's Encrypt](https://letsencrypt.org/getting-started/).

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

Powyższa konfiguracja to stosunkowo restrykcyjne ustawienia TLS dla Nginx. Niektóre z tych ustawień nie są wymagane, ale zwiększają bezpieczeństwo.
