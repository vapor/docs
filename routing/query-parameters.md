---
currentMenu: routing-query-parameters
---

# Query Parameters

Request query parameters can be accessed either as a dictionary or using the `extract` syntax which throws instead of returning an optional.

## Optional Syntax

Optional syntax is the easiest way to handle optional query parameters.

```swift
drop.get("comments") { request in
    if let rating = request.query?["rating"]?.int {
        return "You requested comments with rating greater than #\(rating)"
    }
    return "You requested all comments"
}
```

## Extract Syntax

Extract syntax might be useful to *enforce* the presence of query parameters and throw an exception if they are not present. 
To use this syntax first we need to ensure the query object is present with a `guard`.

```swift
drop.get("comments") { request in
    guard let rating = request.query?["rating"]?.int else {
        throw Abort.custom(status: .preconditionFailed, message: "Please include a rating")
    }
    return "You requested comments with rating greater than #\(rating)"
}
```
