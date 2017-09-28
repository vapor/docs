# URI

URIs or "Uniform Resource Identifiers" are used for defining a resource.

They consist of the following components:

- scheme
- authority
- path
- query
- fragment

## Creating an URI

URIs can be created from it's initializer or from a String literal.

```swift
let stringLiteralURI: URI = "http://localhost:8080/path"
let manualURI: URI = URI(
    scheme: "http",
    hostname: "localhost",
    port: 8080,
    path: "/path"
)
```

## Scheme

The scheme is used to define the specification used to communicate with the resource.

`http` and `https` are common schemes. They're always followed by `://`, thus `http://`.

Schemes are always *required*.

## Authority

Authorities specify the host to connect to using the scheme.

Hosts are required, and can be represented as IPv4, IPv6 or domain name.

The port is also part of an authority, although it is not required to specify the port. If no port is provided, the default port associated with the scheme will be used.

The `http` will use port `80` and `https` will use `443`, for example.

An example of an authority is `localhost:8080` where the host is `localhost` and port is `8080`.

The host and port are separated by the `:` character.

An authority may contain user information. Such information is before the host and is separated from the host by an `@` character.

`exampleuser@localhost` would make the `exampleuser` string the user info.

Some applications/protocols use the user info to define the credentials used for authentication if the protocol supports it.

## Path

The host can be followed by a `path`. This is not required.

A path starts with a `/`, which indicates the root resource. From here you can specify sub-resources, similar to a filesystem.

### Common naming strategies

A commonly used strategy for naming sub-resources is by specifying them as a category.

`/users/` would specify all entities of type `User`.

`/users/123` could specify the user with the identifier `123` or `/users/test` could specify the user with the username `test`.

`/api/v1/users/test` would specify that you're communicating with an API. The API protocol version is `1`. The user test is being accessed.

## Query

Queries are an optional component that specifies parameters as key-value pairs. Queries often influence the results returned by the server. They're commonly used by the client to access options/settings that influence the server's results.

Queries are prefixed with the character `?` and each individual query key-value pair is separated with an `&` character.

The key and value are separated by an `=` character.

`?order=ascending` would specify the key "order" to equal "ascending".

`?order=ascending&total=10` would in addition to the above specify "total" to be "10".

## Fragments

Fragments are often not used by the server to alter the resource. Instead, they're used to indicate a sub-resource of the accessed resource.

An example would be `/users#admin`.

This would access all users (since it's accessing no specific user) and indicates a focus on the `admin` sub-resource.
