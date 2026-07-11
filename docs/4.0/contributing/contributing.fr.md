# Contribuer à Vapor

Vapor est un projet porté par sa communauté et les contributions des membres de la communauté représentent une part importante du développement de Vapor. Ce guide va vous aider à comprendre le processus de contribution et vous aider à faire vos premiers commits sur Vapor !

Toute contribution que vous apportez est utile ! Même de petites choses comme corriger des fautes de frappe font une grande différence pour les personnes qui utilisent Vapor.

## Code de conduite

Vapor a adopté le Code de conduite de Swift, disponible sur [https://www.swift.org/code-of-conduct/](https://www.swift.org/code-of-conduct/). Tous les contributeurs sont tenus de le respecter.

## Sur quoi travailler

Déterminer sur quoi travailler peut être un gros obstacle quand on débute dans l'open source ! En général, les meilleures choses sur lesquelles travailler sont les issues que vous trouvez ou les fonctionnalités que vous souhaitez. Cela dit, Vapor propose quelques outils pratiques pour vous aider à contribuer.

### Problèmes de sécurité

Si vous découvrez un problème de sécurité et souhaitez le signaler ou aider à le corriger, merci de **ne pas** créer d'issue ni de pull request. Nous avons un processus séparé pour les problèmes de sécurité afin de ne pas exposer de vulnérabilité tant qu'un correctif n'est pas disponible. Envoyez un email à security@vapor.codes ou [consultez cette page](https://github.com/vapor/.github/blob/main/SECURITY.md) pour plus de détails.

### Petits problèmes

Si vous trouvez un petit problème, un bug ou une faute de frappe, n'hésitez pas à créer directement une pull request pour le corriger. Si elle résout une issue ouverte sur l'un des dépôts, vous pouvez la lier dans la pull request via la barre latérale afin que l'issue soit automatiquement fermée lorsque la pull request est fusionnée.

![GitHub Link Issue](../images/github-link-issue.png)

### Nouvelles fonctionnalités

Si vous souhaitez proposer des changements plus importants comme de nouvelles fonctionnalités ou des corrections de bugs qui modifient une quantité significative de code, merci d'ouvrir d'abord une issue ou de poster dans le canal `#development` sur Discord. Cela nous permet d'échanger avec vous sur le changement, car il peut y avoir du contexte à prendre en compte ou nous pouvons vous donner des pistes. Nous ne voulons pas que vous perdiez du temps si une fonctionnalité ne correspond pas à nos plans !

### Les tableaux de Vapor

Si vous souhaitez simplement contribuer sans avoir d'idée précise sur quoi travailler, c'est génial ! Vapor propose quelques tableaux qui peuvent vous aider. Vapor compte environ 40 dépôts activement développés, et parcourir tous ces dépôts pour trouver quelque chose sur quoi travailler n'est pas pratique, c'est pourquoi nous utilisons des tableaux pour les regrouper.

Le premier tableau est le [tableau des premières bonnes issues](https://github.com/orgs/vapor/projects/14) (« good first issue board »). Toute issue de l'organisation GitHub de Vapor étiquetée `good first issue` sera ajoutée à ce tableau pour que vous puissiez la trouver. Ce sont des issues que nous estimons adaptées aux personnes relativement nouvelles sur Vapor, car elles ne nécessitent pas beaucoup d'expérience du code.

Le second tableau est le [tableau d'appel à l'aide](https://github.com/orgs/vapor/projects/13) (« help wanted board »). Il regroupe les issues étiquetées `help wanted`. Ce sont des issues qu'il serait bon de corriger, mais l'équipe principale a actuellement d'autres priorités. Ces issues nécessitent généralement un peu plus de connaissances si elles ne sont pas également marquées `good first issue`, mais elles peuvent constituer des projets amusants sur lesquels travailler !

### Traductions

Le dernier domaine où les contributions sont extrêmement précieuses est la documentation. La documentation dispose de traductions dans plusieurs langues, mais toutes les pages ne sont pas traduites et il y a beaucoup d'autres langues que nous aimerions prendre en charge ! Si vous êtes intéressé pour contribuer à de nouvelles langues ou à des mises à jour, consultez le [README de la documentation](https://github.com/vapor/docs#translating) ou contactez-nous dans le canal `#documentation` sur Discord.

## Processus de contribution

Si vous n'avez jamais travaillé sur un projet open source, les étapes pour contribuer peuvent sembler confuses, mais elles sont en réalité assez simples.

Tout d'abord, forkez Vapor ou le dépôt sur lequel vous souhaitez travailler. Vous pouvez le faire dans l'interface de GitHub, et GitHub propose [d'excellents guides](https://docs.github.com/en/get-started/quickstart/fork-a-repo) sur la manière de procéder.

Vous pouvez ensuite apporter des modifications dans votre fork avec le processus habituel de commit et de push. Une fois prêt à soumettre votre correction, vous pouvez créer une PR vers le dépôt de Vapor. Là encore, GitHub propose [d'excellents guides](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork) sur la manière de procéder.

## Soumettre une pull request

Lorsque vous soumettez une pull request, il y a un certain nombre de choses à vérifier :

* Tous les tests passent
* De nouveaux tests ont été ajoutés pour tout nouveau comportement ou bug corrigé
* Les nouvelles API publiques sont documentées. Nous utilisons DocC pour la documentation de nos API.

Vapor utilise l'automatisation pour réduire la quantité de travail nécessaire pour de nombreuses tâches. Pour les pull requests, nous utilisons le [Vapor Bot](https://github.com/VaporBot) pour générer les releases lorsqu'une pull request est fusionnée. Le corps et le titre de la pull request sont utilisés pour générer les notes de version, alors assurez-vous qu'ils aient du sens et couvrent ce que vous vous attendriez à voir dans des notes de version. Vous trouverez plus de détails dans les [directives de contribution de Vapor](https://github.com/vapor/vapor/blob/main/.github/contributing.md#release-title).
