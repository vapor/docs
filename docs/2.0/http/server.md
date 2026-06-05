# Server

The server is responsible for accepting connections from clients, parsing their requests, and delivering them a response. 

## Default

Starting your Droplet with a default server is simple.

```swift
import Vapor

let drop = try Droplet()
try drop.run()
```

The default server will bind to host `0.0.0.0` at port `8080`.

## Config

If you are using a `Config/server.json` file, this is where you can easily change your host and port.

```json
{
    "port": "$PORT:8080",
    "host": "0.0.0.0",
    "securityLayer": "none"
}
```

The default `server.json` is above. The port with try to resolve the environment variable `$PORT` or fallback to `8080`.

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

Here is an example `server.json` file using certificate files with a self signed signature and host verification redundantly set to `true`.

```json
{
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
```

## Nginx

It is highly recommended that you serve your Vapor project behind Nginx in production. Read more in the [deploy Nginx](../deploy/nginx.md) section.