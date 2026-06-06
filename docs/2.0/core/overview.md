# Core

Core provides some conveniences for common tasks.

## Background

Easily create a background thread using `background()`

```swift
print("hello")

try background {
	print("world")	
}
```

## Portal

Portals allow you to make async tasks blocking.

```swift
let result = try Portal.open { portal in
	someAsyncTask { result in
		portal.close(with: result)
	}
}

print(result) // the result from the async task
```

## RFC1123

Create RFC1123 type dates.

```swift
let now = Date().rfc1123 // string 
```

You can also parse RFC1123 strings.

```
let parsed = Date(rfc1123: "Mon, 10 Apr 2017 11:26:13 GMT")
```
