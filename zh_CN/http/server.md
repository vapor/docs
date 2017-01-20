---
currentMenu: http-server
---

# Server

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

server 负责接受来自客户端的连接，解析 request，返回对应的 response。

## Default

使用默认的 server 启动你的 Droplet 是简单的。

```swift
import Vapor

let drop = Droplet()

drop.run()
```

默认的 server 将会绑定到主机 `0.0.0.0` 端口 `8080` 上。

## Config

如果你使用 `Config/servers.json` 文件，你能够很容易的改变 host 和 port，甚至多次重启服务器。

```json
{
    "default": {
        "port": "$PORT:8080",
        "host": "0.0.0.0",
        "securityLayer": "none"
    }
}
```

默认的 `servers.json` 如上面所示。port 尝试解析环境变量 `$ PORT` 或回退到 `8080`。

### Multiple

你能够在相同的应用中启动多个 server。如果你想同时启动一个 `HTTP` 和 `HTTPS` 服务器，这是特别有用的。

```json
{
    "plaintext": {
        "port": "80",
        "host": "vapor.codes",
        "securityLayer": "none"
    },
    "secure": {
        "port": "443",
        "host": "vapor.codes",
        "securityLayer": "tls",
        "tls": {
            "certificates": "none",
            "signature": "selfSigned"
        }
    },
}
```

## TLS

TLS（以前是 SSL）可以使用多个不同的证书和签名配置。

### Verify

主机和证书（hosts and certificates）校验可以禁用。默认情况下是启用的。

> 注意：当禁用该选项的时候需要十分小心。

```json
"tls": {
   "verifyHost": false,
   "verifyCertificates": false
}
```

### Certificates

#### None

```json
"tls": {
    "certificates": "none"
}
```

#### Chain

```json
"tls": {
    "certificates": "chain",
    "chainFile": "/path/to/chainfile"
}
```

#### Files

```json
"tls": {
    "certificates": "files",
    "certificateFile": "/path/to/cert.pem",
    "privateKeyFile": "/path/to/key.pem"
}
```

#### Certificate Authority

```json
"tls": {
    "certificates": "ca"
}
```

### 签名 （Signature）

#### 自签名 （Self Signed）

```json
"tls": {
    "signature": "selfSigned"
}
```

#### Signed File

```json
"tls": {
    "signature": "signedFile",
    "caCertificateFile": "/path/to/file"
}
```

#### Signed Directory

```json
"tls": {
    "signature": "signedDirectory",
    "caCertificateDirectory": "/path/to/dir"
}
```

## Example

这是一个 `servers.json` 文件的例子，使用我们自签名的证书文件，并且设置 host 校验为 `true`。

```json
{
    "secure": {
        "port": "8443",
        "host": "0.0.0.0",
        "securityLayer": "tls",
        "tls": {
            "verifyHost": true,
            "certificates": "files",
            "certificateFile": "/vapor/certs/cert.pem",
            "privateKeyFile": "/vapor/certs/key.pem",
            "signature": "selfSigned"
        }
    }
}
```

## Manual

Server 也可以手动配置，不使用配置文件。

> 注意：如果 server 是编程方式配置的，他们将覆盖配置文件中的配置。

### Simple

Droplet 的 `run` 方法可以接收一个服务器配置的 dictionary 参数。key 是服务器的名称。（译者注：下面的 `"default"`）

```swift
import Vapor

let drop = Droplet()

drop.run(servers: [
    "default": (host: "vapor.codes", port: 8080, securityLayer: .none)
]
```

### TLS

TLS 也可以手动配置，和上面介绍的 `servers.json` 文件的使用方式类似。

```swift
import Vapor
import TLS

let drop = Droplet()

let config = try TLS.Config(
    mode: .server,
    certificates: .files(
        certificateFile: "/Users/tanner/Desktop/certs/cert.pem",
        privateKeyFile: "/Users/tanner/Desktop/certs/key.pem",
        signature: .selfSigned
    ),
    verifyHost: true,
    verifyCertificates: true
)

drop.run(servers: [
    "plaintext": ("vapor.codes", 8080, .none),
    "secure": ("vapor.codes", 8443, .tls(config)),
])
````
