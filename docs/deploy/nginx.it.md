# Deploy con Nginx

Nginx è un server HTTP e proxy estremamente veloce, collaudato e facile da configurare. Mentre Vapor supporta la gestione diretta delle richieste HTTP con o senza TLS, fare il proxy dietro Nginx può fornire migliori prestazioni, sicurezza e facilità d'uso.

!!! note "Nota"
    Raccomandiamo di fare il proxy dei server HTTP Vapor dietro Nginx.

## Panoramica

Cosa significa fare il proxy di un server HTTP? In breve, un proxy funge da intermediario tra la rete pubblica e il tuo server HTTP. Le richieste arrivano al proxy che le inoltra a Vapor.

Una caratteristica importante di questo proxy intermediario è che può modificare o persino reindirizzare le richieste. Ad esempio, il proxy può richiedere che il client utilizzi TLS (https), limitare il numero di richieste (rate limiting), o persino servire file pubblici senza coinvolgere la tua applicazione Vapor.

![nginx-proxy](https://cloud.githubusercontent.com/assets/1342803/20184965/5d9d588a-a738-11e6-91fe-28c3a4f7e46b.png)

### Maggiori Dettagli

La porta predefinita per ricevere le richieste HTTP è la porta `80` (e `443` per HTTPS). Quando colleghi un server Vapor alla porta `80`, riceverà e risponderà direttamente alle richieste HTTP che arrivano al tuo server. Quando aggiungi un proxy come Nginx, colleghi Vapor a una porta interna, come la porta `8080`.

!!! note "Nota"
    Le porte superiori a 1024 non richiedono `sudo` per il binding.

Quando Vapor è collegato a una porta diversa da `80` o `443`, non sarà accessibile dall'esterno di internet. A quel punto colleghi Nginx alla porta `80` e lo configuri per instradare le richieste al tuo server Vapor collegato alla porta `8080` (o qualunque porta tu abbia scelto).

Ecco fatto. Se Nginx è configurato correttamente, vedrai la tua app Vapor rispondere alle richieste sulla porta `80`. Nginx fa il proxy delle richieste e delle risposte in modo trasparente.

## Installare Nginx

Il primo passo è installare Nginx. Uno dei grandi vantaggi di Nginx è la straordinaria quantità di risorse della community e documentazione che lo circondano. Per questo motivo, non entreremo nei dettagli sull'installazione di Nginx, poiché esiste quasi certamente un tutorial per la tua piattaforma, sistema operativo e provider specifici.

Tutorial:

- [How To Install Nginx on Ubuntu 20.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-20-04)
- [How To Install Nginx on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04)
- [How to Install Nginx on CentOS 8](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-centos-8)
- [How To Install Nginx on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-16-04)
- [How to Deploy Nginx on Heroku](https://blog.codeship.com/how-to-deploy-nginx-on-heroku/)

### Package Manager

Nginx può essere installato tramite i package manager su Linux.

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

### Verificare l'Installazione

Verifica che Nginx sia stato installato correttamente visitando l'indirizzo IP del tuo server nel browser

```
http://server_domain_name_or_IP
```

### Servizio

Il servizio può essere avviato o arrestato.

```sh
sudo service nginx stop
sudo service nginx start
sudo service nginx restart
```

## Avviare Vapor

Nginx può essere avviato e arrestato con i comandi `sudo service nginx ...`. Avrai bisogno di qualcosa di simile per avviare e arrestare il tuo server Vapor.

Ci sono molti modi per farlo, e dipendono dalla piattaforma su cui stai facendo il deploy. Consulta le istruzioni di [Supervisor](supervisor.it.md) per aggiungere i comandi per avviare e arrestare la tua app Vapor.

## Configurare il Proxy

I file di configurazione per i siti abilitati si trovano in `/etc/nginx/sites-enabled/`.

Crea un nuovo file o copia il template di esempio da `/etc/nginx/sites-available/` per iniziare.

Ecco un esempio di file di configurazione per un progetto Vapor chiamato `Hello` nella directory home.

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

Questo file di configurazione presuppone che il progetto `Hello` si colleghi alla porta `8080` quando avviato in modalità production.

### Servire File

Nginx può anche servire file pubblici senza coinvolgere la tua app Vapor. Questo può migliorare le prestazioni liberando il processo Vapor per altri compiti sotto carico elevato.

```sh
server {
	...

	# Serve tutti i file pubblici/statici tramite nginx e poi ricade su Vapor per il resto
	location / {
		try_files $uri @proxy;
	}

	location @proxy {
		...
	}
}
```

### TLS

Aggiungere TLS è relativamente semplice, purché i certificati siano stati generati correttamente. Per generare certificati TLS gratuitamente, consulta [Let's Encrypt](https://letsencrypt.org/getting-started/).

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

La configurazione sopra rappresenta impostazioni TLS relativamente restrittive per Nginx. Alcune delle impostazioni qui non sono obbligatorie, ma migliorano la sicurezza.
