# 为 Vapor 做贡献

Vapor 是一个由社区驱动的项目，社区成员的贡献构成了 Vapor 开发工作中相当大的一部分。本指南将帮助你了解贡献流程，并帮助你在 Vapor 中完成你的第一次提交！

你所做的任何贡献都是有用的！即使是修复拼写错误这样的小事，也能为使用 Vapor 的人们带来很大的帮助。

## 行为准则

Vapor 采用了 Swift 的行为准则，可以在 [https://www.swift.org/code-of-conduct/](https://www.swift.org/code-of-conduct/) 找到。所有贡献者都应遵守该行为准则。

## 可以做些什么

在开源项目中刚开始时，想清楚要做什么可能是一个不小的障碍！通常最好的工作对象是你发现的问题或你想要的功能。不过，Vapor 有一些实用的工具可以帮助你参与贡献。

### 安全问题

如果你发现了一个安全问题，并想要报告或帮助修复它，请**不要**创建 issue 或提交 pull request。我们为安全问题设置了单独的处理流程，以确保在修复方案可用之前不会暴露漏洞。请发送邮件至 security@vapor.codes，或[查看这里](https://github.com/vapor/.github/blob/main/SECURITY.md)了解更多详情。

### 小问题

如果你发现了一个小问题、bug 或拼写错误，欢迎直接提交 pull request 来修复它。如果它解决了任何仓库中的一个已有 issue，你可以在 pull request 的侧边栏中链接该 issue，这样当 pull request 被合并时该 issue 会被自动关闭。

![GitHub Link Issue](../images/github-link-issue.png)

### 新功能

如果你想提出较大的改动，比如新功能或会修改大量代码的 bug 修复，请先创建一个 issue，或者在 Discord 的 `#development` 频道中发帖。这样可以让我们和你一起讨论这项改动，因为其中可能涉及一些我们需要考虑的背景信息，或者我们可以给你一些指引。如果某个功能不符合我们的计划，我们不希望你白白浪费时间！

### Vapor 的看板

如果你只是想做贡献，但还没有想好要做什么，那太棒了！Vapor 有几个看板可以帮到你。Vapor 有大约 40 个正在积极开发的仓库，逐一浏览它们来寻找可以做的事情并不现实，因此我们使用看板来汇总这些内容。

第一个看板是 [good first issue 看板](https://github.com/orgs/vapor/projects/14)。Vapor 的 GitHub 组织中任何被标记为 `good first issue` 的 issue 都会被添加到这个看板中供你查找。这些是我们认为适合刚接触 Vapor 不久的人来处理的 issue，因为它们不需要太多对代码的经验。

第二个看板是 [help wanted 看板](https://github.com/orgs/vapor/projects/13)。这里汇集了标记为 `help wanted` 的 issue。这些是可以修复但核心团队目前有其他优先事项的 issue。如果这些 issue 没有同时标记为 `good first issue`，通常需要多一些相关知识，但它们可能是有趣的项目，值得投入！

### 翻译

另一个贡献非常有价值的领域是文档。文档已经支持多种语言的翻译，但并非每个页面都已翻译，而且还有很多我们希望支持的语言！如果你有兴趣贡献新的语言或更新翻译，请查看 [docs README](https://github.com/vapor/docs#translating)，或者在 Discord 的 `#documentation` 频道中联系我们。

## 贡献流程

如果你从未参与过开源项目，实际贡献的步骤可能会让人感到困惑，但其实非常简单。

首先，fork Vapor 或你想参与的任何仓库。你可以在 GitHub 界面中完成这一步，GitHub 有[一些出色的文档](https://docs.github.com/en/get-started/quickstart/fork-a-repo)介绍如何操作。

之后，你可以在你的 fork 中按照常规的 commit 和 push 流程进行修改。当你准备好提交修复方案时，可以创建一个指向 Vapor 仓库的 PR。同样，GitHub 也有[出色的文档](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork)介绍如何操作。

## 提交 Pull Request

在提交 pull request 时，有几件事情你应该检查：

* 所有测试都通过
* 为任何新增行为或已修复的 bug 添加了新的测试
* 新的公共 API 已经过文档说明。我们使用 DocC 来编写 API 文档。

Vapor 使用自动化手段来减少许多任务所需的工作量。对于 pull request，我们使用 [Vapor Bot](https://github.com/VaporBot) 在 pull request 被合并时生成发布说明。pull request 的正文和标题会被用来生成发布说明，所以请确保它们表意清晰，并涵盖你希望在发布说明中看到的内容。关于此项内容，我们在 [Vapor 的贡献指南](https://github.com/vapor/vapor/blob/main/.github/contributing.md#release-title)中有更详细的说明。
