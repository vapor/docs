# Vaporへの貢献 {#contributing-to-vapor}

Vaporはコミュニティ主導のプロジェクトであり、コミュニティメンバーからの貢献がVaporの開発の大きな部分を占めています。このガイドは、貢献プロセスを理解し、Vaporで最初のコミットを行うのに役立ちます！

どんな貢献も有用です！タイポの修正のような小さなことでも、Vaporを使用する人々にとって大きな違いをもたらします。

## 行動規範 {#code-of-conduct}

VaporはSwiftの行動規範を採用しており、[https://www.swift.org/code-of-conduct/](https://www.swift.org/code-of-conduct/)で確認できます。すべての貢献者は行動規範に従うことが期待されています。

## 何に取り組むか {#what-to-work-on}

何に取り組むかを決めることは、オープンソースを始める際の大きなハードルになることがあります！通常、最も良いのは自分が見つけた問題や欲しい機能に取り組むことです。しかし、Vaporには貢献を助けるための便利なものがあります。

### セキュリティの問題 {#security-issues}

セキュリティの問題を発見し、報告または修正を手伝いたい場合は、イシューを立てたりプルリクエストを作成したり**しないでください**。脆弱性を修正が利用可能になるまで公開しないよう、セキュリティの問題には別のプロセスがあります。security@vapor.codesにメールするか、詳細については[こちら](https://github.com/vapor/.github/blob/main/SECURITY.md)をご覧ください。

### 小さな問題 {#small-issues}

小さな問題、バグ、またはタイポを見つけた場合は、遠慮なくプルリクエストを作成して修正してください。いずれかのリポジトリでオープンなイシューを解決する場合は、サイドバーでプルリクエストにリンクして、プルリクエストがマージされたときにイシューが自動的にクローズされるようにできます。

![GitHub Link Issue](../images/github-link-issue.png)

### 新機能 {#new-features}

新機能や大量のコードを変更するバグ修正のような大きな変更を提案したい場合は、まずイシューを開くか、Discordの`#development`チャンネルに投稿してください。これにより、適用する必要があるコンテキストがあるかもしれませんし、ヒントを提供できるため、変更について議論できます。機能が私たちの計画に合わない場合、時間を無駄にしてほしくありません！

### Vaporのボード {#vapors-boards}

貢献したいけれど何に取り組むかのアイデアがない場合、それは素晴らしいことです！Vaporには役立ついくつかのボードがあります。Vaporには積極的に開発されている約40のリポジトリがあり、それらすべてを見て何か取り組むものを見つけるのは実用的ではないため、ボードを使用してこれらを集約しています。

最初のボードは[good first issueボード](https://github.com/orgs/vapor/projects/14)です。VaporのGitHub組織内で`good first issue`タグが付けられたイシューは、見つけやすいようにボードに追加されます。これらは、コードの経験をあまり必要としないため、Vaporに比較的新しい人が取り組むのに良いと思われるイシューです。

2番目のボードは[help wantedボード](https://github.com/orgs/vapor/projects/13)です。これは`help wanted`ラベルが付いたイシューを取り込みます。これらは修正するのに良いイシューですが、コアチームは現在他の優先事項があります。これらのイシューは`good first issue`とマークされていない場合、通常もう少し知識が必要ですが、楽しいプロジェクトになる可能性があります！

### 翻訳 {#translations}

貢献が非常に価値のある最後の分野はドキュメントです。ドキュメントには複数の言語の翻訳がありますが、すべてのページが翻訳されているわけではなく、サポートしたい言語がまだたくさんあります！新しい言語の貢献や更新に興味がある場合は、[docs README](https://github.com/vapor/docs#translating)を参照するか、Discordの`#documentation`チャンネルで連絡してください。

## 貢献プロセス {#contributing-process}

オープンソースプロジェクトに取り組んだことがない場合、実際に貢献する手順は混乱する可能性がありますが、実際にはとても簡単です。

まず、Vaporまたは作業したいリポジトリをフォークします。これはGitHub UIで行うことができ、GitHubには[これを行う方法に関する優れたドキュメント](https://docs.github.com/ja/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo)があります。

その後、通常のコミットとプッシュのプロセスで、フォークで変更を加えることができます。修正を提出する準備ができたら、VaporのリポジトリにPRを作成できます。ここでも、GitHubには[これを行う方法に関する優れたドキュメント](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork)があります。

## プルリクエストの提出 {#submitting-a-pull-request}

プルリクエストを提出する際には、確認すべきことがいくつかあります：

* すべてのテストがパスすること
* 新しい動作やバグ修正のための新しいテストが追加されていること
* 新しいパブリックAPIがドキュメント化されていること。APIドキュメントにはDocCを使用しています。

Vaporは多くのタスクに必要な作業量を減らすために自動化を使用しています。プルリクエストでは、[Vapor Bot](https://github.com/VaporBot)を使用して、プルリクエストがマージされたときにリリースを生成します。プルリクエストの本文とタイトルはリリースノートの生成に使用されるため、それらが意味をなし、リリースノートで期待される内容をカバーしていることを確認してください。[Vaporの貢献ガイドライン](https://github.com/vapor/vapor/blob/main/.github/contributing.md#release-title)に詳細があります。