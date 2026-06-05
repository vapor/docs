# Relations

Fluent relations allow you to relate your models in three different ways:

| Type         | Relations         |
|--------------|-------------------|
| One to One   | Parent / Child    |
| One to Many  | Parent / Children |
| Many to Many | Siblings          |


## One to Many

We'll start with one-to-many since it's the easiest type of relation to understand.

Take the following database schema:

`users`

| id              | name   |
|-----------------|--------|
| &lt;id type&gt; | string |

`pets`

| id              | name   | user_id         |
|-----------------|--------|-----------------|
| &lt;id type&gt; | string | &lt;id type&gt; |

!!! seealso
    Visit the [database preparations](database.md#preparations) guide for more information
    on how to create schema.

Here each pet has exactly one owner (a user) and each owner can have multiple pets. 
This is a one-to-many relationship. One owner has many pets.

!!! tip
    Use the `builder.foreignId()` to create foreign ids like `user_id`. This will automatically
    create foreign key constraints and follow pre-set key naming conventions.

### Children

To access the user's pets, we will use the `Children` relation.

```swift
extension User {
    var pets: Children<User, Pet> {
        return children()
    }
}
```

Imagine the children relation as `Children<Parent, Child>` or `Children<From, To>`.
Here we are relating _from_ the user type _to_ the pet type.

We can now use this relation to get all of the user's pets.

```swift
let pets = try user.pets.all() // [Pet]
```

This will create SQL similar to:

```sql
SELECT * FROM `pets` WHERE `user_id` = '...';
```

Relations work similarly to [queries](query.md).

```swift
let pet = try user.pets.filter("name", "Spud").first()
```

### Parent

To access a pet's owner from the pet, we will use the `Parent` relation.

```swift
extension Pet {
    let userId: Identifier

    ...

    var owner: Parent<Pet, User> {
        return parent(id: userId)
    }
}
```

Imagine the parent relation as `Parent<Child, Parent>` or `Parent<From, To>`.
Here we are relating _from_ the pet type _to_ the parent type.

!!! note
    Notice the `Parent` relation requires an identifier to be passed in. 
    Make sure to load this identifier in your model's `init(row:)` method.

We can now use this relation to get the pet's owner.

```swift
let owner = try pet.owner.get() // User?
```

#### Migration

Adding a parent identifier to the child table can be done using the `.parent()` method on
the schema builder.

```swift
try database.create(Pet.self) { builder in
    ...
    builder.parent(User.self)
}
```

## One to One

One-to-one relations work exactly the same as one-to-many relations. You can use the
code from the previous example and simply call `.first()` and all calls from the parent type.

However, you can add a convenience for doing this. Let's assume we wanted to change the previous
example from one-to-many to one-to-one.

```swift
extension User {
   func pet() throws -> Pet? {
        return try children().first()
   } 
}
```

## Many to Many

Many to many relations require a table in between to store which model is related to which. 
This table is called a pivot table.

You can use any entity you want as a pivot, but Fluent provides a default one called `Pivot`.

Take the following schema.

`pets`

| id              | name   |
|-----------------|--------|
| &lt;id type&gt; | string |

`pet_toy`

| id              | pet_id          | toy_id          |
|-----------------|-----------------|-----------------|
| &lt;id type&gt; | &lt;id type&gt; | &lt;id type&gt; |


`toys`

| id              | name   |
|-----------------|--------|
| &lt;id type&gt; | string |

Here each pet can own many toys and each toy can belong to many pets. This is a many-to-many relationship.

### Siblings

To represent this many-to-many relationship, we will use the `Siblings` relation.

```swift
extension Pet {
    var toys: Siblings<Pet, Toy, Pivot<Pet, Toy>> {
        return siblings()
    }
}
```

Imagine the siblings relations as `Siblings<From, To, Through>`.
Here we are relating _from_ the pet type _to_ the toy type _through_ the pet/toy pivot.

!!! note
    The generic syntax might look a little intimidating at first, but it allows for a very powerful API.

With this relation added on pets, we can fetch a pet's toys.

```swift
let toys = pet.toys.all() // [Toy]
```

The siblings relation works similarly to [queries](query.md) and parent/children relations. 

#### Migration

If you are using a `Pivot` type, you can simply add it to your Droplet's preparation array.

```swift
drop.preparations.append(Pivot<Pet, Toy>.self)
```

If you are using a `Pivot` for your "through" model, it will also have methods for adding and removing models from the relation.

#### Add

To add a new model to the relation, use the `.add()` method.

```swift
try pet.toys.add(toy)
```

!!! note
    The newly created pivot will be returned.

#### Remove

To remove a model from being related, use the `.remove()` method.

```swift
try pet.toys.remove(toy)
```

#### Is Attached

To check if a model is related, use the `.isAttached()` method.

```swift
if try pet.toys.isAttached(to: toy) {
    // it is attached
}
```

#### Custom Through

You can use any entity type as the "through" entity in your siblings relation. 

```swift
extension User {
    var posts: Siblings<User, Post, Comment> {
        return siblings()
    }
}
```

In the above example we are pivoting on the comments entity to retreive all posts the user
has commented on.

As long as the "through" entity has a `user_id` and `post_id`, the siblings relation will work.

!!! note
    If the `Comment `entity does not conform to `PivotProtocol`, the 
    `add`, `remove`, and `isAttached` methods will not be available.
