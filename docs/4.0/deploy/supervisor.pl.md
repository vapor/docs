# Supervisor

[Supervisor](http://supervisord.org) to system kontroli procesów, który ułatwia uruchamianie, zatrzymywanie i restartowanie Twojej aplikacji Vapor.

## Instalacja

Supervisor można zainstalować za pomocą menedżerów pakietów na Linuxie.

### Ubuntu

```sh
sudo apt-get update
sudo apt-get install supervisor
```

### CentOS i Amazon Linux

```sh
sudo yum install supervisor
```

### Fedora

```sh
sudo dnf install supervisor
```

## Konfiguracja

Każda aplikacja Vapor na Twoim serwerze powinna mieć własny plik konfiguracyjny. Dla przykładowego projektu `Hello` plik konfiguracyjny znajdowałby się w `/etc/supervisor/conf.d/hello.conf`

```sh
[program:hello]
command=/home/vapor/hello/.build/release/App serve --env production
directory=/home/vapor/hello/
user=vapor
stdout_logfile=/var/log/supervisor/%(program_name)s-stdout.log
stderr_logfile=/var/log/supervisor/%(program_name)s-stderr.log
```

Jak określono w naszym pliku konfiguracyjnym, projekt `Hello` znajduje się w folderze domowym użytkownika `vapor`. Upewnij się, że `directory` wskazuje na katalog główny Twojego projektu, w którym znajduje się plik `Package.swift`.

Flaga `--env production` wyłączy szczegółowe logowanie.

### Zmienne środowiskowe

Za pomocą supervisora możesz eksportować zmienne do swojej aplikacji Vapor. Aby wyeksportować wiele wartości środowiskowych, umieść je wszystkie w jednej linii. Zgodnie z [dokumentacją Supervisora](http://supervisord.org/configuration.html#program-x-section-values):

> Wartości zawierające znaki niealfanumeryczne powinny być ujęte w cudzysłów (np. KEY="val:123",KEY2="val,456"). W innym przypadku cytowanie wartości jest opcjonalne, ale zalecane.

```sh
environment=PORT=8123,ANOTHERVALUE="/something/else"
```

Wyeksportowanych zmiennych można użyć w Vapor za pomocą `Environment.get`

```swift
let port = Environment.get("PORT")
```

## Uruchomienie

Teraz możesz wczytać i uruchomić swoją aplikację.

```sh
supervisorctl reread
supervisorctl add hello
supervisorctl start hello
```

!!! note
    Komenda `add` mogła już uruchomić Twoją aplikację.
