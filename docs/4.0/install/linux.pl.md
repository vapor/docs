# Zainstaluj na Linux

Aby używać Vapor, będziesz potrzebować Swifta w wersji 5.9 lub wyższej. Możesz go zainstalować za pomocą narzędzia CLI [Swiftly](https://swiftlang.github.io/swiftly/) dostarczanego przez Swift Server Workgroup (zalecane), lub za pomocą toolchainów dostępnych na [Swift.org](https://swift.org/download/).

## Wspierane dystrybucje i wersje

Vapor wspiera te same wersje dystrybucji Linuxa, które są wspierane przez Swift 5.9 lub nowsze wersje. Zajrzyj na [oficjalną stronę wsparcia](https://www.swift.org/platform-support/), aby znaleźć aktualne informacje o tym, które systemy operacyjne są oficjalnie wspierane.

Dystrybucje Linuxa, które nie są oficjalnie wspierane, mogą również uruchomić Swifta poprzez kompilację kodu źródłowego, lecz Vapor nie daje gwarancji stabilności. Dowiedz się więcej o kompilacji Swifta z oficjalnego repozytorium [Swift repo](https://github.com/apple/swift#getting-started).

## Instalacja Swifta

### Automatyczna instalacja za pomocą narzędzia CLI Swiftly (zalecane)

Odwiedź [stronę Swiftly](https://swiftlang.github.io/swiftly/), aby zapoznać się z instrukcjami instalacji Swiftly i Swifta na Linuxie. Następnie zainstaluj Swifta za pomocą poniższej komendy:

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

### Instalacja ręczna za pomocą toolchainu

Odwiedź przewodnik [Using Downloads](https://swift.org/download/#using-downloads) na Swift.org, aby zapoznać się z instrukcjami instalacji Swifta na Linuxie.

### Fedora

Użytkownicy Fedory mogą po prostu użyć następującej komendy, aby zainstalować Swifta:

```sh
sudo dnf install swift-lang
```

Jeśli używasz Fedory 35, będziesz musiał dodać EPEL 8, aby uzyskać Swifta 5.9 lub nowszych wersji.

## Docker

Możesz również użyć oficjalnych obrazów Docker Swifta, które mają już preinstalowany kompilator. Dowiedz się więcej na [Swift's Docker Hub](https://hub.docker.com/_/swift).

## Zainstaluj Toolbox

Teraz gdy masz już zainstalowanego Swifta, zainstalujmy [Vapor Toolbox](https://github.com/vapor/toolbox). Jest to narzędzie CLI, które nie jest wymagane, by używać Vapora, ale pomaga w tworzeniu nowych projektów Vapor.

### Homebrew

Toolbox jest dystrybuowany za pomocą Homebrew. Jeśli jeszcze nie masz Homebrew, odwiedź <a href="https://brew.sh" target="_blank">brew.sh</a> po instrukcje instalacji.

```sh
brew install vapor
```

Sprawdź dwa razy, czy instalacja przebiegła pomyślnie, wyświetlając pomoc.

```sh
vapor --help
```

Powinna wyświetlić się lista dostępnych komend.

### Makefile

Jeśli chcesz, możesz również zbudować Toolbox ze źródła. Odwiedź <a href="https://github.com/vapor/toolbox/releases" target="_blank">wydania</a> Toolboxu na GitHubie, aby znaleźć najnowszą wersję.

```sh
git clone https://github.com/vapor/toolbox.git
cd toolbox
git checkout <desired version>
make install
```

Sprawdź dwa razy, czy instalacja przebiegła pomyślnie, wyświetlając pomoc.

```sh
vapor --help
```

Powinna wyświetlić się lista dostępnych komend.

## Następnie

Teraz gdy zainstalowałeś Swifta i Vapor Toolbox, stwórz swoją pierwszą aplikację w [Pierwsze kroki &rarr; Witaj, świecie](../getting-started/hello-world.md).
