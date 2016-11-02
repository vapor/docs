---
currentMenu: fluent-relation
---

# Relation

Relations allow foreign key based connections between database entities. This is common in SQL-based databases, but can also be used with NoSQL.

Fluent's relations are named as follows:
- Parent (BelongsTo)
- Children (HasMany, HasOne)
- Siblings (ManyToMany, BelongsToMany)

## Parent

The parent relation should be called on an entity that has a foreign key to another entity. For example, assume the following schema:

```
pets
- id
- owner_id
- name
- type

owner
- id
- name
```

Here each pet can have one owner. To access that owner from the pet, call `.parent()`.

```swift
let pet: Pet = ...
let owner = try pet.parent(pet.ownerId, Owner.self).get()
```

The parent method requires the foreign key for the parent as well as the type.

### Convenience

To make requesting a parent easier, a method can be added to the model.

```swift
extension Pet {
    func owner() throws -> Parent<Owner> {
        return try parent(ownerId)
    }
}
```

Since we are extending `Pet`, we no longer need to use `pet.` before the `ownerId`. Furthermore, because we are providing the type information about `Owner` in the return type of the method, we no longer need to pass that as an argument.

The `Parent<T>` type is a queryable object, meaning you could `delete()` the parent, `filter()`, etc.

```swift
try pet.owner().delete()
```

To fetch the parent, you must call `get()`.

```swift
let owner = try pet.owner().get()
```

## Children

`Children` are the opposite side of the `Parent` relationship. Assuming the schema from the previous example, the pets could be retrieved from an owner like so:

```swift
let owner: Owner = ...
let pets = owner.children(Pet.self).all()
```

Here only the type of child is required.

### Convenience

Similarly to `Parent`, convenience methods can be added for children.

```swift
extension Owner {
    func pets() throws -> Children<Pet> {
        return try children()
    }
}
```

Since the type information is clear from the return value, `Pet.self` does not need to be passed to `children()`.

The `Children<T>` is also a queryable object like `Parent<T>`. You can call `first()`, `all()`, `filter()`, etc.

```swift
let coolPets = try owner.pets().filter("type", .in, ["Dog", "Ferret"]).all()
```

## Siblings

`Siblings` work differently from `Children` or `Parent` since they require a `Pivot`.

For an example, let's say we want to allow our pets to have multiple toys. But we also want the toys to be shared by multiple pets. We need a pivot entity for this.

```
pets
- id
- type
- owner_id

toys
- id
- name

pets_toys
- id
- pet_id
- toy_id
```

Here you can see the pivot entity, `pets_toys`, or `Pivot<Pet, Toy>`.

### Convenience

Let's add the convenience methods to `Pet`.

```swift
extension Pet {
    func toys() throws -> Siblings<Toy> {
        return try siblings()
    }
}
```

And the opposite for `Toy`.

```swift
extension Toy {
    func pets() throws -> Siblings<Pet> {
        return try siblings()
    }
}
```

Now you are free to query pets and toys similarly to children.

```swift
let pet: Pet = ...
let toys = pet.toys().all()
```

To create a new many-to-many relationship you can do the following.

```swift

var toy: Toy = ...                      // Create a new toy
try toy.save()                          // Save the toy to the db


var pet: Pet = ...                      // Create a new pet
try pet.save()                          // Save the pet to the db

// Link them together in the db
var pivot = Pivot<Toy, Pet>(toy, pet)   // Create the relationship
try pivot.save()                        // Save the relationship to the db
```

### Preparation

To prepare for a relationship with a `Pivot`, simply add the pivot to the `Droplet`'s preparations.

```swift
let drop = Droplet()
drop.preparations += [
    Toy.self,
    Pet.self,
    Pivot<Toy, Pet>.self
]
```
