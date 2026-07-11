# Kontrybucja do Vapor

Vapor jest projektem tworzonym przez społeczność, a wkład jej członków stanowi znaczącą część rozwoju Vapor. Ten przewodnik pomoże Ci zrozumieć proces kontrybucji i pomoże Ci wykonać pierwsze commity w Vapor!

Każdy wkład, który wnosisz, jest przydatny! Nawet drobne rzeczy, takie jak poprawianie literówek, robią dużą różnicę dla osób korzystających z Vapor.

## Kodeks postępowania

Vapor przyjął Kodeks postępowania Swift, który można znaleźć pod adresem [https://www.swift.org/code-of-conduct/](https://www.swift.org/code-of-conduct/). Od wszystkich kontrybutorów oczekuje się przestrzegania tego kodeksu postępowania.

## Nad czym pracować

Ustalenie, nad czym pracować, może być dużą przeszkodą, jeśli chodzi o rozpoczęcie przygody z open source! Zazwyczaj najlepsze do pracy są problemy, które sam znajdziesz, lub funkcje, których potrzebujesz. Jednak Vapor ma kilka przydatnych rzeczy, które pomogą Ci wnieść swój wkład.

### Problemy związane z bezpieczeństwem

Jeśli odkryjesz problem związany z bezpieczeństwem i chcesz go zgłosić lub pomóc go naprawić, **nie** twórz zgłoszenia (issue) ani pull requesta. Mamy oddzielny proces dla problemów związanych z bezpieczeństwem, aby nie ujawniać podatności, dopóki nie będzie dostępna poprawka. Wyślij e-mail na security@vapor.codes lub [zobacz tutaj](https://github.com/vapor/.github/blob/main/SECURITY.md), aby dowiedzieć się więcej.

### Drobne problemy

Jeśli znajdziesz drobny problem, błąd lub literówkę, śmiało utwórz pull request, aby to naprawić. Jeśli rozwiązuje to otwarte zgłoszenie w którymkolwiek z repozytoriów, możesz je połączyć w pull requeście w panelu bocznym, dzięki czemu zgłoszenie zostanie automatycznie zamknięte po scaleniu pull requesta.

![GitHub Link Issue](../images/github-link-issue.png)

### Nowe funkcje

Jeśli chcesz zaproponować większe zmiany, takie jak nowe funkcje lub poprawki błędów, które zmieniają znaczną ilość kodu, otwórz najpierw zgłoszenie (issue) lub napisz na kanale `#development` na Discordzie. Umożliwi nam to omówienie zmiany z Tobą, ponieważ może być potrzebny pewien kontekst albo możemy podać Ci wskazówki. Nie chcemy, abyś marnował(a) czas, jeśli dana funkcja nie pasuje do naszych planów!

### Tablice Vapor

Jeśli po prostu chcesz wnieść wkład, ale nie masz pomysłu, nad czym pracować, to świetnie! Vapor ma kilka tablic, które mogą pomóc. Vapor ma około 40 aktywnie rozwijanych repozytoriów, a przeglądanie ich wszystkich w poszukiwaniu czegoś do zrobienia nie jest praktyczne, dlatego używamy tablic, aby je zebrać w jednym miejscu.

Pierwszą tablicą jest [tablica good first issue](https://github.com/orgs/vapor/projects/14). Każde zgłoszenie w organizacji GitHub Vapor oznaczone jako `good first issue` zostanie dodane do tej tablicy, abyś mógł/mogła je znaleźć. Są to zgłoszenia, które naszym zdaniem będą dobre dla osób stosunkowo nowych w Vapor, ponieważ nie wymagają dużego doświadczenia z kodem.

Drugą tablicą jest [tablica help wanted](https://github.com/orgs/vapor/projects/13). Zbiera ona zgłoszenia oznaczone etykietą `help wanted`. Są to zgłoszenia, które warto byłoby naprawić, ale zespół główny (core team) ma obecnie inne priorytety. Te zgłoszenia zazwyczaj wymagają nieco większej wiedzy, jeśli nie są też oznaczone jako `good first issue`, ale mogą być ciekawymi projektami do pracy!

### Tłumaczenia

Ostatnim obszarem, w którym wkład jest niezwykle cenny, jest dokumentacja. Dokumentacja ma tłumaczenia na wiele języków, ale nie każda strona jest przetłumaczona i jest jeszcze wiele języków, które chcielibyśmy wspierać! Jeśli jesteś zainteresowany(a) wkładem w nowe języki lub aktualizacjami, zobacz [README dokumentacji](https://github.com/vapor/docs#translating) lub napisz na kanale `#documentation` na Discordzie.

## Proces kontrybucji

Jeśli nigdy nie pracowałeś/aś przy projekcie open source, kroki prowadzące do faktycznego wniesienia wkładu mogą wydawać się mylące, ale są dość proste.

Najpierw zrób fork Vapor lub dowolnego repozytorium, w którym chcesz pracować. Możesz to zrobić w interfejsie GitHub, a GitHub ma [świetną dokumentację](https://docs.github.com/en/get-started/quickstart/fork-a-repo) na temat tego, jak to zrobić.

Następnie możesz wprowadzać zmiany w swoim forku, korzystając ze zwykłego procesu commitowania i push'owania. Gdy będziesz gotowy(a) do przesłania swojej poprawki, możesz utworzyć PR do repozytorium Vapor. Ponownie, GitHub ma [świetną dokumentację](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork) na temat tego, jak to zrobić.

## Przesyłanie pull requesta

Podczas przesyłania pull requesta powinieneś/aś sprawdzić kilka rzeczy:

* Wszystkie testy przechodzą
* Dodano nowe testy dla nowego zachowania lub naprawionych błędów
* Nowe publiczne API są udokumentowane. Do dokumentacji API używamy DocC.

Vapor korzysta z automatyzacji, aby zmniejszyć ilość pracy potrzebnej do wielu zadań. W przypadku pull requestów używamy [Vapor Bota](https://github.com/VaporBot) do generowania wydań, gdy pull request zostanie scalony. Treść i tytuł pull requesta są używane do generowania informacji o wydaniu, więc upewnij się, że mają sens i obejmują to, czego można by oczekiwać w informacjach o wydaniu. Więcej szczegółów znajdziesz w [wytycznych dotyczących kontrybucji Vapor](https://github.com/vapor/vapor/blob/main/.github/contributing.md#release-title).
