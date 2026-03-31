# Vapor 에 기여하기

Vapor는 커뮤니티 중심의 프로젝트입니다. 그리고, 커뮤니티 멤버들의 기여는 Vapor 개발에서 아주 중요한 부분 있니다. 이 가이드는 Vapor에 기여하는 과정을 이해하고, Vapor에서 여러분이 첫 커밋을 할 수 있도록 도울 것입니다.

여러분의 기여는 어떤 형태든 큰 도움이 될 것입니다. 오타 수정과 같은 작은 기여도 Vapor를 사용하는 사람들에게 큰 차이를 만들어낼 수 있습니다.

## 행동 강령(Code of Conduct)

Vapor는 Swift의 행동 강령을 채택하고 있습니다. Swift 행동 강령은 [https://www.swift.org/code-of-conduct/](https://www.swift.org/code-of-conduct/)에서 확인할 수 있습니다. 모든 기여자분들은 이 행동 강령을 준수해 주시길 바랍니다.

## 무엇을 작업해야 할까요?

오픈 소스에 처음 발을 내디딜 때, 어떤 것으로 작업을 시작할지 결정하는 것은 큰 난관이 될 수 있습니다. 보통 본인이 발견한 문제나 원하는 기능이 좋은 작업이 될 수 있습니다. 하지만, Vapor는 여러분이 기여하는 것을 돕기 위해, 유용한 것들을 준비해 놓았습니다.

### 보안 문제

만약 보안 문제를 발견해서 그것을 알리거나 해결하는 데 도움을 주고 싶다면, **절대로 Issue를 생성하거나 Pull Request를 생성하지 마세요.** 수정 사항이 준비될 때까지 취약점이 노출되지 않도록 보안 문제에 대해서는 별도의 프로세스를 운영하고 있습니다. security@vapor.codes로 이메일을 보내거나 [여기](https://github.com/vapor/.github/blob/main/SECURITY.md)에서 상세 내용을 확인할 수 있습니다.

### 작은 문제들

작은 이슈, 버그 또는 오타를 발견했다면, 부담 갖지 마시고 수정을 위한 Pull Request를 생성해 주세요. 만약 특정 저장소의 Open Issue를 해결하는 PR이라면, 사이드바에서 해당 Issue를 링크해 주세요. PR이 Merge 될 때, 해당 Issue는 자동으로 close 됩니다.

![GitHub Link Issue](../images/github-link-issue.png)

### 새로운 기능

새로운 기능이나 많은 양의 코드를 변경하는 버그 수정을 제안하고 싶다면, 먼저 Issue를 Open 하거나, Discord의 `#development` 채널에 글을 게시해 주세요. 적용이 필요한 특정 맥락(Context)이 있을 수 있거나, 가이드라인을 전달드릴 수도 있기 때문입니다. 채널을 통해서 해당 변경 사항에 관해 논의할 수 있습니다. Vapor의 계획과 맞지 않은 기능을 만드는 데 여러분의 시간을 낭비하는 것을 원하지 않습니다!

### Vapor의 보드들

여러분이 기여를 하고 싶지만 무엇을 해야 할지 아이디어가 떠오르지 않더라도 괜찮습니다! Vapor는 도움을 줄 수 있는 몇 가지 보드를 가지고 있습니다. Vapor에는 활발히 진행 중인 약 40개의 저장소가 있습니다. 이 저장소들을 모두 살펴보는 것은 현실적으로 어렵기 때문에, 관련 정보들을 한 곳에서 보여주는 보드를 활용하고 있습니다.

첫 번째 보드는 [good first issue board](https://github.com/orgs/vapor/projects/14)입니다. Vapor's GitHub org의 Issue 중에는 `good first issue` 태그가 붙은 것들이 있습니다. 이 Issue들은 코드에 대한 많은 경험을 필요로 하지 않기 때문에 Vapor의 입문자들이 작업하기에 적합합니다.

두 번째는 [help wanted board](https://github.com/orgs/vapor/projects/13)입니다. 이 보드는 `help wanted` 라벨이 붙어있는 Issue들을 보여줍니다. 이 Issue들은 수정되면 좋지만 코어(Core) 팀이 현재 우선순위가 높은 다른 곳에 집중하고 있는 상황입니다. 보통 `good first issue`보다는 지식이 조금 더 필요합니다. 하지만 재미있는 프로젝트가 될 것입니다.

### 번역

마지막으로 매우 가치 있는 기여는 바로 문서입니다. 현재 문서에는 여러 가지 언어로 된 번역본들이 있습니다. 하지만 모든 페이지가 번역되어 있지는 않습니다. 우리는 지원하고 싶은 많은 언어가 있습니다. 여러분이 새로운 언어로 기여하거나 업데이트하는데 관심이 있다면, [docs README](https://github.com/vapor/docs#translating)를 확인하거나 디스코드(Discord)에서 `#documentation` 채널을 찾아와 주세요.

## 기여 과정

오픈 소스 프로젝트에 참여해 본 경험이 없다면, 실제의 기여 과정은 조금 혼란스러울 수도 있습니다. 하지만 사실은 꽤 간단합니다.

첫째로, Vapor 또는 작업하고자 하는 저장소를 fork 하세요. GitHub와 GitHub UI에서 fork 할 수 있고, GitHub에는 이것을 위한 [훌륭한 문서](https://docs.github.com/en/get-started/quickstart/fork-a-repo)가 준비되어 있습니다.

fork된 저장소에서 평소처럼 Commit과 Push로 수정할 수 있습니다. 수정사항을 제출할 준비가 되었다면, Vapor 저장소로 PR을 생성할 수 있습니다. 역시나 GitHub에 [훌륭한 문서](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork)가 준비되어 있습니다.

## Pull Request 제출하기

Pull Request를 제출할 때, 다음 사항들을 확인해 주세요.

* 기존의 모든 테스트가 통과해야 합니다.
* 새로운 동작이 추가되거나 버그를 수정했다면, 이에 대한 새로운 테스트가 추가되어야 합니다.
* 새로운 Public API들은 문서화가 필요합니다. 우리는 API 문서화에 DocC를 사용합니다.

Vapor는 많은 작업과 일들을 줄이기 위해 자동화를 사용하고 있습니다. Pull Request의 경우에는 [Vapor Bot](https://github.com/VaporBot)을 사용해서 자동으로 Pull Request을 Merge 하고 Releases를 생성합니다. Pull Request의 제목과 내용은 Release Notes 생성에 사용됩니다. 그러므로, 해당 내용이 명확하고 Release Note에 포함되어야 하는 내용이 적절하게 포함되어 있는지 확인해 주세요. [Vapor 기여 가이드라인](https://github.com/vapor/vapor/blob/main/.github/contributing.md#release-title)에서 더 자세한 내용을 확인할 수 있습니다.
