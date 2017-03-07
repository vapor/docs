---
currentMenu: fluent-fixtures
---

# Fixtures
Sometimes, you may need to prepopulate your database with data. For exemples, you might need insert in your table 'Users' an admin account or a test account.


In a separate file (Database+Fixture.swift):
```swift
extension Database {
    func insertFixtures<T: Entity, S: Sequence>(_ data: S) throws where S.Iterator.Element == T {
        let context = DatabaseContext(self)
        try data.forEach { model in
            let query = Query<T>(self)
            query.action = .create
            query.data = try model.makeNode(context: context)
            try driver.query(query)
        }
    }
}
```

In your model User.swift file
```swift
static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
            users.string("email")
            users.string("password")
        }
        let seedData: [AppUser] = [
                try User(email: "admin@admin.com", rawPassword: "Def4ultPassword?!"),
                try User(email: "test@test.com", rawPassword: "Def4ultPassword?!")
        ]

        try database.insertFixtures(seedData)
 }
 ```
    
