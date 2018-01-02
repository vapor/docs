# BSON

BSON is a performant (not compact) format for storing data in MongoDB.
The BSON module used here is extremely performant and support Codable.

## Primitives

MongoDB has a set of supported primitives. At the root of any BSON data lies a `Document`.

- Double
- String
- Document (Array and Dictionary)
- ObjectId
- Bool
- Int32
- Int (Int64)
- Binary
- Decimal128 **(not supported)**
- JavascriptCode
- Null (not nil)
- Date (from Foundation)
- MinKey
- MaxKey
- RegularExpression (BSON Type)

### Document

Document is a type that comes in two representations. Array and Dictionary-like.
You should see Document as `[(String, Primitive)]`.

Array-like Documents ignore the key (`String`) whilst Dictionary-like Documents require using it.
For this reason, both `Document` variants are the same struct type and behave the same way.

You can subscript a dictionary-like document with an integer, and an array-like document by it's key.

# Usage

The root type of any BSON structure is a `Document`, please note that MongoDB entities **must** be a dictionary-like.

To create a dictionary-like BSON Document:

```swift
// Dictionary document by default
var document = Document()
```

You can also use a dictionary or array literal. This creates the respective BSON document type.

```swift
var arrayDocument: Document = []
var dictionaryDocument: Document = [:]
```

## Accessing Dictionary Documents

To access a dictionary document you must subscript with a key:

```swift
let username = dictionaryDocument["username"] // Primitive?
```

The return type is a Primitive type, which is a protocol.

## Accessing Array Documents

To a

## Primitives

To access the concrete type of the primitive you must either cast the primitive to a concrete type or loosely unwrap the type.

For the purpose of demonstration we're assuming the following Document:

```swift
var doc: Document = [
    "_id": ObjectId(),
    "username": "Joannis",
    "admin": true,
    "year": 2018
]
```

### Casting

Casting is used when you want exactly that type. A good example is a `String`.

```swift
let username = doc["username"] as? String // String?
print(username) // Optional("Joannis")
```

The following will be nil because they're not a `String`.

```swift
let _id: = doc["_id"] as? String // String?
print(_id) // nil

let admin = doc["admin"] as? String // String?
print(admin) // nil

let year = doc["year"] as? String // String?
print(year) // nil
```

### Loosely Converting

Converting is useful when you don't care about the specifics.
For example, when exposing data over JSON.

```swift
let username = String(lossy: doc["username"]) // String?
print(username) // Optional("Joannis")
```

This converts types to a String when it's sensible:

```swift
let _id: = doc["_id"] as? String // String?
print(_id) // Optional("afafafafafafafafafafafaf")

let admin = doc["admin"] as? String // String?
print(admin) // Optional("true")

let year = doc["year"] as? String // String?
print(year) // Optional("2018")
```

## Codable

BSON has highly optimized support for Codable through `BSONEncoder` and `BSONDecoder`.

```swift
struct User: Codable {
    var _id = ObjectId()
    var username: String
    var admin: Bool = false
    var year: Int

    init(named name: String, year: Int) {
        self.username = name
        self.year = year
    }
}

let user = User(named: "Joannis", year: 2018)

let userDocument = try BSONEncoder().encode(user)

let username = userDocument["username"] as? String
print(username) // Optional("Joannis")

let sameUser = try BSONDecoder().decode(User.self, from: userDocument)

print(sameUser.username) // "Joannis"
```
