# Authentication

Authentication is the act of verifying a user's identity. This is done through the verification of credentials like a username and password or unique token. Authentication (sometimes called auth/c) is distinct from authorization (auth/z) which is the act of verifying a previously authenticated user's permissions to perform certain tasks.

## Introduction

Vapor's Authentication API provides support for authenticating a user via the `Authorization` header, using [basic](https://tools.ietf.org/html/rfc7617) and [bearer](https://tools.ietf.org/html/rfc6750). It also supports authenticating a user via the data decoded from the [Content](/content.md) API.

Authentication is implemented by creating an `Authenticator` which contains the verification logic. An authenticator is then capable of creating middleware which can be used to protect individual route groups or an entire app. The following authenticator helpers ship with Vapor:

|Protocol|Description|
|-|-|
|`RequestAuthenticator`|Base authenticator capable of creating middleware.|
|`BasicAuthenticator`|Authenticates basic authorization header.|
|`BearerAuthenticator`|Authenticates bearer authorization header.|
|`UserTokenAuthenticator`|Authenticates a token type with associated user.|
|`CredentialsAuthenticator`|Authenticates a credentials payload from the request body.|

If authentication is successful, the authenticator returns the verified user. This user can then be accessed using `req.auth.get(_:)` in routes protected by the authenticator's middleware. If authentication fails, `nil` is returned and the user is not available via `req.auth`. 

## Basic

Basic authorization sends a username and password in the `Authorization` header. The username and password are concatenated with a colon and base-64 encoded. 

```http
GET /me HTTP/1.1
Authorization: Basic dGVzdDpzZWNyZXQ=
``` 

## Bearer

## Credentials

## Fluent