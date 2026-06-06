# Witaj, świecie

Then poradnik przeprowadzi cię krok po kroku przez tworzenie nowego projektu z użyciem Vapor, budowania go oraz uruchomienie serwera.

Jeśli jeszcze nie masz zainstalowanego Swifta czy Vapor Toolbox, to sprawdź sekcje poniżej.

- [Instalacja &rarr; macOS](../install/macos.md)
- [Instalacja &rarr; Linux](../install/linux.md)

## Nowy projekt

Pierwszym krokiem jest utworzenie nowego projektu Vapor na komputerze. Otwórz terminal i użyj polecenia nowego projektu w Toolbox. Spowoduje to utworzenie nowego folderu w bieżącym katalogu zawierającego projekt.

```sh
vapor new hello -n
```

!!! tip
    Flaga `-n` tworzy projekt z użyciem minimalistycznego szablonu, po przez odpowiadanie na wszystkie pytania nie.

!!! tip
    Można również pobrać najnowszy szablon z GitHub bez Vapor Toolbox, klonując [repozytorium z szablonami](https://github.com/vapor/template-bare).

!!! tip
    Vapor i szablon używają teraz domyślnie `async`/`await`.
    Jeśli nie możesz zaktualizować systemu do macOS 12 i/lub chcesz nadal używać `EventLoopFuture`,
    użyj flagi `--branch macos10-15`.

Po tym jak działanie komendy zakończy się, wejdź do nowo stworzonego folderu przy użyciu:

```sh
cd hello
```

## Zbuduj i uruchom

### Xcode

Najpierw, otwórz projekt w XCode.

```sh
open Package.swift
```

Automatycznie rozpocznie pobieranie zależności Menedżera pakietów Swift. Może to zająć trochę czasu przy pierwszym otwarciu projektu. Po zakończeniu rozpoznawania zależności Xcode wypełni dostępne schematy. 

W górnej części okna, po prawej stronie przycisków Play i Stop, kliknij nazwę projektu, aby wybrać schemat projektu i wybierz odpowiedni cel uruchamiania - najprawdopodobniej "My Mac". Kliknij przycisk odtwarzania, aby utworzyć i uruchomić projekt.

W oknie terminala Xcode powinna pojawić się konsola.

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

### Linux

W systemie Linux i innych systemach operacyjnych (a nawet w systemie macOS, jeśli nie chcesz używać Xcode) możesz edytować projekt w swoim ulubionym edytorze, takim jak Vim lub VSCode. Aktualne informacje na temat konfiguracji innych IDE można znaleźć w [Swift Server Guides](https://github.com/swift-server/guides/blob/main/docs/setup-and-ide-alternatives.md).

Aby zbudować i uruchomić projekt, w Terminalu uruchom:

```sh
swift run
```

Spowoduje to zbudowanie i uruchomienie projektu. Przy pierwszym uruchomieniu pobieranie i rozwiązywanie zależności zajmie trochę czasu. Po uruchomieniu powinieneś zobaczyć następujące informacje w konsoli:

```sh
[ INFO ] Server starting on http://127.0.0.1:8080
```

## Odwiedź localhost

Otwórz swoją przeglądarkę, a następnie adres: <a href="http://localhost:8080/hello" target="_blank">localhost:8080/hello</a> lub <a href="http://127.0.0.1:8080" target="_blank">http://127.0.0.1:8080</a>

Powinieneś widzieć następująca stronę.

```html
Hello, world!
```

Gratulujemy stworzenia, zbudowania i uruchomienia twojej pierwszej aplikacji z użyciem Vapora! 🎉🎉
