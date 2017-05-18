---
currentMenu: http-cors
---

# CORS

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

Vapor 默认提供了一个中间件 `CORSMiddleware`，用于实现对于 跨域资源共享 （Cross-Origin Resource Sharing - CORS) 支持。

"Cross-Origin Resource Sharing (CORS) is a specification that enables truly open access across domain-boundaries. If you serve public content, please consider using CORS to open it up for universal JavaScript / browser access." - [http://enable-cors.org/](http://enable-cors.org/)    
“跨域资源共享（Cross-Origin Resource Sharing - CORS）是一种可以跨域边界真正开放访问的规范。如果您提供公开内容，请考虑使用 CORS 开放它，以实现通用 JavaScript/浏览器 访问。 - [http://enable-cors.org/](http://enable-cors.org/)

要了解更多关于中间件的内容，请访问文档的 Middleware 章节[here](https://vapor.github.io/documentation/guide/middleware.html)

![](https://upload.wikimedia.org/wikipedia/commons/c/ca/Flowchart_showing_Simple_and_Preflight_XHR.svg)
*Image Author: [Wikipedia](https://commons.wikimedia.org/wiki/File:Flowchart_showing_Simple_and_Preflight_XHR.svg)*

## 基础 （Basic）

首先添加 CORS 中间件到你的 middleware 数组中。

```swift
# Insert CORS before any other middlewares
drop.middleware.insert(CORSMiddleware(), at: 0)
```

> 注意： 确保你在任何可能抛出错误的中间件（例如 AbortMiddleware 或者其他类似的）前插入 CORS 中间件。否则可能不会将适当的标头添加到响应中。

`CORSMiddleware` 有一个默认的配置，应该能够满足大部分用户，值如下：

- **Allowed Origin**
	- Value of origin header in the request.
- **Allowed Methods**
	- `GET`, `POST`, `PUT`, `OPTIONS`, `DELETE`, `PATCH`
- **Allowed Headers**
	- `Accept`, `Authorization`, `Content-Type`, `Origin`, `X-Requested-With`

## 高级 （Advanced）

所有设置和预设都可以由高级用户自定义。有两种方法可以实现：编程式创建配置 `CORSConfiguration` 对象，或者把你的配置到放到 Vapor 的 JSON 配置文件中。

下面看一下如何通过两种方式设置这些选项。

### Configuration

`CORSConfiguration` 结构体被用来配置 `CORSMiddleware`，你能够像下面那样实例化一个：

```swift
let configuration = CORSConfiguration(allowedOrigin: .custom("https://vapor.codes"),
						                  allowedMethods: [.get, .post, .options],
						                  allowedHeaders: ["Accept", "Authorization"],
						                  allowCredentials: false,
						                  cacheExpiration: 600,
						                  exposedHeaders: ["Cache-Control", "Content-Language"])
```

创建配置之后，你能添加 CORS 中间件。

```swift
drop.middleware.insert(CORSMiddleware(configuration: configuration), at: 0)
```

> 注意： 请查阅 `CORSConfiguration` 源文件中的文档，获取更多信息和配置项可用的值。


### JSON Config

`CORSMiddleware` 也可以使用包含在你的 Vapor `Config` 目录中的 json 文件来配置。你需要在你项目的 Config 目录中创建一个叫做 `cors.json` 或者 `CORS.json` 文件并且添加要求的 key。

一个例子文件：

```swift
{
    "allowedOrigin": "origin",
    "allowedMethods": "GET,POST,PUT,OPTIONS,DELETE,PATCH",
    "allowedHeaders": ["Accept", "Authorization", "Content-Type", "Origin", "X-Requested-With"]
}

```

> 注意：下面的的 key 是必须的：`allowedOrigin`, `allowedMethods`, `allowedHeaders`。如果没有这些 key，实例化中间件的时候回抛出错误。
>
> 可选的，你也可以指定这些 key： `allowCredentials` (Bool), `cacheExpiration` (Int) 和 `exposedHeaders` ([String])

Afterwards you can add the middleware using the a throwing overload of the initialiser that accepts Vapor's `Config`.

```swift
let drop = Droplet()

do {
	drop.middleware.insert(try CORSMiddleware(configuration: drop.config), at: 0)
} catch {
	fatalError("Error creating CORSMiddleware, please check that you've setup cors.json correctly.")
}
```
