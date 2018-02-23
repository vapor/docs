# Existing Vapor 2 users

If you're an established Vapor 2 users, you'll find many things have changed the last release.

### A high level recap

Vapor 3 is now [async and reactive](../async/getting-started.md).
In short, this means less complexity, code and bugs.

This reactive approach cascades throughout the entire ecosystem, resulting in extremely low memory usage with extremely high throughput.
This also makes Vapor 3 highly resistant against Denial of Service attacks by nature.

Aside of that we've made the move to support `Codable`, meaning you can return structs and classes without the need for an intermediary representation.
This cleans up [JSON](../getting-started/content.md) and [Database Models](../fluent/models.md) significantly. Codable and Async go hand-in-hand in the official libraries.

One significant milestone is that we don't rely on OpenSSL on macOS anymore.
Another milestone is the separation between implementation and API.
The entire ecosystem relies on only one C library which can be replaced without impacting existing users.
This includes MySQL, PostgreSQL and MongoDB, which are entirely written in Swift.

Finally, we've improved Vapor's performance beyond all of our own expectations.
Some of our routes are reaching 100'000 requests per second with little to no fluctuations over time.
