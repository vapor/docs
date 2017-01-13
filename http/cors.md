---
currentMenu: http-cors
---

# CORS

Vapor by default provides a middleware for implementing proper support for Cross-Origin Resource Sharing (CORS) named `CORSMiddleware`.

"Cross-Origin Resource Sharing (CORS) is a specification that enables truly open access across domain-boundaries. If you serve public content, please consider using CORS to open it up for universal JavaScript / browser access." - [http://enable-cors.org/](http://enable-cors.org/)

To learn more about middlewares, please visit the Middleware section of the documentation [here](https://vapor.github.io/documentation/guide/middleware.html).

![](https://upload.wikimedia.org/wikipedia/commons/c/ca/Flowchart_showing_Simple_and_Preflight_XHR.svg)
*Image Author: [Wikipedia](https://commons.wikimedia.org/wiki/File:Flowchart_showing_Simple_and_Preflight_XHR.svg)*

## Basic

First of all, add the CORS middleware into your droplet middlewares array.

```swift
# Insert CORS before any other middlewares
drop.middleware.insert(CORSMiddleware(), at: 0)
``` 

> Note: Make sure you insert CORS middleware before any other throwing middlewares, like the AbortMiddleware or similar. Otherwise the proper headers might not be added to the response.

`CORSMiddleware` has a default configuration which should suit most users, with values as follows:

- **Allowed Origin** 
	- Value of origin header in the request.
- **Allowed Methods** 
	- `GET`, `POST`, `PUT`, `OPTIONS`, `DELETE`, `PATCH`
- **Allowed Headers**
	- `Accept`, `Authorization`, `Content-Type`, `Origin`, `X-Requested-With`

## Advanced

All settings and presets can be customized by advanced users. There's two ways of doing this, either you programatically create and configure a `CORSConfiguration` object or you can put your configuration into a Vapor's JSON config file.

See below for how to set up both and what are the options.

### Configuration

The `CORSConfiguration` struct is used to configure the `CORSMiddleware`. You can instanitate one like this:

```swift
let configuration = CORSConfiguration(allowedOrigin: .custom("https://vapor.codes"),
						                  allowedMethods: [.get, .post, .options],
						                  allowedHeaders: ["Accept", "Authorization"],
						                  allowCredentials: false,
						                  cacheExpiration: 600,
						                  exposedHeaders: ["Cache-Control", "Content-Language"])
```

After creating a configuration you can add the CORS middleware.

```swift
drop.middleware.insert(CORSMiddleware(configuration: configuration), at: 0)
```

> Note: Please consult the documentation in the source code of the `CORSConfiguration` for more information about available values for the settings.


### JSON Config

Optionally, `CORSMiddleware` can be configured using the Vapor's `Config` which is created out of the json files contained in your Config folder. You will need to create a file called `cors.json` or `CORS.json` in your Config folder in your project and add the required keys.

Example of how such a file could look as follows:

```swift
{
    "allowedOrigin": "origin",
    "allowedMethods": "GET,POST,PUT,OPTIONS,DELETE,PATCH",
    "allowedHeaders": ["Accept", "Authorization", "Content-Type", "Origin", "X-Requested-With"]
}

```

> Note: Following keys are required: `allowedOrigin`, `allowedMethods`, `allowedHeaders`. If they are not present an error will be thrown while instantiating the middleware.
> 
> Optionally you can also specify the keys `allowCredentials` (Bool), `cacheExpiration` (Int) and `exposedHeaders` ([String]).

Afterwards you can add the middleware using the a throwing overload of the initialiser that accepts Vapor's `Config`.

```swift
let drop = Droplet()

do {
	drop.middleware.insert(try CORSMiddleware(configuration: drop.config), at: 0)
} catch {
	fatalError("Error creating CORSMiddleware, please check that you've setup cors.json correctly.")
}
```

