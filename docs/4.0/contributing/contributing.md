# Contributing to Vapor

Vapor is a community-driven project and contributions from community members form a significant amount of development of Vapor. This guide will help you understand the contribution process and help you make your first commits in Vapor!

Any contribution you make is useful! Even small things like fixing typos make a big difference to people using Vapor.

## Code of Conduct

Vapor has adopted Swift's Code of Conduct which can be found at [https://www.swift.org/code-of-conduct/](https://www.swift.org/code-of-conduct/). All contributors are expected to follow the code of conduct.

## What to work on

Working out what to work on can be a big hurdle when it comes to getting started in open source! Usually the best things to work on are issues you find or features you want. However, Vapor has some handy things to help you contribute.

### Security Issues

If you discover a security issue and want to report it or help fix it please **do not** raise an issue or create a pull request. We have a separate process for security issues to ensure we don't expose vulnerability until a fix is available. Email security@vapor.codes or [see here](https://github.com/vapor/.github/blob/main/SECURITY.md) for more details.

### Small issues

If you find a small issue, bug or typo, then feel free to go ahead and create a pull request to fix it. If it resolves an open issue on any of the repos then you can link it in the pull request in the sidebar so the issue is automatically closed when the pull request is merged.

![GitHub Link Issue](../images/github-link-issue.png)

### New features

If you want to propose larger changes like new features or bug fixes that change significant amounts of code then please either open an issue first or post in the `#development` channel in Discord. This enables us to discuss the change with you as there might be some context we need to apply or we can give you pointers. We don't want you wasting time if a feature doesn't fit in with our plans!

### Vapor's Boards

If you just want to contribute but don't have an idea of what to work on, that's awesome! Vapor has a couple of boards that can help. Vapor has around 40 repositories that are actively developed and looking through them all to find something to work on is not practical so we use boards to aggregate these.

The first board is the [good first issue board](https://github.com/orgs/vapor/projects/14). Any issue in Vapor's GitHub org that's tagged with `good first issue` will be added to the board for you to find. These are issues that we think will be good for people relatively new to Vapor to work on as they don't require much experience of the code.

The second board is the [help wanted board](https://github.com/orgs/vapor/projects/13). This pulls in issues labelled `help wanted`. These are issues that could be good to fix but the core team currently has other priorities. These issues usually require a bit more knowledge if they aren't also marked with `good first issue`, but they could be fun projects to work on!

### Translations

The final area where contributions are extremely valuable is the documentation. The docs have translations for multiple languages but not every page is translated and there are lots more languages we'd like to support! If you're interested in contributing new languages or updates see the [docs README](https://github.com/vapor/docs#translating) or reach out in the `#documentation` channel on Discord.

## Contributing Process

If you've never worked on an open source project, the steps to actual contribute can be confusing but they're pretty simple.

First, fork Vapor or whichever repo you want to work in. You can do this in the GitHub UI and GitHub has [some excellent docs](https://docs.github.com/en/get-started/quickstart/fork-a-repo) on how to do this.

You can then make changes in your fork with the usual commit and push process. Once you're ready to submit your fix, you can create a PR onto Vapor's repo. Again, GitHub has [excellent docs](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork) on how to do this.

## Submitting a Pull Request

When submitting a pull request there are number of things you should check:

* All the tests pass
* New tests added for any new behavior or bugs fixed
* New public APIs are documented. We use DocC for our API documentation.

Vapor uses automation to reduce the amount of work needed for many tasks. For pull requests, we use the [Vapor Bot](https://github.com/VaporBot) to generate releases when a pull request is merged. The pull request body and title are used to generate the release notes, so make sure that they make sense and cover what you'd expect to see in release notes. We have more details on [Vapor's contributing guidelines](https://github.com/vapor/vapor/blob/main/.github/contributing.md#release-title).
