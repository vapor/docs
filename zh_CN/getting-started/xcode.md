---
currentMenu: getting-started-xcode
---

# Xcode

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

你可能已经注意到了 Vapor 和 SwiftPM 项目中不包括 Xcode 项目。事实上，当你使用 SwiftPM 生成 packages 的时候，`.xcodeproj` 文件默认是被忽略的。

这意味着我们不用担心 pbxproj 冲突，并且对于不同平台使用不同的编辑器开发是很友好的。

## Generate Project

### Vapor Toolbox

为了给项目生成 Xcode project， 使用：

```bash
vapor xcode
```

> 如果你希望自动打开 Xcode project， 使用 `vapor xcode -y`

### Manual

手动生成 Xcode project。

```bash
swift package generate-xcodeproj
```

和平常一样打开项目。

## Flags

For many packages with underlying c-dependencies, users will need to pass linker flags during **build** AND **project generation**. Make sure to consult the guides associated with those dependencies. For example:
> 译者注： 不太清楚怎么翻译会更好，如果你有更好的翻译，欢迎更新。

```
vapor xcode --mysql
```

or

```
swift package generate-xcodeproj -Xswiftc -I/usr/local/include/mysql -Xlinker -L/usr/local/lib
```
