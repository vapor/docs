# Using JWT

JSON Web Tokens are a great tool for implementing _decentralized_ authentication and authorization. Once you are finished configuring your app to use the JWT package (see [JWT &rarr; Getting Started](getting-started.md)), you are ready to begin using JWTs in your app.

## Structure

Like other forms of token-based auth, JWTs are sent using the bearer authorization header. 

```http
GET /hello HTTP/1.1
Authorization: Bearer <token>
...
```

In the example HTTP request above, `<token>` would be replaced by the serialized JWT. [jwt.io](https://jwt.io) hosts an online tool for parsing and serializing JWTs. We will use that tool to create a token for testing.

![JWT.io](https://user-images.githubusercontent.com/1342803/44101613-ce328e04-9fb5-11e8-9aed-2d9900d0c40c.png)

### Header

The header is mainly used to specify which algorithm was used to generate the token's signature. This is used by the accepting app to verify the token's authenticity.

Here is the raw JSON data for our header:

```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

### Payload

The payload is where you store information to identify the authenticated user. You can store any data you want here, but be careful not to store too much as some web browsers limit HTTP header sizes. 

The payload is also where you store _claims_. These standardized key / value pairs that many JWT implementations can recognize and act on automatically. See a full list of supported claims in [RFC 7519 &sect; 4.1](https://tools.ietf.org/html/rfc7519#section-4.1).

```json
{
  "id": 42,
  "name": "Vapor Developer"
}
```

### Secret

Last but not least is the secret key used to sign the JWT. For this example, we are using the `HS256` algorithm (specified in the JWT header). This algorithm uses a single secret key to sign and verify:

```
secret
```

Other algorithms, like RSA, use asymmetric (public and private) keys.

### Serialized

Finally, here is our fully serialized token. This will be sent via the bearer authorization header. 

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6NDIsIm5hbWUiOiJWYXBvciBEZXZlbG9wZXIifQ.__Dm_tr1Ky2VYhZNoN6XpEkaRHjtRgaM6HdgDFcc9PM
```

Each segment is separated by a `.`. The overall structure of the token is the following:

```
<header>.<payload>.<signature>
```

Note that the header and payload segments are simply base64-url encoded JSON. It is important to remember that all information your store in a normal JWT is publically readable.


## Parse

First, let's take a look at how to parse and verify incoming JWTs. 
