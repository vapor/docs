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

## Usage

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



## Codable
