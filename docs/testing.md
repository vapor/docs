# Testing

Vapor includes a module named `XCTVapor` that provides test helpers built on `XCTest`. These testing helpers allow you to send test requests to your Vapor application programmatically or running over an HTTP server.

## Getting Started

To use the `XCTVapor` module, ensure it has been added to your package's test target.

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0")
    ],
    targets: [
        ...
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
```

Then, add `import XCTVapor` at the top of your test files. Create classes extending `XCTestCase` to write test cases.

```swift
import XCTVapor

final class MyTests: XCTestCase {
    func testStub() throws {
    	// Test here.
    }
}
```

Each function beginning with `test` will run automatically when your app is tested. 

### Running Tests

Use `cmd+u` with the `-Package` scheme selected to run tests in Xcode. Use `swift test --enable-test-discovery` to test via the CLI.

## Testable Application

Initialize an instance of `Application` using the `.testing` environment. You must call `app.shutdown()` before this application deinitializes. 

```swift
let app = Application(.testing)
defer { app.shutdown() }
try configure(app)
```

Pass the `Application` to your package's `configure(_:)` method to apply your configuration. Any test-only configurations can be applied after.

### Send Request

To send a test request to your application, use the `test` method.

```swift
try app.test(.GET, "hello") { res in
    XCTAssertEqual(res.status, .ok)
    XCTAssertEqual(res.body.string, "Hello, world!")
}
```

The first two parameters are the HTTP method and URL to request. The trailing closure accepts the HTTP response which you can verify using `XCTAssert` methods. 

For more complex requests, you can supply a `beforeRequest` closure to modify headers or encode content. Vapor's [Content API](content.md) is available on both the test request and response.

```swift
try app.test(.POST, "todos", beforeRequest: { req in
	try req.content.encode(["title": "Test"])
}, afterResponse: { res in
    XCTAssertEqual(res.status, .created)
    let todo = try res.content.decode(Todo.self)
    XCTAssertEqual(todo.title, "Test")
})
```

### Testable Method

Vapor's testing API supports sending test requests programmatically and via a live HTTP server. You can specify which method you would like to use by using the `testable` method.

```swift
// Use programmatic testing.
app.testable(method: .inMemory).test(...)

// Run tests through a live HTTP server.
app.testable(method: .running).test(...)
```

The `inMemory` option is used by default. 

The `running` option supports passing a specific port to use. By default `8080` is used.

```swift
.running(port: 8123)
```
