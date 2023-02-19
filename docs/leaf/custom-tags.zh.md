# 自定义标签

你可以遵循 [`LeafTag`](https://api.vapor.codes/leafkit/documentation/leafkit/leaftag) 协议来创建自定义的 Leaf 标签。

为了演示这一点，让我们看看创建一个 `#now` 标签来打印当前时间戳。标签还支持一个可选参数来指定日期格式。

!!! tip "建议" 
    如果你的自定义标签用来渲染 HTML，你应该使你的自定义标记符合 `UnsafeUnescapedLeafTag`，这样 HTML 就不会被转义。别忘了检查或清除用户的任何输入。

## `LeafTag`

首先创建一个名为 `NowTag` 的类并遵循 `LeafTag` 协议。

```swift
struct NowTag: LeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        ...
    }
}
```

现在我们来实现 `render(_:)` 方法。传递给该方法的 `LeafContext` 参数包含了我们需要的所有内容。

```swift
enum NowTagError: Error {
    case invalidFormatParameter
    case tooManyParameters
}

struct NowTag: LeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        let formatter = DateFormatter()
        switch ctx.parameters.count {
        case 0: formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        case 1:
            guard let string = ctx.parameters[0].string else {
                throw NowTagError.invalidFormatParameter
            }

            formatter.dateFormat = string
        default:
            throw NowTagError.tooManyParameters
	    }
    
        let dateAsString = formatter.string(from: Date())
        return LeafData.string(dateAsString)
    }
}
```

## 配置标签

现在我们已经实现了 `NowTag`，我们只需要告诉 Leaf 就可以了。你可以像这样添加任何标签 - 即使它们来自一个单独的包。你通常在`configure.swift` 中做如下配置：

```swift
app.leaf.tags["now"] = NowTag()
```

就是这样！现在可以在 Leaf 中使用我们的自定义标签了。

```leaf
The time is #now()
```

## 上下文属性

`LeafContext` 包含两个重要的属性。`parameters` 和 `data` 有我们需要的一切。

 - `parameters`： 包含标签参数的数组。
 - `data`：一个字典，包含传递给 `render(_:_:)` 方法作为上下文视图的数据。


### Hello 标签示例

要了解如何使用它，让我们使用这两个属性实现一个简单的 hello 标签。

#### 使用 Parameters

我们可以访问包含名称的第一个参数。

```swift
enum HelloTagError: Error {
    case missingNameParameter
}

struct HelloTag: UnsafeUnescapedLeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        guard let name = ctx.parameters[0].string else {
            throw HelloTagError.missingNameParameter
        }

        return LeafData.string("<p>Hello \(name)</p>")
    }
}
```

```leaf
#hello("John")
```

#### 使用 Data

我们可以通过使用 data 属性中的 ”name“ 键来访问 name 值。

```swift
enum HelloTagError: Error {
    case nameNotFound
}

struct HelloTag: UnsafeUnescapedLeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        guard let name = ctx.data["name"]?.string else {
            throw HelloTagError.nameNotFound
        }

        return LeafData.string("<p>Hello \(name)</p>")
    }
}
```

```leaf
#hello()
```

控制器：

```swift
return try await req.view.render("home", ["name": "John"])
```
