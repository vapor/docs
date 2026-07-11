# Systemd

Systemd to domyślny menedżer systemu i usług w większości dystrybucji Linuksa. Zazwyczaj jest zainstalowany domyślnie, więc nie jest wymagana żadna instalacja we wspieranych dystrybucjach Swift.

## Konfiguracja

Każda aplikacja Vapor na Twoim serwerze powinna mieć swój własny plik usługi. Dla przykładowego projektu `Hello`, plik konfiguracyjny znajdowałby się w `/etc/systemd/system/hello.service`. Ten plik powinien wyglądać następująco:

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

Zgodnie z tym, co określono w naszym pliku konfiguracyjnym, projekt `Hello` znajduje się w folderze domowym użytkownika `vapor`. Upewnij się, że `WorkingDirectory` wskazuje na katalog główny Twojego projektu, w którym znajduje się plik `Package.swift`.

Flaga `--env production` wyłączy szczegółowe logowanie.

### Zmienne środowiskowe
Poza tym cytowanie wartości jest opcjonalne, ale zalecane.

Możesz eksportować zmienne za pomocą systemd na dwa sposoby. Albo tworząc plik środowiskowy z wszystkimi ustawionymi w nim zmiennymi:

```sh
EnvironmentFile=/path/to/environment/file1
EnvironmentFile=/path/to/environment/file2
```


Albo możesz dodać je bezpośrednio do pliku usługi w sekcji `[service]`:

```sh
Environment="PORT=8123"
Environment="ANOTHERVALUE=/something/else"
```
Wyeksportowanych zmiennych można używać w Vapor za pomocą `Environment.get`

```swift
let port = Environment.get("PORT")
```

## Uruchamianie

Możesz teraz wczytać, włączyć, uruchomić, zatrzymać i zrestartować swoją aplikację, uruchamiając poniższe polecenia jako root.

```sh
systemctl daemon-reload
systemctl enable hello
systemctl start hello
systemctl stop hello
systemctl restart hello
```
