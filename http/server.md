---
currentMenu: http-server
---

# Server

The server is responsible for accepting connections from clients, parsing their requests, and delivering them a response. 

## Default

Starting your Droplet with a default server is simple.

```swift
import Vapor

let drop = Droplet()

drop.run()
```

The default server will bind to host `0.0.0.0` at port `8080`.

## Config

If you are using a `Config/servers.json` file, this is where you can easily change your host and port or even boot multiple servers.

```json
{
    "default": {
        "port": "$PORT:8080",
        "host": "0.0.0.0",
        "securityLayer": "none"
    }
}
```

The default `servers.json` is above. The port with try to resolve the environment variable `$PORT` or fallback to `8080`.

### Multiple

You can start multiple servers in the same application. This is especially useful if you want to boot an `HTTP` and `HTTPS` server side by side.

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

TLS (formerly SSL) can be configured with a variety of different certificate and signature types.

### Verify

Verificiation of hosts and certificates can be disabled. They are enabled by default.

> Note: Be extremely careful when disabling these options.

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

### Signature

#### Self Signed

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

Here is an example `servers.json` file using certificate files with a self signed signature and host verification redundantly set to `true`.

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

Servers can also be configured manually, without configuration files. 

> Note: If servers are configured programatically, they override any config settings.

### Simple

The `run` method on the Droplet takes a dictionary of server configuration objects. The key is the name of the server.

```swift
import Vapor

let drop = Droplet()

drop.run(servers: [
    "default": (host: "vapor.codes", port: 8080, securityLayer: .none)
]
```

### TLS

TLS can also be configured manually, and works similarly to the `servers.json` config files described above.

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