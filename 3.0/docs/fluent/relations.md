# Fluent Relations

Relations are logical connections between models.

There are two main categories of relations in Fluent:

* Parent / Child (One-to-Many)
* Siblings (Many-to-Many)

## One-to-Many

In parent / child relations, one parent is directly connected to zero or more children.

Consider the following database schema:

`customer`

| id              | name   |
|-----------------|--------|
| &lt;id type&gt; | string |

`address`

| id              | name   | customer_id   |
|-----------------|--------|--------|
| &lt;id type&gt; | string | &lt;id type&gt; | 

Here each address belongs to a single customer, but each customer may have multiple addresses (i.e. home and work).
This is a one-to-many relationship.

### Parent

To access the customer from their address, we can use the `Parent` relation.
```swift
extension Address{
	let customerID: Identifier
	...
	var resident: Parent<Address, Customer>{
		return parent(\.customerID)
	}
}
```

We can now use this relation to get the resident of the address.
```swift
let customer = try address.resident.get() // Customer?
```

### Children

To access the customer's addresses, we will use the `Children` relation.
```swift
extension Customer{
	var addresses: Children<Customer, Address>{
		return children(\.customerID)
	}
}
```

!!! warning
	You need to use the keypath for variable in the child model that refers to its parent.

	In this case, it is the `customerID` variable defined in the previous section, *not* the parent model's `id` variable.

We can now use this relation to get the array of addresses belonging to the customer.
```swift
let addresses = try customer.addresses.all() // [Address]
```

#### One-to-One

If we wanted to prevent customers from having multiple addresses, we could simply call `first()` on the array returned in the previous example.
Alternatively, a convenience function can be added to change this relation from one-to-many to one-to-one.
```swift
extension Customer{
func address() throws -> Address? {
		return try children().first()
	}
}
```

## Many-to-Many

In sibling relations, a pivot is used as an intermediary to connect one group of models to another group.

Consider the following database schema:

`customer`

| id              | name   |
|-----------------|--------|
| &lt;id type&gt; | string |

`product`

| id              | name   |
|-----------------|--------|
| &lt;id type&gt; | string |

If we wanted to link our customers to the products they have purchased, we would likely use the following pivot table:

`order`

| id              | customer_id   | product_id   | 
|-----------------|--------|--------|
| &lt;id type&gt; | &lt;id type&gt; | &lt;id type&gt; |

This pivot ensures that customers can *purchase* multiple products, but also that products can be *purchased by* multiple customers.
This is a many-to-many relationship.

### Siblings

To represent this many-to-many relationship, the `Siblings` relation is used.

```swift
extension Customer{
	var purchases: Sibling<Customer, Product, Order>{
		return siblings()
	}
}
```

We can now use this relation to get the array of all products the customer has ordered.

```swift
let products = customer.purchases.all() // [Product]
```

!!! tip
	Instead of creating a custom Pivot model (i.e. `Order`), Fluent provides a default [`Pivot`](pivot.md) entity.
