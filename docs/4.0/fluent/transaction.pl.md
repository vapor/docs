# Transakcje

Transakcje pozwalają upewnić się, że wiele operacji zakończy się powodzeniem, zanim dane zostaną zapisane w bazie danych.
Po rozpoczęciu transakcji możesz normalnie wykonywać zapytania Fluent. Jednak żadne dane nie zostaną zapisane w bazie danych, dopóki transakcja się nie zakończy.
Jeśli w dowolnym momencie transakcji zostanie zgłoszony błąd (przez Ciebie lub przez bazę danych), żadna ze zmian nie zostanie zastosowana.

Aby wykonać transakcję, potrzebujesz dostępu do czegoś, co może połączyć się z bazą danych. Zazwyczaj jest to przychodzące żądanie HTTP. W tym celu użyj `req.db.transaction(_ :)`:
```swift
req.db.transaction { database in
    // use database
}
```
Wewnątrz domknięcia transakcji musisz używać bazy danych dostarczonej w parametrze domknięcia (nazwanej `database` w powyższym przykładzie) do wykonywania zapytań.

Gdy to domknięcie zwróci wynik pomyślnie, transakcja zostanie zatwierdzona.
```swift
var sun: Star = ...
var sirius: Star = ...

return req.db.transaction { database in
    return sun.save(on: database).flatMap { _ in
        return sirius.save(on: database)
    }
}
```
Powyższy przykład zapisze `sun`, a *następnie* `sirius`, zanim transakcja zostanie zakończona. Jeśli zapis którejkolwiek z gwiazd się nie powiedzie, żadna z nich nie zostanie zapisana.

Po zakończeniu transakcji jej wynik można przekształcić w inny future, na przykład w status HTTP wskazujący na zakończenie, jak pokazano poniżej:
```swift
return req.db.transaction { database in
    // use database and perform transaction
}.transform(to: HTTPStatus.ok)
```

## `async`/`await`

Jeśli używasz `async`/`await`, możesz przekształcić kod w następujący sposób:

```swift
try await req.db.transaction { transaction in
    try await sun.save(on: transaction)
    try await sirius.save(on: transaction)
}
return .ok
```
