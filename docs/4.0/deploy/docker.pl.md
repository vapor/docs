# Wdrożenia z Dockerem

Użycie Dockera do wdrożenia twojej aplikacji Vapor ma kilka zalet:

1. Twoja zdockeryzowana aplikacja może być niezawodnie uruchamiana za pomocą tych samych poleceń na dowolnej platformie z Docker Daemon -- czyli na Linuksie (CentOS, Debian, Fedora, Ubuntu), macOS i Windows.
2. Możesz użyć docker-compose lub manifestów Kubernetes do orkiestracji wielu usług potrzebnych do pełnego wdrożenia (np. Redis, Postgres, nginx itd.).
3. Łatwo jest przetestować zdolność twojej aplikacji do skalowania horyzontalnego, nawet lokalnie na twojej maszynie deweloperskiej.

Ten przewodnik nie wyjaśni, jak umieścić twoją zdockeryzowaną aplikację na serwerze. Najprostsze wdrożenie polegałoby na zainstalowaniu Dockera na twoim serwerze i uruchomieniu tych samych poleceń, które uruchomiłbyś na swojej maszynie deweloperskiej, aby uruchomić twoją aplikację.

Bardziej skomplikowane i solidne wdrożenia zwykle różnią się w zależności od twojego rozwiązania hostingowego; wiele popularnych rozwiązań, takich jak AWS, ma wbudowane wsparcie dla Kubernetes i niestandardowych rozwiązań bazodanowych, co utrudnia opisanie najlepszych praktyk w sposób mający zastosowanie do wszystkich wdrożeń.

Niemniej jednak, użycie Dockera do lokalnego uruchomienia całego stosu serwera w celach testowych jest niezwykle wartościowe zarówno dla dużych, jak i małych aplikacji serwerowych. Dodatkowo, koncepcje opisane w tym przewodniku mają zastosowanie w ogólnym zarysie do wszystkich wdrożeń Dockera.

## Konfiguracja

Musisz skonfigurować swoje środowisko deweloperskie do uruchamiania Dockera i zdobyć podstawowe zrozumienie plików zasobów, które konfigurują stosy Dockera.

### Zainstaluj Dockera

Musisz zainstalować Dockera dla swojego środowiska deweloperskiego. Informacje dla dowolnej platformy znajdziesz w sekcji [Supported Platforms](https://docs.docker.com/install/#supported-platforms) w Docker Engine Overview. Jeśli używasz Mac OS, możesz przejść od razu do strony instalacji [Docker for Mac](https://docs.docker.com/docker-for-mac/install/).

### Wygeneruj szablon

Sugerujemy użycie szablonu Vapor jako punktu wyjścia. Jeśli masz już aplikację, zbuduj szablon w sposób opisany poniżej w nowym folderze jako punkt odniesienia podczas dockeryzacji istniejącej aplikacji -- możesz skopiować kluczowe zasoby z szablonu do swojej aplikacji i nieco je dostosować jako punkt startowy.

1. Zainstaluj lub zbuduj Vapor Toolbox ([macOS](../install/macos.md#zainstaluj-toolbox), [Linux](../install/linux.md#zainstaluj-toolbox)).
2. Utwórz nową aplikację Vapor za pomocą `vapor new my-dockerized-app` i przejdź przez pytania, aby włączyć lub wyłączyć odpowiednie funkcje. Twoje odpowiedzi na te pytania wpłyną na sposób generowania plików zasobów Dockera.

## Zasoby Dockera

Warto, czy to teraz, czy w niedalekiej przyszłości, zapoznać się z [Docker Overview](https://docs.docker.com/engine/docker-overview/). Ten przegląd wyjaśni pewne kluczowe terminy, których używa ten przewodnik.

Szablon aplikacji Vapor ma dwa kluczowe zasoby specyficzne dla Dockera: **Dockerfile** i plik **docker-compose**.

### Dockerfile

Dockerfile mówi Dockerowi, jak zbudować obraz twojej zdockeryzowanej aplikacji. Ten obraz zawiera zarówno plik wykonywalny twojej aplikacji, jak i wszystkie zależności potrzebne do jego uruchomienia. Warto trzymać otwartą [pełną dokumentację referencyjną](https://docs.docker.com/engine/reference/builder/), gdy pracujesz nad dostosowaniem swojego Dockerfile.

Dockerfile wygenerowany dla twojej aplikacji Vapor ma dwa etapy. Pierwszy etap buduje twoją aplikację i tworzy obszar tymczasowy zawierający wynik. Drugi etap konfiguruje podstawy bezpiecznego środowiska uruchomieniowego, przenosi wszystko z obszaru tymczasowego do miejsca, w którym będzie znajdować się w ostatecznym obrazie, oraz ustawia domyślny entrypoint i polecenie, które uruchomi twoją aplikację w trybie produkcyjnym na domyślnym porcie (8080). Ta konfiguracja może zostać nadpisana, gdy obraz zostanie użyty.

### Plik Docker Compose

Plik Docker Compose definiuje sposób, w jaki Docker powinien budować wiele usług w relacji do siebie nawzajem. Plik Docker Compose w szablonie aplikacji Vapor zapewnia funkcjonalność niezbędną do wdrożenia twojej aplikacji, ale jeśli chcesz dowiedzieć się więcej, powinieneś sięgnąć do [pełnej dokumentacji referencyjnej](https://docs.docker.com/compose/compose-file/), która zawiera szczegóły dotyczące wszystkich dostępnych opcji.

!!! note
    Jeśli ostatecznie planujesz użyć Kubernetes do orkiestracji swojej aplikacji, plik Docker Compose nie ma bezpośredniego zastosowania. Jednak pliki manifestów Kubernetes są koncepcyjnie podobne i istnieją nawet projekty mające na celu [przenoszenie plików Docker Compose](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/) na manifesty Kubernetes.

Plik Docker Compose w twojej nowej aplikacji Vapor zdefiniuje usługi do uruchamiania twojej aplikacji, uruchamiania migracji lub ich cofania oraz uruchamiania bazy danych jako warstwy trwałości twojej aplikacji. Dokładne definicje będą się różnić w zależności od tego, jaką bazę danych wybrałeś podczas uruchamiania `vapor new`.

Zauważ, że twój plik Docker Compose ma na górze kilka współdzielonych zmiennych środowiskowych. (Możesz mieć inny zestaw domyślnych zmiennych w zależności od tego, czy używasz Fluenta, i którego sterownika Fluent używasz, jeśli tak).

```docker
x-shared_environment: &shared_environment
  LOG_LEVEL: ${LOG_LEVEL:-debug}
  DATABASE_HOST: db
  DATABASE_NAME: vapor_database
  DATABASE_USERNAME: vapor_username
  DATABASE_PASSWORD: vapor_password
```

Zobaczysz, że są one wciągane do wielu usług poniżej za pomocą składni referencji YAML `<<: *shared_environment`.

Zmienne `DATABASE_HOST`, `DATABASE_NAME`, `DATABASE_USERNAME` i `DATABASE_PASSWORD` są w tym przykładzie zakodowane na stałe, podczas gdy `LOG_LEVEL` przyjmie swoją wartość ze środowiska uruchamiającego usługę lub domyślnie przyjmie `'debug'`, jeśli ta zmienna nie jest ustawiona.

!!! note
    Zakodowanie na stałe nazwy użytkownika i hasła jest akceptowalne dla lokalnego developmentu, ale powinieneś przechowywać te zmienne w pliku sekretów dla wdrożenia produkcyjnego. Jednym ze sposobów obsłużenia tego w produkcji jest wyeksportowanie pliku sekretów do środowiska uruchamiającego twoje wdrożenie i użycie linii takich jak poniższa w twoim pliku Docker Compose:

    ```
    DATABASE_USERNAME: ${DATABASE_USERNAME}
    ```

    To przekazuje zmienną środowiskową do kontenerów zgodnie z definicją hosta.

Inne rzeczy, na które warto zwrócić uwagę:

- Zależności między usługami są definiowane przez tablice `depends_on`.
- Porty usług są udostępniane systemowi uruchamiającemu te usługi za pomocą tablic `ports` (w formacie `<host_port>:<service_port>`).
- `DATABASE_HOST` jest zdefiniowany jako `db`. Oznacza to, że twoja aplikacja będzie uzyskiwać dostęp do bazy danych pod adresem `http://db:5432`. Działa to dlatego, że Docker uruchomi sieć używaną przez twoje usługi, a wewnętrzny DNS w tej sieci będzie kierować nazwę `db` do usługi o nazwie `'db'`.
- Dyrektywa `CMD` w Dockerfile jest nadpisywana w niektórych usługach za pomocą tablicy `command`. Zauważ, że to, co jest określone przez `command`, jest uruchamiane względem `ENTRYPOINT` w Dockerfile.
- W trybie Swarm Mode (więcej o tym poniżej) usługi domyślnie otrzymują 1 instancję, ale usługi `migrate` i `revert` mają zdefiniowane `deploy` `replicas: 0`, więc nie uruchamiają się domyślnie podczas uruchamiania Swarma.

## Budowanie

Plik Docker Compose mówi Dockerowi, jak zbudować twoją aplikację (używając Dockerfile w bieżącym katalogu) i jak nazwać wynikowy obraz (`my-dockerized-app:latest`). To drugie jest w rzeczywistości kombinacją nazwy (`my-dockerized-app`) i tagu (`latest`), gdzie tagi są używane do wersjonowania obrazów Dockera.

Aby zbudować obraz Dockera dla swojej aplikacji, uruchom

```shell
docker compose build
```

z katalogu głównego projektu twojej aplikacji (folderu zawierającego `docker-compose.yml`).

Zobaczysz, że twoja aplikacja i jej zależności muszą zostać zbudowane ponownie, nawet jeśli wcześniej zbudowałeś je na swojej maszynie deweloperskiej. Są one budowane w środowisku budowania Linux, którego używa Docker, więc artefakty budowania z twojej maszyny deweloperskiej nie są ponownie użyteczne.

Gdy to się skończy, znajdziesz obraz swojej aplikacji, uruchamiając

```shell
docker image ls
```

## Uruchamianie

Twój stos usług może być uruchamiany bezpośrednio z pliku Docker Compose lub możesz użyć warstwy orkiestracji takiej jak Swarm Mode lub Kubernetes.

### Samodzielnie

Najprostszym sposobem na uruchomienie twojej aplikacji jest uruchomienie jej jako samodzielnego kontenera. Docker użyje tablic `depends_on`, aby upewnić się, że wszelkie zależne usługi są również uruchamiane.

Najpierw wykonaj:

```shell
docker compose up app
```

i zauważ, że uruchamiane są zarówno usługa `app`, jak i `db`.

Twoja aplikacja nasłuchuje na porcie 8080 i, zgodnie z definicją w pliku Docker Compose, jest dostępna na twojej maszynie deweloperskiej pod adresem **http://localhost:8080**.

To rozróżnienie mapowania portów jest bardzo ważne, ponieważ możesz uruchomić dowolną liczbę usług na tych samych portach, jeśli wszystkie działają we własnych kontenerach i każda z nich udostępnia inne porty maszynie hosta.

Odwiedź `http://localhost:8080`, a zobaczysz `It works!`, ale odwiedź `http://localhost:8080/todos` i otrzymasz:

```
{"error":true,"reason":"Something went wrong."}
```

Rzuć okiem na logi wyświetlane w terminalu, w którym uruchomiłeś `docker compose up app`, a zobaczysz:

```
[ ERROR ] relation "todos" does not exist
```

Oczywiście! Musimy uruchomić migracje na bazie danych. Naciśnij `Ctrl+C`, aby zatrzymać swoją aplikację. Uruchomimy aplikację ponownie, ale tym razem z:

```shell
docker compose up --detach app
```

Teraz twoja aplikacja uruchomi się "odłączona" (w tle). Możesz to zweryfikować, uruchamiając:

```shell
docker container ls
```

gdzie zobaczysz zarówno bazę danych, jak i twoją aplikację działające w kontenerach. Możesz nawet sprawdzić logi, uruchamiając:

```shell
docker logs <container_id>
```

Aby uruchomić migracje, wykonaj:

```shell
docker compose run migrate
```

Po uruchomieniu migracji możesz ponownie odwiedzić `http://localhost:8080/todos` i zamiast komunikatu o błędzie otrzymasz pustą listę zadań (todos).

#### Poziomy logowania

Przypomnij sobie powyżej, że zmienna środowiskowa `LOG_LEVEL` w pliku Docker Compose będzie dziedziczona ze środowiska, w którym uruchamiana jest usługa, jeśli jest dostępna.

Możesz uruchomić swoje usługi za pomocą

```shell
LOG_LEVEL=trace docker-compose up app
```

aby uzyskać logowanie na poziomie `trace` (najbardziej szczegółowe). Możesz użyć tej zmiennej środowiskowej, aby ustawić logowanie na [dowolny dostępny poziom](../basics/logging.md#level).

#### Logi wszystkich usług

Jeśli jawnie określisz swoją usługę bazy danych podczas uruchamiania kontenerów, zobaczysz logi zarówno swojej bazy danych, jak i aplikacji.

```shell
docker-compose up app db
```

#### Zatrzymywanie samodzielnych kontenerów

Teraz, gdy masz kontenery działające "odłączone" od powłoki twojego hosta, musisz jakoś powiedzieć im, aby się zamknęły. Warto wiedzieć, że każdy działający kontener można poprosić o zamknięcie za pomocą

```shell
docker container stop <container_id>
```

ale najłatwiejszym sposobem na zatrzymanie tych konkretnych kontenerów jest

```shell
docker-compose down
```

#### Czyszczenie bazy danych

Plik Docker Compose definiuje wolumin `db_data`, aby zachować twoją bazę danych między uruchomieniami. Istnieje kilka sposobów na zresetowanie bazy danych.

Możesz usunąć wolumin `db_data` w tym samym momencie, w którym zatrzymujesz swoje kontenery, za pomocą

```shell
docker-compose down --volumes
```

Możesz zobaczyć wszystkie woluminy aktualnie przechowujące dane za pomocą `docker volume ls`. Zauważ, że nazwa woluminu zazwyczaj będzie miała prefiks `my-dockerized-app_` lub `test_`, w zależności od tego, czy działałeś w trybie Swarm Mode, czy nie.

Możesz usuwać te woluminy pojedynczo, np. za pomocą

```shell
docker volume rm my-dockerized-app_db_data
```

Możesz również wyczyścić wszystkie woluminy za pomocą

```shell
docker volume prune
```

Uważaj tylko, żeby przypadkiem nie wyczyścić woluminu z danymi, które chciałeś zachować!

Docker nie pozwoli ci usunąć woluminów, które są aktualnie w użyciu przez działające lub zatrzymane kontenery. Możesz uzyskać listę działających kontenerów za pomocą `docker container ls`, a zatrzymane kontenery możesz zobaczyć za pomocą `docker container ls -a`.

### Swarm Mode

Swarm Mode to prosty interfejs do użycia, gdy masz pod ręką plik Docker Compose i chcesz przetestować, jak twoja aplikacja skaluje się horyzontalnie. Możesz przeczytać wszystko o Swarm Mode na stronach zaczynających się od [przeglądu](https://docs.docker.com/engine/swarm/).

Pierwszą rzeczą, jakiej potrzebujemy, jest węzeł menedżera dla naszego Swarma. Uruchom

```shell
docker swarm init
```

Następnie użyjemy naszego pliku Docker Compose, aby uruchomić stos o nazwie `'test'` zawierający nasze usługi

```shell
docker stack deploy -c docker-compose.yml test
```

Możemy sprawdzić, jak radzą sobie nasze usługi, za pomocą

```shell
docker service ls
```

Powinieneś zobaczyć `1/1` replik dla usług `app` i `db` oraz `0/0` replik dla usług `migrate` i `revert`.

Musimy użyć innego polecenia, aby uruchomić migracje w trybie Swarm.

```shell
docker service scale --detach test_migrate=1
```

!!! note
    Właśnie poprosiliśmy krótkotrwałą usługę o skalowanie do 1 repliki. Pomyślnie się przeskaluje, uruchomi, a następnie zakończy działanie. Jednak to pozostawi ją z `0/1` działających replik. Nie jest to żaden problem, dopóki nie będziemy chcieli ponownie uruchomić migracji, ale nie możemy jej powiedzieć, żeby "przeskalowała się do 1 repliki", jeśli już tam się znajduje. Osobliwością tej konfiguracji jest to, że następnym razem, gdy będziemy chcieli uruchomić migracje w ramach tego samego środowiska uruchomieniowego Swarma, musimy najpierw przeskalować usługę do `0`, a potem z powrotem do `1`.

Korzyścią z naszych trudów w kontekście tego krótkiego przewodnika jest to, że teraz możemy skalować naszą aplikację do dowolnej wartości, aby przetestować, jak dobrze radzi sobie z rywalizacją o bazę danych, awariami i nie tylko.

Jeśli chcesz uruchomić równocześnie 5 instancji swojej aplikacji, wykonaj

```shell
docker service scale test_app=5
```

Oprócz obserwowania, jak Docker skaluje twoją aplikację, możesz zobaczyć, że rzeczywiście działa 5 replik, ponownie sprawdzając `docker service ls`.

Możesz wyświetlić (i śledzić) logi swojej aplikacji za pomocą

```shell
docker service logs -f test_app
```

#### Zatrzymywanie usług Swarm

Gdy chcesz zatrzymać swoje usługi w trybie Swarm Mode, robisz to, usuwając stos utworzony wcześniej.

```shell
docker stack rm test
```

## Wdrożenia produkcyjne

Jak wspomniano na początku, ten przewodnik nie wejdzie w szczegóły dotyczące wdrażania twojej zdockeryzowanej aplikacji na produkcję, ponieważ temat jest obszerny i różni się znacznie w zależności od usługi hostingowej (AWS, Azure itd.), narzędzi (Terraform, Ansible itd.) i orkiestracji (Docker Swarm, Kubernetes itd.).

Jednak techniki, których nauczyłeś się, aby uruchamiać swoją zdockeryzowaną aplikację lokalnie na swojej maszynie deweloperskiej, są w dużej mierze przenośne na środowiska produkcyjne. Instancja serwera skonfigurowana do uruchamiania daemona Dockera zaakceptuje wszystkie te same polecenia.

Skopiuj pliki swojego projektu na swój serwer, połącz się z serwerem przez SSH i uruchom polecenie `docker-compose` lub `docker stack deploy`, aby uruchomić wszystko zdalnie.

Alternatywnie, ustaw swoją lokalną zmienną środowiskową `DOCKER_HOST`, aby wskazywała na twój serwer, i uruchom polecenia `docker` lokalnie na swojej maszynie. Ważne jest, aby zauważyć, że w przypadku tego podejścia nie musisz kopiować żadnych plików swojego projektu na serwer, _ale_ musisz hostować swój obraz Dockera gdzieś, skąd twój serwer może go pobrać.
