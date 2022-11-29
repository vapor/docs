# Deployen met Nginx

Nginx is een extreem snelle, in de strijd geteste, en eenvoudig te configureren HTTP server en proxy. Hoewel Vapor het direct serveren van HTTP verzoeken met of zonder TLS ondersteunt, kan proxying achter Nginx voor betere prestaties, veiligheid en gebruiksgemak zorgen. 

!!! note "Opmerking"
    Wij raden aan de Vapor HTTP servers te proxen achter Nginx.

## Overzicht

Wat betekent het om een HTTP server te proxyen? In het kort, een proxy fungeert als tussenpersoon tussen het publieke internet en uw HTTP server. Verzoeken komen naar de proxy en deze stuurt ze vervolgens door naar Vapor. 

Een belangrijke eigenschap van deze tussenpersoon proxy is dat het de verzoeken kan veranderen of zelfs omleiden. De proxy kan bijvoorbeeld eisen dat de client TLS (https) gebruikt, verzoeken beperken in snelheid, of zelfs publieke bestanden serveren zonder met uw Vapor toepassing te praten.

![nginx-proxy](https://cloud.githubusercontent.com/assets/1342803/20184965/5d9d588a-a738-11e6-91fe-28c3a4f7e46b.png)

### Meer Details

De standaard poort voor het ontvangen van HTTP verzoeken is poort `80` (en `443` voor HTTPS). Wanneer u een Vapor server bindt aan poort `80`, zal deze direct HTTP verzoeken ontvangen en beantwoorden die op uw server binnenkomen. Bij het toevoegen van een proxy zoals Nginx, bindt u Vapor aan een interne poort, zoals poort `8080`. 

!!! note "Opmerking"
    Poorten groter dan 1024 hebben `sudo` niet nodig om te binden.

Wanneer Vapor is gebonden aan een andere poort dan `80` of `443`, zal deze niet toegankelijk zijn voor het buiten-internet. U bindt dan Nginx aan poort `80` en configureert het om verzoeken te routeren naar uw Vapor server gebonden aan poort `8080` (of welke poort u ook gekozen heeft).

En dat is het. Als Nginx goed is geconfigureerd, zult u uw Vapor app zien reageren op verzoeken op poort `80`. Nginx proxied de verzoeken en antwoorden onzichtbaar.

## Installeer Nginx

De eerste stap is het installeren van Nginx. Een van de geweldige delen van Nginx is de enorme hoeveelheid community bronnen en documentatie eromheen. Daarom zullen we hier niet in detail treden over het installeren van Nginx, omdat er vrijwel zeker een tutorial is voor uw specifieke platform, OS, en provider.

Tutorials:

- [Hoe Nginx te installeren op Ubuntu 20.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-20-04)
- [Hoe Nginx te installeren op Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04)
- [Hoe Nginx te installeren op CentOS 8](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-centos-8)
- [Hoe Nginx te installeren op Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-16-04)
- [Hoe Nginx te installeren op on Heroku](https://blog.codeship.com/how-to-deploy-nginx-on-heroku/)

### Pakketbeheerders

Nginx kan worden geïnstalleerd via pakketbeheer op Linux.

#### Ubuntu

```sh
sudo apt-get update
sudo apt-get install nginx
```

#### CentOS and Amazon Linux

```sh
sudo yum install nginx
```

#### Fedora

```sh
sudo dnf install nginx
```

### Installatie Valideren

Controleer of Nginx correct werd geïnstalleerd door het IP-adres van uw server te bezoeken in een browser

```
http://server_domain_name_or_IP
```

### Service

De dienst kan worden gestart of gestopt.

```sh
sudo service nginx stop
sudo service nginx start
sudo service nginx restart
```

## Vapor Opstarten

Nginx kan gestart en gestopt worden met de `sudo service nginx ...` commando's. U zult iets soortgelijks nodig hebben om uw Vapor server te starten en te stoppen.

Er zijn vele manieren om dit te doen, en ze zijn afhankelijk van het platform waarnaar u implementeert. Bekijk de [Supervisor](supervisor.md) instructies om commando's toe te voegen voor het starten en stoppen van uw Vapor app.

## Configureer Proxy

De instellingenbestanden voor geactiveerde sites staan in `/etc/nginx/sites-enabled/`.

Maak een nieuw bestand aan of kopieer het voorbeeld sjabloon uit `/etc/nginx/sites-available/` om te beginnen.

Hier is een voorbeeld configuratiebestand voor een Vapor project genaamd `Hello` in de home directory.

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

Dit configuratie bestand gaat er van uit dat het `Hello` project bindt aan poort `8080` als het in productie modus wordt opgestart.

### Bestanden Serveren

Nginx kan ook publieke bestanden serveren zonder uw Vapor app te vragen. Dit kan de prestaties verbeteren door het Vapor proces vrij te maken voor andere taken onder zware belasting.

```sh
server {
	...

	# Serveer alle publieke/statische bestanden via nginx en val dan terug op Vapor voor de rest
	location / {
		try_files $uri @proxy;
	}

	location @proxy {
		...
	}
}
```

### TLS

TLS toevoegen is relatief eenvoudig zolang de certificaten goed zijn gegenereerd. Om gratis TLS-certificaten te genereren, kijk op [Let's Encrypt](https://letsencrypt.org/getting-started/).

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

De configuratie hierboven zijn de relatief strikte instellingen voor TLS met Nginx. Sommige van de instellingen hier zijn niet vereist, maar verhogen de veiligheid.
