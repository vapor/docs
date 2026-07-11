# Nginx로 배포하기

Nginx는 매우 빠르고, 검증되었으며, 설정하기 쉬운 HTTP 서버이자 프록시입니다. Vapor는 TLS 사용 여부와 관계없이 HTTP 요청을 직접 처리하는 것을 지원하지만, Nginx 뒤에서 프록시를 사용하면 성능, 보안, 그리고 사용 편의성을 향상시킬 수 있습니다.

!!! note
    Vapor HTTP 서버는 Nginx 뒤에서 프록시로 사용하는 것을 권장합니다.

## 개요

HTTP 서버를 프록시한다는 것은 무엇을 의미할까요? 간단히 말해, 프록시는 공용 인터넷과 HTTP 서버 사이에서 중개자 역할을 합니다. 요청은 프록시로 들어오고, 프록시는 이를 Vapor로 전달합니다.

이 중개자 프록시의 중요한 특징은 요청을 변경하거나 리다이렉트할 수 있다는 점입니다. 예를 들어, 프록시는 클라이언트가 TLS(https)를 사용하도록 요구하거나, 요청 속도를 제한하거나, Vapor 애플리케이션과 통신하지 않고도 공개 파일을 직접 제공할 수 있습니다.

![nginx-proxy](https://cloud.githubusercontent.com/assets/1342803/20184965/5d9d588a-a738-11e6-91fe-28c3a4f7e46b.png)

### 좀 더 자세히

HTTP 요청을 수신하는 기본 포트는 `80`번(HTTPS의 경우 `443`번)입니다. Vapor 서버를 `80`번 포트에 바인딩하면, 서버로 들어오는 HTTP 요청을 직접 수신하고 응답합니다. Nginx와 같은 프록시를 추가할 때는 Vapor를 `8080`번과 같은 내부 포트에 바인딩합니다.

!!! note
    1024보다 큰 포트는 바인딩할 때 `sudo`가 필요하지 않습니다.

Vapor가 `80`이나 `443`이 아닌 다른 포트에 바인딩되면, 외부 인터넷에서는 접근할 수 없습니다. 그런 다음 Nginx를 `80`번 포트에 바인딩하고, `8080`번(또는 선택한 다른 포트)에 바인딩된 Vapor 서버로 요청을 라우팅하도록 설정합니다.

이렇게 하면 끝입니다. Nginx가 올바르게 설정되었다면, `80`번 포트로 들어오는 요청에 Vapor 앱이 응답하는 것을 볼 수 있습니다. Nginx는 요청과 응답을 보이지 않게 프록시합니다.

## Nginx 설치

첫 번째 단계는 Nginx를 설치하는 것입니다. Nginx의 훌륭한 점 중 하나는 이를 둘러싼 방대한 양의 커뮤니티 자료와 문서입니다. 이 때문에 여기서는 Nginx 설치에 대해 자세히 다루지 않습니다. 사용 중인 플랫폼, OS, 제공업체에 맞는 튜토리얼이 거의 반드시 존재하기 때문입니다.

튜토리얼:

- [How To Install Nginx on Ubuntu 20.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-20-04)
- [How To Install Nginx on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04)
- [How to Install Nginx on CentOS 8](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-centos-8)
- [How To Install Nginx on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-16-04)
- [How to Deploy Nginx on Heroku](https://blog.codeship.com/how-to-deploy-nginx-on-heroku/)

### 패키지 매니저

Nginx는 Linux의 패키지 매니저를 통해 설치할 수 있습니다.

#### Ubuntu

```sh
sudo apt-get update
sudo apt-get install nginx
```

#### CentOS와 Amazon Linux

```sh
sudo yum install nginx
```

#### Fedora

```sh
sudo dnf install nginx
```

### 설치 확인

브라우저에서 서버의 IP 주소로 접속하여 Nginx가 올바르게 설치되었는지 확인하세요.

```
http://server_domain_name_or_IP
```

### 서비스

서비스는 시작하거나 중지할 수 있습니다.

```sh
sudo service nginx stop
sudo service nginx start
sudo service nginx restart
```

## Vapor 부팅하기

Nginx는 `sudo service nginx ...` 명령어로 시작하고 중지할 수 있습니다. Vapor 서버를 시작하고 중지하려면 이와 비슷한 것이 필요합니다.

이를 수행하는 방법은 여러 가지이며, 배포하려는 플랫폼에 따라 달라집니다. Vapor 앱을 시작하고 중지하는 명령어를 추가하려면 [Supervisor](supervisor.md) 안내를 확인하세요.

## 프록시 설정

활성화된 사이트의 설정 파일은 `/etc/nginx/sites-enabled/`에서 찾을 수 있습니다.

시작하려면 새 파일을 만들거나 `/etc/nginx/sites-available/`에서 예제 템플릿을 복사하세요.

다음은 홈 디렉토리에 있는 `Hello`라는 Vapor 프로젝트에 대한 예제 설정 파일입니다.

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

이 설정 파일은 `Hello` 프로젝트가 프로덕션 모드로 시작될 때 `8080`번 포트에 바인딩된다고 가정합니다.

### 파일 제공하기

Nginx는 Vapor 앱에 요청하지 않고도 공개 파일을 제공할 수 있습니다. 이는 부하가 높은 상황에서 Vapor 프로세스가 다른 작업을 처리할 수 있도록 여유를 줌으로써 성능을 향상시킬 수 있습니다.

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

인증서가 올바르게 생성되어 있다면 TLS를 추가하는 것은 비교적 간단합니다. 무료로 TLS 인증서를 생성하려면 [Let's Encrypt](https://letsencrypt.org/getting-started/)를 확인하세요.

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

위 설정은 Nginx에서 TLS를 위한 비교적 엄격한 설정입니다. 여기 있는 설정 중 일부는 필수는 아니지만 보안을 강화합니다.
