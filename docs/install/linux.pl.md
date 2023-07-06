# Zainstaluj na Linux

Aby używać Vapor, będziesz potrzebować Swifta w wersji 5.6 lub wyższej. Możesz go zainstalować używając jednego z plików instalacyjnych na [Swift.org](https://swift.org/download/).

## Wspierane dystrybucje i wersje

Vapor wspiera te same wersje dystrybucji Linuxa jak wersja 5.6 lub nowsza Swifta.

!!! note
    Wspierane wersje wypisane poniżej mogą być przeterminowane w momencie gdy to czytasz. Możesz zobaczyć które systemy operacyjne czy dystrybucje są wpierane na stronie [Swift Releases](https://swift.org/download/#releases).

|Dystrybucja|Wersja|Wersja Swift|
|-|-|-|
|Ubuntu|20.04|>= 5.6|
|Fedora|>= 30|>= 5.6|
|CentOS|8|>= 5.6|
|Amazon Linux|2|>= 5.6|

Dystrybucje Linuxa które nie są oficjalnie wspierane mogą również użyć Swifta po przez kompilacje kodu źródłowego, lecz Vapor nie daje gwarancji stabilności. Dowiedz się więcej o kompilacji Swifta z oficjalnego repozytorium [Swift repo](https://github.com/apple/swift#getting-started).

## Instalacja Swifta

Wejdź na Swift.org i użyj instrukcji pod adresem [Using Downloads](https://swift.org/download/#using-downloads) aby zainstalować Swifta na Linux.

### Fedora

Użytkownicy Fedory mogę po prostu użyć następującej komendy aby zainstalować Swifta:

```sh
sudo dnf install swift-lang
```

Jeśli używasz Fedora 30, będziesz musiał dodać EPEL 8, aby używać Swifta 5.6 lub nowszego.

## Docker

Możesz również użyć oficjalnego obrazu Docker Swifta, który ma już preinstalowany kompilator. Dowiedz się więcej na [Swift's Docker Hub](https://hub.docker.com/_/swift).

## Zainstaluj Toolbox

Teraz gdy masz już zainstalowanego Swifta, zainstalujmy [Vapor Toolbox](https://github.com/vapor/toolbox). Jest to narzędzie CLI (z ang. Command Line Interface), które nie jest potrzebne by używać Vapora, natomiast jest wyposażone w przydatne usprawnienia takie jak kreator nowego projektu.

Na Linux, musisz zbudować toolbox z źródła. Odwiedź [wydania](https://github.com/vapor/toolbox/releases) toolboxu na Github aby znaleźć najnowsza wersję.

```sh
git clone https://github.com/vapor/toolbox.git
cd toolbox
git checkout <desired version>
make install
```

Sprawdź dwa razy czy instalacja przeszła poprawnie po przez wyświetlenie pomocy.

```sh
vapor --help
```

Powinna być widoczna lista dostępnych komend.

## Następnie

Kiedy już udało Ci się zainstalować Swifta, stwórz swoja pierwszą aplikacje w sekcji [Pierwsze kroki &rarr; Witaj, świecie](../getting-started/hello-world.md).
