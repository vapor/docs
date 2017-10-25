# Multipart Forms

Multipart is a module that is primarily used with Forms. Multipart is used for complex forms containing one or more files, input fields and other HTML form data.

## Parsing a multipart form

Multipart forms can be parsed using `MultipartParser`.

```swift
let multipartForm = try MultipartParser.parse(from: request)
```

## Reading forms

The parsed form is an array of `Part` instances.
Each of them contains data and headers.

You can read a part using either manually or using the `Form`'s helpers.

```swift
let pictureData = try multipartForm.getFile(forName: "profile-picture")
```

```swift
let newPassword = try multipartForm.getString(forName: "password")
```
