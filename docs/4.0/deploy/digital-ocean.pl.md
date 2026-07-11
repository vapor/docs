# Wdrażanie na DigitalOcean

Ten przewodnik przeprowadzi Cię przez proces wdrożenia prostej aplikacji Vapor typu Hello, world na [Droplet](https://www.digitalocean.com/products/droplets/). Aby skorzystać z tego przewodnika, musisz posiadać konto [DigitalOcean](https://www.digitalocean.com) ze skonfigurowanym rozliczeniem.

## Utwórz serwer

Zacznijmy od zainstalowania Swifta na serwerze z Linuxem. Użyj menu tworzenia, aby utworzyć nowego Droplet.

![Create Droplet](../images/digital-ocean-create-droplet.png)

W sekcji dystrybucji wybierz Ubuntu 22.04 LTS. W tym przewodniku ta wersja będzie używana jako przykład.

![Ubuntu Distro](../images/digital-ocean-distributions-ubuntu.png)

!!! note 
    Możesz wybrać dowolną dystrybucję Linuxa w wersji wspieranej przez Swift. Możesz sprawdzić, które systemy operacyjne są oficjalnie wspierane, na stronie [Swift Releases](https://swift.org/download/#releases).

Po wybraniu dystrybucji wybierz dowolny plan i region centrum danych, jaki preferujesz. Następnie skonfiguruj klucz SSH, aby móc uzyskać dostęp do serwera po jego utworzeniu. Na koniec kliknij create Droplet i poczekaj, aż nowy serwer zostanie uruchomiony.

Gdy nowy serwer będzie już gotowy, najedź kursorem na adres IP Droplet i kliknij kopiuj.

![Droplet List](../images/digital-ocean-droplet-list.png)

## Wstępna konfiguracja

Otwórz terminal i połącz się z serwerem jako root za pomocą SSH.

```sh
ssh root@your_server_ip
```

DigitalOcean posiada szczegółowy przewodnik dotyczący [wstępnej konfiguracji serwera na Ubuntu 22.04](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-22-04). Ten przewodnik krótko omówi podstawy.

### Konfiguracja zapory sieciowej

Zezwól na OpenSSH w zaporze sieciowej i włącz ją.

```sh
ufw allow OpenSSH
ufw enable
```

### Dodaj użytkownika

Utwórz nowego użytkownika oprócz `root`. W tym przewodniku nowy użytkownik nazywa się `vapor`.

```sh
adduser vapor
```

Zezwól nowo utworzonemu użytkownikowi na korzystanie z `sudo`.

```sh
usermod -aG sudo vapor
```

Skopiuj autoryzowane klucze SSH użytkownika root do nowo utworzonego użytkownika. Dzięki temu będziesz mógł zalogować się przez SSH jako nowy użytkownik.

```sh
rsync --archive --chown=vapor:vapor ~/.ssh /home/vapor
```

Na koniec zakończ bieżącą sesję SSH i zaloguj się jako nowo utworzony użytkownik.

```sh
exit
ssh vapor@your_server_ip
```

## Zainstaluj Swift

Teraz, gdy utworzyłeś nowy serwer Ubuntu i zalogowałeś się jako użytkownik niebędący rootem, możesz zainstalować Swift.

### Automatyczna instalacja za pomocą narzędzia CLI Swiftly (zalecane)

Odwiedź [stronę Swiftly](https://swiftlang.github.io/swiftly/), aby zapoznać się z instrukcjami instalacji Swiftly i Swifta na Linuxie. Następnie zainstaluj Swift za pomocą poniższej komendy:

#### Podstawowe użycie

```sh
$ swiftly install latest

Fetching the latest stable Swift release...
Installing Swift 5.9.1
Downloaded 488.5 MiB of 488.5 MiB
Extracting toolchain...
Swift 5.9.1 installed successfully!

$ swift --version

Swift version 5.9.1 (swift-5.9.1-RELEASE)
Target: x86_64-unknown-linux-gnu
```

## Zainstaluj Vapor za pomocą Vapor Toolbox

Teraz, gdy Swift jest już zainstalowany, zainstalujmy Vapor za pomocą Vapor Toolbox. Będziesz musiał zbudować toolbox ze źródła. Sprawdź [wydania](https://github.com/vapor/toolbox/releases) toolboxu na GitHubie, aby znaleźć najnowszą wersję. W tym przykładzie używamy wersji 18.6.0.

### Sklonuj i zbuduj Vapor

Sklonuj repozytorium Vapor Toolbox.

```sh
git clone https://github.com/vapor/toolbox.git
```

Przełącz się na najnowsze wydanie.

```sh
cd toolbox
git checkout 18.6.0
```

Zbuduj Vapor i przenieś plik binarny do swojej ścieżki.

```sh
swift build -c release --disable-sandbox --enable-test-discovery
sudo mv .build/release/vapor /usr/local/bin
```

### Utwórz projekt Vapor

Użyj komendy new z Toolboxu, aby zainicjować projekt.

```sh
vapor new HelloWorld -n
```

!!! tip
    Flaga `-n` daje Ci szablon w wersji podstawowej, automatycznie odpowiadając nie na wszystkie pytania.

![Vapor Splash](../images/vapor-splash.png)

Po zakończeniu działania komendy przejdź do nowo utworzonego folderu:

```sh
cd HelloWorld
``` 

### Otwórz port HTTP

Aby uzyskać dostęp do Vapor na swoim serwerze, otwórz port HTTP.

```sh
sudo ufw allow 8080
```

### Uruchom

Teraz, gdy Vapor jest skonfigurowany i mamy otwarty port, uruchommy go.

```sh
swift run App serve --hostname 0.0.0.0 --port 8080
```

Odwiedź adres IP swojego serwera przez przeglądarkę lub lokalny terminal, a powinieneś zobaczyć "It works!". W tym przykładzie adres IP to `134.122.126.139`.

```
$ curl http://134.122.126.139:8080
It works!
```

Z powrotem na serwerze powinieneś zobaczyć logi dotyczące testowego żądania.

```
[ NOTICE ] Server starting on http://0.0.0.0:8080
[ INFO ] GET /
```

Użyj `CTRL+C`, aby zamknąć serwer. Zamknięcie może potrwać chwilę.

Gratulacje, udało Ci się uruchomić aplikację Vapor na Droplet DigitalOcean!

## Kolejne kroki

Reszta tego przewodnika wskazuje dodatkowe zasoby, które pozwolą ulepszyć Twoje wdrożenie.

### Supervisor

Supervisor to system kontroli procesów, który może uruchamiać i monitorować Twój plik wykonywalny Vapor. Dzięki konfiguracji supervisora Twoja aplikacja może automatycznie uruchamiać się przy starcie serwera i być restartowana w przypadku awarii. Dowiedz się więcej o [Supervisorze](../deploy/supervisor.md).

### Nginx

Nginx to niezwykle szybki, sprawdzony w boju i łatwy w konfiguracji serwer HTTP oraz proxy. Chociaż Vapor obsługuje bezpośrednią obsługę żądań HTTP, umieszczenie proxy za Nginx może zapewnić zwiększoną wydajność, bezpieczeństwo i łatwość użycia. Dowiedz się więcej o [Nginx](../deploy/nginx.md).
