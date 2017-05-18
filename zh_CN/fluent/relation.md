---
currentMenu: fluent-relation
---

# Relation

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

Relation 允许数据库实体之间有基于外键的连接。这个再 SQL-based 数据库中很平常，但是也可以使用在 NoSQL 中。

Fluent 中的 relation 有如下几种：
- Parent (BelongsTo)
- Children (HasMany, HasOne)
- Siblings (ManyToMany, BelongsToMany)

## Parent

当一个 entity 中使用另外一个 entity 作为外键的时候，使用parent relation。例如：假设有如下的 schema：

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

这里每个 pet 能够有一个所有者。要想在 pet 中访问所有者，调用 `.parent()`。

```swift
let pet: Pet = ...
let owner = try pet.parent(pet.ownerId, Owner.self).get()
```

parent 方法需要参数外键和 parent 的类型。

### Convenience

为了使获取 parent 更加简单，可以在 model 中添加一个方法。

```swift
extension Pet {
    func owner() throws -> Parent<Owner> {
        return try parent(ownerId)
    }
}
```

由于我们已经扩展了 `Pet`，我们不需要在 `ownerId` 之前使用 `pet.`了。（译者注：由 `pet.ownerId` 变成了 `ownerId`）。此外由于我们在方法的返回类型中提供了关于 `Owner` 的类型信息，所以我们也不需要传入它作为一个参数了。

`Parent<T>` 类型是一个可查询的对象（queryable object），意味着你可以在其上调用 `delete()`、`filter()` 等。

```swift
try pet.owner().delete()
```

要获取 parent， 你必须调用 `get()`。

```swift
let owner = try pet.owner().get()
```

## Children

`Children` 是一种与 `Parent`  相反的关系。假设还是前面例子中的 schema，pet 也能够从所有者那里获取到，例如：

```swift
let owner: Owner = ...
let pets = owner.children(Pet.self).all()
```

这里只有 child 的类型是必须的。

### Convenience

与 `Parent` 类似，也可以为 children 添加便利方法。

```swift
extension Owner {
    func pets() throws -> Children<Pet> {
        return try children()
    }
}
```

由于类型信息在返回信息中已经表示的很清晰了，`Pet.self` 不用被传入 `children()` 方法了。

`Children<T>` 也像 `Parent<T>` 一样，是可查询的对象（queryable object）。你能在其上调用  `first()`、 `all()`、 `filter()` 等方法。

```swift
let coolPets = try owner.pets().filter("type", .in, ["Dog", "Ferret"]).all()
```

## Siblings

`Siblings` work differently from `Children` or `Parent` since they require a `Pivot`.
`Siblings` 与 `Children` 和 `Parent` 都不同，因为他要求一个 `Pivot`。

例如：我们允许我们的 pet 有多个 toy，同样我们也希望 toy 能够被多个 pet 分享。对于这个，我们需要一个 pivot entity。

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

这里我们可以看到这个 pivot entity： `pets_toys` 或者 `Pivot<Pet, Toy>`。

### Convenience

让我们为 `Pet` 添加一个便利方法。

```swift
extension Pet {
    func toys() throws -> Siblings<Toy> {
        return try siblings()
    }
}
```

同样为 `Toy` 也添加一个。

```swift
extension Toy {
    func pets() throws -> Siblings<Pet> {
        return try siblings()
    }
}
```

现在你可以类似 children 那样自由的查询 pets 和 toys 了。

```swift
let pet: Pet = ...
let toys = pet.toys().all()
```

要创建一个新的 many-to-many 关系，你能按照如下去做。

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

准备与一个 `Pivot` 的关系，只要添加 pivot 到 `Droplet` 的 preparations 数组中就可以了。

```swift
let drop = Droplet()
drop.preparations += [
    Toy.self,
    Pet.self,
    Pivot<Toy, Pet>.self
]
```
