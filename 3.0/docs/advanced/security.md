# Security

In web development, security is always important to avoid leaking user data to hackers.
For the purpose of this document I'll split up security in the following subjects:

- Transport Layer
- Protocol Layer
- Application
- Testing
- Post data breach

## Transport

Transport layer security usually comes in the form of TLS (Transport Layer Security), previously named "SSL" (Secure Sockets Layer). When hosting a public service you should always use encryption like this.

## Protocol layer

Many attacks are possible on the protocol layer. TCP read/write attacks such as slowloris and attacks to HTTP. Many attacks are designed to crash servers by overflowing memory and network usage. Vapor has built-in safety mechanisms against all known attacks.

## Application

Application security is (when oversimplified) a question of not writing bugs. So in order to prevent this, let's take a look at how some (security) bugs are written.

### DRY

DRY, short for "Don't Repeat Yourself" it a principle of centralization. Rather than validating security in every route, you should validate security on a global scale. This is most commonly applied using Middlewares.

A basic symptom of repeating yourself is copying and pasting lines of code between routes.

## Testing

Testing code is quite important. Functionality is not necessarily required to test, but authentication and permissions should be tested for sure!

## Post data breach

Writing a perfect, unhackable application is not realistic. You should, and under some laws **must** go the extra mile. Securing information post data breach means encrypting data so that it cannot be deciphered by the hacker.

### Passwords

Passwords are the first and foremost thing to secure. You **must** encrypt passwords in every circumstance. Passwords are encrypted with a "cryptographic hashing function". These hashing functions are specialized in making a unique and almost irreversible result. These hashes should be relatively strong. The harder it is to create a hash, the harder it is to crack the password. Since cracking a password usually means guessing passwords until a match has been found.

#### Salts

A common technique when cracking passwords is to calculate a table with all possible hashes for an algorithm called a "rainbow table". Instead of guessing all options for every user, you create the table once and search the user's hash in this.

This can, however, be avoided by adding a "salt" to your user's passwords. These salts are a string, randomly generated for every individual user (thus unique) which is then mixed in or appended to the existing passwords.

#### Trusted algorithms

BCrypt and PBKDF2 are two algorithms that are known to be resilient to attacks. PBKDF2 is an older algorithm, widely used in the WPA2 WiFi authentication algorithm. BCrypt is a bit newer and more modern.

BCrypt password validation is often simplifier compared to PBKDF2 since PBKDF2 needs the hash and salt to be stored in a separate variable/column for your user whilst BCrypt combines both in a String. BCrypt should use a minimum of 12 for a cost factor.

PBKDF2 is more customizable, being applicable with any and all hashing algorithms. It's a wrapper around any hashign function, whereas BCrypt combines the Hashing algorithm with the rest of the algorithm. PBKDF2 hashes should use a minimum of 10_000 iterations and a strong hashing.
