# Czym jest Heroku

Heroku to popularne, kompleksowe rozwiązanie hostingowe, więcej informacji znajdziesz na [heroku.com](https://www.heroku.com)

## Rejestracja

Będziesz potrzebować konta heroku, jeśli go nie masz, zarejestruj się tutaj: [https://signup.heroku.com/](https://signup.heroku.com/)

## Instalacja CLI

Upewnij się, że zainstalowałeś narzędzie heroku cli.

### HomeBrew

```bash
brew tap heroku/brew && brew install heroku
```

### Inne opcje instalacji

Zobacz alternatywne opcje instalacji tutaj: [https://devcenter.heroku.com/articles/heroku-cli#download-and-install](https://devcenter.heroku.com/articles/heroku-cli#download-and-install).

### Logowanie

Po zainstalowaniu cli, zaloguj się za pomocą:

```bash
heroku login
```

Zweryfikuj, że zalogowany jest właściwy adres e-mail za pomocą:

```bash
heroku auth:whoami
```

### Utwórz aplikację

Odwiedź dashboard.heroku.com, aby uzyskać dostęp do swojego konta, i utwórz nową aplikację z rozwijanego menu w prawym górnym rogu. Heroku zada kilka pytań, takich jak region i nazwa aplikacji, po prostu postępuj zgodnie z instrukcjami.

### Git

Heroku używa Gita do wdrażania Twojej aplikacji, więc musisz umieścić swój projekt w repozytorium Git, jeśli jeszcze tego nie zrobiłeś.

#### Zainicjuj Git

Jeśli musisz dodać Git do swojego projektu, wpisz następującą komendę w terminalu:

```bash
git init
```

#### Main

Powinieneś zdecydować się na jedną gałąź i trzymać się jej przy wdrażaniu na Heroku, taką jak gałąź **main** lub **master**. Upewnij się, że wszystkie zmiany są zatwierdzone (committed) w tej gałęzi przed pushowaniem.

Sprawdź swoją bieżącą gałąź za pomocą:

```bash
git branch
```

Gwiazdka wskazuje bieżącą gałąź.

```bash
* main
  commander
  other-branches
```

!!! note 
    Jeśli nie widzisz żadnego wyniku, a właśnie wykonałeś `git init`. Musisz najpierw zatwierdzić swój kod, a wtedy zobaczysz wynik komendy `git branch`.

Jeśli aktualnie *nie* jesteś na właściwej gałęzi, przełącz się na nią, wpisując (dla **main**):

```bash
git checkout main
```

#### Zatwierdź zmiany

Jeśli ta komenda zwraca jakiś wynik, oznacza to, że masz niezatwierdzone zmiany.

```bash
git status --porcelain
```

Zatwierdź je za pomocą poniższego

```bash
git add .
git commit -m "a description of the changes I made"
```

#### Połącz z Heroku

Połącz swoją aplikację z heroku (zamień na nazwę swojej aplikacji).

```bash
$ heroku git:remote -a your-apps-name-here
```

### Ustaw buildpack

Ustaw buildpack, aby nauczyć heroku, jak radzić sobie z vapor.

```bash
heroku buildpacks:set vapor/vapor
```

### Plik wersji Swift

Dodany buildpack szuka pliku **.swift-version**, aby wiedzieć, której wersji swift użyć. (Zamień 5.8.1 na wersję, jakiej wymaga Twój projekt.)

```bash
echo "5.8.1" > .swift-version
```

To tworzy **.swift-version** z `5.8.1` jako jego zawartością.

### Procfile

Heroku używa **Procfile**, aby wiedzieć, jak uruchomić Twoją aplikację, w naszym przypadku musi to wyglądać tak:

```
web: App serve --env production --hostname 0.0.0.0 --port $PORT
```

Możemy to utworzyć za pomocą następującej komendy terminala

```bash
echo "web: App serve --env production" \
  "--hostname 0.0.0.0 --port \$PORT" > Procfile
```

### Zatwierdź zmiany

Właśnie dodaliśmy te pliki, ale nie są one zatwierdzone. Jeśli je wypushujemy, heroku ich nie znajdzie.

Zatwierdź je za pomocą poniższego.

```bash
git add .
git commit -m "adding heroku build files"
```

### Wdrażanie na Heroku

Jesteś gotowy do wdrożenia, uruchom to z terminala. Zbudowanie może potrwać chwilę, to normalne.

```bash
git push heroku main
```

### Skalowanie w górę

Po pomyślnym zbudowaniu musisz dodać przynajmniej jeden serwer. Ceny zaczynają się od 5 USD/miesiąc za plan Eco (zobacz [cennik](https://www.heroku.com/pricing#containers)), upewnij się, że masz skonfigurowaną płatność na Heroku. Następnie dla pojedynczego web workera:

```bash
heroku ps:scale web=1
```

### Kontynuacja wdrażania

Za każdym razem, gdy chcesz zaktualizować aplikację, wystarczy pobrać najnowsze zmiany do main i wypushować na heroku, a nastąpi ponowne wdrożenie.

## Postgres

### Dodaj bazę danych PostgreSQL

Odwiedź swoją aplikację na dashboard.heroku.com i przejdź do sekcji **Add-ons**.

Tutaj wpisz `postgres`, a zobaczysz opcję `Heroku Postgres`. Wybierz ją.

Wybierz plan Essential 0 za 5 USD/miesiąc (zobacz [cennik](https://www.heroku.com/pricing#data-services)) i zainicjuj (provision). Heroku zajmie się resztą.

Po zakończeniu zobaczysz bazę danych w zakładce **Resources**.

### Skonfiguruj bazę danych

Musimy teraz powiedzieć naszej aplikacji, jak uzyskać dostęp do bazy danych. W katalogu naszej aplikacji uruchommy.

```bash
heroku config
```

To wygeneruje wynik podobny do tego

```none
=== today-i-learned-vapor Config Vars
DATABASE_URL: postgres://cybntsgadydqzm:2d9dc7f6d964f4750da1518ad71hag2ba729cd4527d4a18c70e024b11cfa8f4b@ec2-54-221-192-231.compute-1.amazonaws.com:5432/dfr89mvoo550b4
```

**DATABASE_URL** reprezentuje tutaj naszą bazę danych postgres. **NIGDY** nie zapisuj na stałe (hard code) statycznego adresu url z tego, heroku będzie go rotować, co spowoduje awarię Twojej aplikacji. To również zła praktyka. Zamiast tego odczytuj zmienną środowiskową w czasie działania (runtime).

Dodatek Heroku Postgres [wymaga](https://devcenter.heroku.com/changelog-items/2035), aby wszystkie połączenia były szyfrowane. Certyfikaty używane przez serwery Postgres są wewnętrzne dla Heroku, dlatego konieczne jest skonfigurowanie **niezweryfikowanego (unverified)** połączenia TLS.

Poniższy fragment kodu pokazuje, jak osiągnąć jedno i drugie:

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    var tlsConfig: TLSConfiguration = .makeClientConfiguration()
    tlsConfig.certificateVerification = .none
    let nioSSLContext = try NIOSSLContext(configuration: tlsConfig)

    var postgresConfig = try SQLPostgresConfiguration(url: databaseURL)
    postgresConfig.coreConfiguration.tls = .require(nioSSLContext)

    app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
} else {
    // ...
}
```

Nie zapomnij zatwierdzić tych zmian

```bash
git add .
git commit -m "configured heroku database"
```

### Cofanie zmian w bazie danych

Możesz cofnąć zmiany lub uruchomić inne komendy na heroku za pomocą komendy `run`.

Aby cofnąć zmiany w bazie danych:

```bash
heroku run App -- migrate --revert --all --yes --env production
```

Aby zmigrować:

```bash
heroku run App -- migrate --env production
```
