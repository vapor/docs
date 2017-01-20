---
currentMenu: routing-query-parameters
---

# Query Parameters

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

请求参数要么作为字典访问，要么使用 `extract` 语法访问。后者使用 throws 代替返回一个 optional 值。

## Optional Syntax

Optional 语法是处理 Optional query 参数最容易的方法。

```swift
drop.get("comments") { request in
	if let rating = request.query?["rating"]?.int {
  	return "You requested comments with rating greater than #\(rating)"
  }
  return "You requested all comments"
}
```

## Extract Syntax

Extract 语法在要求必须有对应的 query 参数，如果没有需要抛出异常，这类情况的处理上是很有用的。
要使用这个语法，首先我们要使用 `guard` 确保 query 对象存在。

```swift
drop.get("comments") { request in
        guard let rating = request.query?["rating"]?.int else {
            throw Abort.custom(status: .preconditionFailed, message: "Please include a rating")
        }
  return "You requested comments with rating greater than #\(rating)"
}
```
