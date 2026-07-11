# Fly

Fly to platforma hostingowa, która umożliwia uruchamianie aplikacji serwerowych i baz danych ze szczególnym naciskiem na edge computing. Zobacz [ich stronę internetową](https://fly.io/), aby dowiedzieć się więcej.

!!! note
    Polecenia opisane w tym dokumencie podlegają [cennikowi Fly](https://fly.io/docs/about/pricing/), upewnij się, że dobrze go rozumiesz, zanim będziesz kontynuować.

## Rejestracja
Jeśli nie masz konta, musisz [je utworzyć](https://fly.io/app/sign-up).

## Instalacja flyctl
Głównym sposobem interakcji z Fly jest korzystanie z dedykowanego narzędzia CLI, `flyctl`, które musisz zainstalować.

### macOS
```bash
brew install flyctl
```

### Linux
```bash
curl -L https://fly.io/install.sh | sh
```

### Inne opcje instalacji
Więcej opcji i szczegółów znajdziesz w [dokumentacji instalacji `flyctl`](https://fly.io/docs/flyctl/install/).

## Logowanie
Aby zalogować się z terminala, uruchom następujące polecenie:
```bash
fly auth login
```

## Konfiguracja projektu Vapor
Przed wdrożeniem na Fly musisz upewnić się, że masz projekt Vapor z odpowiednio skonfigurowanym Dockerfile, ponieważ jest on wymagany przez Fly do zbudowania Twojej aplikacji. W większości przypadków powinno to być bardzo proste, ponieważ domyślne szablony Vapor już go zawierają.

### Nowy projekt Vapor
Najłatwiejszym sposobem utworzenia nowego projektu jest rozpoczęcie od szablonu. Możesz go utworzyć za pomocą szablonów GitHub lub Vapor toolbox. Jeśli potrzebujesz bazy danych, zaleca się użycie Fluent z Postgres; Fly ułatwia utworzenie bazy danych Postgres, do której możesz podłączyć swoje aplikacje (zobacz [dedykowaną sekcję](#konfiguracja-postgres) poniżej).

#### Za pomocą Vapor toolbox
Najpierw upewnij się, że masz zainstalowany Vapor toolbox (zobacz instrukcje instalacji dla [macOS](../install/macos.md#zainstaluj-toolbox) lub [Linux](../install/linux.md#zainstaluj-toolbox)).
Utwórz swoją nową aplikację za pomocą następującego polecenia, zastępując `app-name` nazwą aplikacji, jaką chcesz nadać:
```bash
vapor new app-name
```

To polecenie wyświetli interaktywny monit, który pozwoli Ci skonfigurować projekt Vapor - to tutaj możesz wybrać Fluent i Postgres, jeśli ich potrzebujesz.

#### Za pomocą szablonów GitHub
Wybierz szablon, który najlepiej odpowiada Twoim potrzebom z poniższej listy. Możesz go sklonować lokalnie za pomocą Git lub utworzyć projekt GitHub za pomocą przycisku "Use this template".

- [Szablon Barebones](https://github.com/vapor/template-bare)
- [Szablon Fluent/Postgres](https://github.com/vapor/template-fluent-postgres)
- [Szablon Fluent/Postgres + Leaf](https://github.com/vapor/template-fluent-postgres-leaf)

### Istniejący projekt Vapor
Jeśli masz istniejący projekt Vapor, upewnij się, że masz odpowiednio skonfigurowany plik `Dockerfile` obecny w katalogu głównym; [dokumentacja Vapor o korzystaniu z Dockera](../deploy/docker.md) oraz [dokumentacja Fly o wdrażaniu aplikacji za pomocą Dockerfile](https://fly.io/docs/languages-and-frameworks/dockerfile/) mogą się przydać.

## Uruchom swoją aplikację na Fly
Gdy Twój projekt Vapor jest gotowy, możesz uruchomić go na Fly.

Najpierw upewnij się, że Twój bieżący katalog jest ustawiony na katalog główny Twojej aplikacji Vapor, i uruchom następujące polecenie:
```bash
fly launch
```

To uruchomi interaktywny monit do konfiguracji ustawień Twojej aplikacji Fly:

- **Nazwa:** możesz wpisać jedną lub pozostawić puste pole, aby otrzymać automatycznie wygenerowaną nazwę.
- **Region:** domyślnie jest to ten, który jest najbliżej Ciebie. Możesz go użyć lub wybrać dowolny inny z listy. Można to łatwo zmienić później.
- **Baza danych:** możesz poprosić Fly o utworzenie bazy danych do użycia z Twoją aplikacją. Jeśli wolisz, zawsze możesz zrobić to samo później za pomocą poleceń `fly pg create` i `fly pg attach` (zobacz sekcję [Konfiguracja Postgres](#konfiguracja-postgres), aby dowiedzieć się więcej).

Polecenie `fly launch` automatycznie tworzy plik `fly.toml`. Zawiera on ustawienia takie jak mapowania portów prywatnych/publicznych, parametry kontroli stanu (health checks) i wiele innych. Jeśli właśnie utworzyłeś nowy projekt od podstaw za pomocą `vapor new`, domyślny plik `fly.toml` nie wymaga żadnych zmian. Jeśli masz istniejący projekt, jest szansa, że `fly.toml` również będzie dobry bez zmian lub z niewielkimi zmianami. Więcej informacji znajdziesz w [dokumentacji `fly.toml`](https://fly.io/docs/reference/configuration/).

Zwróć uwagę, że jeśli poprosisz Fly o utworzenie bazy danych, będziesz musiał trochę poczekać, aż zostanie utworzona i przejdzie kontrole stanu.

Przed zakończeniem polecenie `fly launch` zapyta Cię, czy chcesz od razu wdrożyć swoją aplikację. Możesz się zgodzić lub zrobić to później za pomocą `fly deploy`.

!!! tip
    Gdy Twój bieżący katalog znajduje się w katalogu głównym Twojej aplikacji, narzędzie CLI fly automatycznie wykrywa obecność pliku `fly.toml`, co informuje Fly, którą aplikację dotyczą Twoje polecenia. Jeśli chcesz wskazać konkretną aplikację niezależnie od bieżącego katalogu, możesz dodać `-a nazwa-twojej-aplikacji` do większości poleceń Fly.

## Wdrażanie
Uruchamiasz polecenie `fly deploy` za każdym razem, gdy musisz wdrożyć nowe zmiany na Fly.

Fly odczytuje pliki `Dockerfile` i `fly.toml` z Twojego katalogu, aby określić, jak zbudować i uruchomić Twój projekt Vapor.

Gdy Twój kontener zostanie zbudowany, Fly uruchamia jego instancję. Wykona różne kontrole stanu, upewniając się, że Twoja aplikacja działa poprawnie, a serwer odpowiada na żądania. Polecenie `fly deploy` kończy się błędem, jeśli kontrole stanu się nie powiodą.

Domyślnie Fly wycofa się do ostatniej działającej wersji Twojej aplikacji, jeśli kontrole stanu nie powiodą się dla nowej wersji, którą próbowałeś wdrożyć.

Podczas wdrażania workera w tle (z Vapor Queues) nie zmieniaj CMD ani ENTRYPOINT w swoim Dockerfile; pozostaw je bez zmian, aby główna aplikacja webowa uruchamiała się normalnie. Zamiast tego dodaj sekcję [processes] w swoim pliku fly.toml, tak jak poniżej:

```
[processes]
  app = ""
  worker = "queues"
```

To informuje Fly.io, aby uruchomił proces app z domyślnym punktem wejścia Dockera (Twój serwer webowy), a proces worker, aby uruchomił Twoją kolejkę zadań za pomocą interfejsu wiersza poleceń Vapor (tj. swift run App queues).

## Konfiguracja Postgres

### Tworzenie bazy danych Postgres na Fly
Jeśli nie utworzyłeś aplikacji bazodanowej podczas pierwszego uruchamiania swojej aplikacji, możesz zrobić to później za pomocą:
```bash
fly pg create
```

To polecenie tworzy aplikację Fly, która będzie mogła hostować bazy danych dostępne dla innych Twoich aplikacji na Fly, zobacz [dedykowaną dokumentację Fly](https://fly.io/docs/postgres/), aby dowiedzieć się więcej.

Gdy Twoja aplikacja bazodanowa zostanie utworzona, przejdź do katalogu głównego swojej aplikacji Vapor i uruchom:
```bash
fly pg attach name-of-your-postgres-app
```
Jeśli nie znasz nazwy swojej aplikacji Postgres, możesz ją znaleźć za pomocą `fly pg list`.

Polecenie `fly pg attach` tworzy bazę danych i użytkownika przeznaczonych dla Twojej aplikacji, a następnie udostępnia je Twojej aplikacji poprzez zmienną środowiskową `DATABASE_URL`.

!!! note
    Różnica między `fly pg create` a `fly pg attach` polega na tym, że pierwsze polecenie alokuje i konfiguruje aplikację Fly, która będzie mogła hostować bazy danych Postgres, podczas gdy drugie tworzy rzeczywistą bazę danych i użytkownika przeznaczonych dla wybranej przez Ciebie aplikacji. O ile spełnia to Twoje wymagania, pojedyncza aplikacja Postgres Fly może hostować wiele baz danych używanych przez różne aplikacje. Gdy poprosisz Fly o utworzenie aplikacji bazodanowej w `fly launch`, wykonuje ono odpowiednik wywołania zarówno `fly pg create`, jak i `fly pg attach`.

### Łączenie aplikacji Vapor z bazą danych
Gdy Twoja aplikacja zostanie podłączona do bazy danych, Fly ustawia zmienną środowiskową `DATABASE_URL` na adres URL połączenia zawierający Twoje dane uwierzytelniające (powinien być traktowany jako informacja wrażliwa).

W większości typowych konfiguracji projektów Vapor konfigurujesz swoją bazę danych w `configure.swift`. Oto jak możesz to zrobić:

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    try app.databases.use(.postgres(url: databaseURL), as: .psql)
} else {
    // Handle missing DATABASE_URL here...
    //
    // Alternatively, you could also set a different config 
    // depending on wether app.environment is set to to 
    // `.development` or `.production`
}
```

W tym momencie Twój projekt powinien być gotowy do uruchamiania migracji i korzystania z bazy danych.

### Uruchamianie migracji
Za pomocą `release_command` w `fly.toml` możesz poprosić Fly o uruchomienie określonego polecenia przed uruchomieniem głównego procesu serwera. Dodaj to do `fly.toml`:
```toml
[deploy]
 release_command = "migrate -y"
```

!!! note
    Powyższy fragment kodu zakłada, że korzystasz z domyślnego Dockerfile Vapor, który ustawia `ENTRYPOINT` Twojej aplikacji na `./App`. Konkretnie oznacza to, że gdy ustawisz `release_command` na `migrate -y`, Fly wywoła `./App migrate -y`. Jeśli Twój `ENTRYPOINT` jest ustawiony na inną wartość, musisz odpowiednio dostosować wartość `release_command`.

Fly uruchomi Twoje polecenie release w tymczasowej instancji, która ma dostęp do Twojej wewnętrznej sieci Fly, sekretów i zmiennych środowiskowych.

Jeśli Twoje polecenie release zakończy się niepowodzeniem, wdrożenie nie będzie kontynuowane.

### Inne bazy danych
Chociaż Fly ułatwia tworzenie aplikacji bazodanowej Postgres, możliwe jest również hostowanie innych typów baz danych (na przykład zobacz ["Use a MySQL database"](https://fly.io/docs/app-guides/mysql-on-fly/) w dokumentacji Fly).

## Sekrety i zmienne środowiskowe
### Sekrety
Użyj sekretów, aby ustawić dowolne wrażliwe wartości jako zmienne środowiskowe.
```bash
 fly secrets set MYSECRET=A_SUPER_SECRET_VALUE
```

!!! warning
    Pamiętaj, że większość powłok przechowuje historię wpisanych poleceń. Zachowaj ostrożność w tej kwestii, ustawiając sekrety w ten sposób. Niektóre powłoki można skonfigurować tak, aby nie zapamiętywały poleceń poprzedzonych spacją. Zobacz również [polecenie `fly secrets import`](https://fly.io/docs/flyctl/secrets-import/).

Aby dowiedzieć się więcej, zobacz [dokumentację `fly secrets`](https://fly.io/docs/apps/secrets/).

### Zmienne środowiskowe
Możesz ustawić inne, niewrażliwe [zmienne środowiskowe w `fly.toml`](https://fly.io/docs/reference/configuration/#the-env-variables-section), na przykład:
```toml
[env]
  MAX_API_RETRY_COUNT = "3"
  SMS_LOG_LEVEL = "error"
```

## Połączenie SSH
Możesz połączyć się z instancjami aplikacji za pomocą:
```bash
fly ssh console -s
```

## Sprawdzanie logów
Możesz sprawdzić na żywo logi swojej aplikacji za pomocą:
```bash
fly logs
```

## Następne kroki
Teraz, gdy Twoja aplikacja Vapor jest wdrożona, jest o wiele więcej rzeczy, które możesz zrobić, takich jak skalowanie swoich aplikacji wertykalnie i horyzontalnie w wielu regionach, dodawanie trwałych woluminów, konfigurowanie ciągłego wdrażania, a nawet tworzenie rozproszonych klastrów aplikacji. Najlepszym miejscem, aby dowiedzieć się, jak to wszystko zrobić i wiele więcej, jest [dokumentacja Fly](https://fly.io/docs/).
