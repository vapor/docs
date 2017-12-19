# Multipart Forms

Multipart is a module that is primarily used with Forms. Multipart is used for complex forms containing one or more files, input fields and other HTML form data.

## Extracting from a request

`MultipartForm` is a type of [`Content`](../getting-started/content.md) and can be extracted like any type of Content.

```swift
let form = try MultipartForm.decode(from: request) // Future<MultipartForm>
```

A future is returned because of streaming/reactive body parsing.

## Parsing a multipart form

Multipart forms can be parsed using `MultipartParser` provided a body and boundary to read.

```swift
let form = try MultipartParser(body: httpBody, boundary: boundaryBytes).parse()
```

## Reading forms

The parsed form is an array of `Part` instances.
Each of them contains data and headers.

You can read a part using either manually or using the `MultipartForm`'s helpers.

```swift
let pictureData = try form.getFile(named: "profile-picture")
```

```swift
let newPassword = try form.getString(named: "password")
```
