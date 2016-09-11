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
  guard let query = request.query else {
    throw Abort.badRequest
  }
  let rating = try query.extract("rating") as Int
  return "You requested comments with rating greater than #\(rating)"
}
```
