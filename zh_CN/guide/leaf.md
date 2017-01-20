---
currentMenu: guide-leaf
---

# Leaf

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

欢迎来带 Leaf。Leaf 的目标是成为一个能够更加容易生成 view 的简单的模板语言。这里有许多优秀的模板语言，使用你认为最好的，或许那就是 Leaf。Leaf 的目标如下：

- Small set of strictly enforced rules
- Consistency
- Parser first mentality
- Extensibility


- 很小的一部分强制执行的规则
- 一致性
- Parser first mentality
- 可扩展性

## 语法 （Syntax）
### 结构 （Structure）

Leaf Tag 由4元素组成。
  - Token: `#` 是 Token
  - Name: 一个标志 Tag 的 `string`
  - Parameter List: `()` 能够接受 0 或者更多参数
  - Body(optional): `{}` 必须通过一个空格和 Parameter List 区分开

这4个元素基于它们的实现可以有不同的使用。让我们看一些例子，看看 Leaf 的内建 Tag 怎么被使用：

  - `#()`
  - `#(variable)`
  - `#import("template")`
  - `#export("link") { <a href="#()"></a> }`
  - `#index(friends, "0")`
  - `#loop(friends, "friend") { <li>#(friend.name)</li> }`
  - `#raw() { <a href="#raw">Anything goes!@#$%^&*</a> }`

### 在 HTML 中使用 `#` token （Using the `#` token in HTML)

token 能够被转义。使用 `#()` 或者 `#raw() {}` Tag，在 Leaf 模板中输出 `#`。`#()` => `#`

### 原始 HTML （Raw HTML）

默认所有的 Leaf 输出是被转义的。使用`#raw() {}` Tag可以不转义输出。
`#raw() { <a href="#link">Link</a> }` => `<a href="#link">Link</a>`
> IMPORTANT!  Make sure you are not using the `#raw() {}` Tag with user input.
> IMPORTANT! 确保你没有使用 `#raw() {}` Tag 带有用户的输入。

### Chaining

两个 token：`##`  表明这是一个 chain。它能够在任何标准 Tag 上使用。如果前面的 Tag 失败了，这个 chained Tag 将会被给一个机会去运行。

```
#if(hasFriends) ##embed("getFriends")
```

### Leaf 的内建 Tag (Leaf's built-in Tags)

#### Token: `#()`

```
#() #()hashtags #()FTW => # #Hashtags #FTW
```

#### Raw: `#raw() {}`

```
#raw() {
    Do whatever w/ #'s here, this code won't be rendered as leaf document and is not escaped.
    It's a great place for things like Javascript or large HTML sections.
}
```

#### Equal: `#equal(lhs, rhs) {}`

```
#equal(leaf, leaf) { Leaf == Leaf } => Leaf == Leaf
#equal(leaf, mustache) { Leaf == Mustache } =>
```

#### Variable: `#(variable)`

```
Hello, #(name)!
```

#### Loop: `#loop(object, "index")`

```
#loop(friends, "friend") {
  Hello, #(friend.name)!
}
```
#### Index: `#loop(object, "index")`

```
Hello, #index(friends, "0")!
```

#### If - Else: `#if(bool) ##else() { this }`

```
#if(entering) {
  Hello, there!
} ##if(leaving) {
  Goodbye!
} ##else() {
  I've been here the whole time.
}
```

#### Import: `#import("template")`
#### Export: `#export("template") { Leaf/HTML }`
#### Extend: `#extend("template")`
#### Embed: `#embed("template")`

> 当你使用这些 Layout Tag 的时候，可以省略这些文件的 .leaf 后缀名。

```
/// base.leaf
<!DOCTYPE html>
#import("html")

/// html.leaf
#extend("base")

#export("html") { <html>#embed("body")</html> }

/// body.leaf
<body></body>
```

Leaf renders `html.leaf` as:

```
<!DOCTYPE html>
<html><body></body></html>
```

### 自定义 Tag （Custom Tags）

Look at the existing tags for advanced scenarios, let's look at a basic example by creating `Index` together. This tag will take two arguments, an array, and an index to access.
为已经存在的 tag 添加高级使用场景，让我们通过创建 `Index` 看一个基础的例子。这个 tag 将会接受两个参数： 一个数组、一个想要访问的索引：

```swift
class Index: BasicTag {
  let name = "index"

  func run(arguments: [Argument]) throws -> Node? {
    guard
      arguments.count == 2,
      let array = arguments[0].value?.nodeArray,
      let index = arguments[1].value?.int,
      index < array.count
    else { return nil }
        return array[index]
    }
}
```

我们可以在 `main.swift` 通过如下代码注册这个 Tag：

```swift
if let leaf = drop.view as? LeafRenderer {
    leaf.stem.register(Version())
}
```

像我们在 [上面](#index).那样使用它。

> 注意：在 Tag 名字中使用非字母数字符号是 **强烈不建议的**，并且在未来的版本中可能会被允许。

## 语法高亮 （Syntax Highlighting）

### Atom

[language-leaf](https://atom.io/packages/language-leaf) by ButkiewiczP

### Xcode
It is not currently possible to implement Leaf Syntax Highlighting in Xcode, however, using Xcode's HTML Syntax Coloring can help a bit. Select one or more Leaf files and then choose Editor > Syntax Coloring > HTML.  Your selected Leaf files will now use Xcode's HTML Syntax Coloring.  Unfortunately the usefulness of this is limited because this association will be removed when `vapor xcode` is run.

There appears to be a way to [make Xcode file associations persist](http://stackoverflow.com/questions/9050035/how-to-make-xcode-recognize-a-custom-file-extension-as-objective-c-for-syntax-hi) but that requires a bit more kung-fu.


### Visual Studio Code

[vscode-html-leaf](https://marketplace.visualstudio.com/items?itemName=Francisco.html-leaf) by FranciscoAmado

### CLion & AppCode

Some preliminary work has been done to implement a Leaf Plugin for CLion & AppCode but lack of skill and interest in Java has slowed progress! If you have IntelliJ SDK experience and want to help with this, message Tom Holland on [Vapor Slack](http://vapor.team)
