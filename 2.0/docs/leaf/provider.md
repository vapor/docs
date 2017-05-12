# Leaf Provider

After you've [added the Leaf Provider package](package.md) to your project, setting the provider up in code is easy.

## Add to Droplet

First, register the `LeafProvider.Provider` with your Droplet.

```swift
import Vapor
import LeafProvider

let config = try Config()
try config.addProvider(LeafProvider.Provider.self)

let drop = try Droplet(config)

...
```

## Configure Droplet

Once the provider is added to your Droplet, you can configure your Droplet to use the Leaf view renderer.

`Config/droplet.json`

```json
{
    ...,
    "view": "leaf",
    ...
}
```

!!! seealso
	Learn more about configuration files in the [Settings guide](../settings/config.md).

## Manual

You can also set the `drop.view` property manually if you want to hardcode your view renderer.

```swift
import Vapor
import LeafProvider

let drop = try Droplet()

drop.view = LeafRenderer(viewsDir: drop.viewsDir)
```

## Done

Next time you boot your application, your views will be rendered using Leaf.
