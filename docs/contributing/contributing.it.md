# Contribuire a Vapor

Vapor è un progetto gestito dalla community e le contribuzioni dai membri della community formano una parte significante dello sviluppo di Vapor. Questa guida ti aiuterà a capire il processo di contribuzione e aiutarti a fare i tuoi primi commit in Vapor!

Qualsiasi contributo darai sarà utile! Anche le piccole cose come aggiustare errori di battitura fanno la differenza per le persone che usano Vapor.

## Codice di Condotta

Vapor ha adottato il Codice di Condotta di Swift che puoi trovare su [https://www.swift.org/code-of-conduct/](https://www.swift.org/code-of-conduct/). Tutti i contributori devono seguire il codice di condotta.

## Su cosa lavorare

Capire su cosa lavorare può essere un grande ostacolo quando sei agli inizi nell'open source! Di solito le cose migliori su cui lavorare sono problemi che incontri o funzionalità che vuoi. Tuttavia, Vapor ha delle cose utili per aiutarti a contribuire.

### Problemi di sicurezza

Se scopri un problema di sicurezza e vuoi riferirlo o aiutare a risolverlo perfavore **non** creare una issue o una pull request. Abbiamo un processo separato per i problemi di sicurezza per assicurare che non esponiamo vulnerabilità finché una soluzione non è disponibile. Manda una email a security@vapor.codes o [guarda qui](https://github.com/vapor/.github/blob/main/SECURITY.md) per più dettagli.

### Piccoli problemi

Se trovi un piccolo problema, bug o errore di battitura, sentiti libero di procedere e creare una pull request per risolverlo. Se risolve una issue aperta su una qualsiasi delle repo puoi linkarla nella pull request nella barra laterale in modo che la issue venga automaticamente chiusa quando la pull request viene unita.

![GitHub Link Issue](../images/github-link-issue.png)

### Nuove funzionalità

Se vuoi proporre cambiamenti più grandi, come nuove funzionalità o bug fix che cambiano quantità significative di codice, allora per favore apri una issue prima o fai un post nel canale `#development` di Discord. Questo ci permetterà di discutere il cambiamento con te in quanto potrebbe esserci del contesto da aggiungere o delle indicazioni da darti. Non vogliamo farti perdere tempo se una funzionalità non rientra nei nostri piani!

### Bacheca di Vapor

Se vuoi solo contribuire ma non hai idea su cosa lavorare, fantastico! Vapor ha un paio di bacheche che possono aiutarti. Vapor ha circa 40 repository che sono attivamente sviluppate e cercare fra tutte queste per trovare qualcosa su cui lavorare non è fattibile, quindi usiamo le bacheche per aggregarle.

La prima bachecha è la [bacheca delle buone prime issue](https://github.com/orgs/vapor/projects/14). Ogni issue nell'organizzazione GitHub di Vapor che è taggata come `good first issue` sarà aggiunta alla bacheca. Queste sono issue che pensiamo possano essere buone per persone relativamente nuove a Vapor per lavorarci su, in quanto non richiedono molta esperienza sul codice.

La seconda bacheca è la [bacheca del "Cercasi aiuto"](https://github.com/orgs/vapor/projects/13). Questa contiene issue taggate `help wanted`. Queste sono issue che potrebbero essere aggiustate, ma la squadra principale al momento ha altre priorità. Queste issue di solito richiedono un po' più di conoscenza se non sono anche taggate `good first issue`, ma potrebbero essere un progetto divertente su cui lavorare!

### Traduzioni

L'area finale in cui le contribuzioni sono estremamente importanti è la documentazione. La documentazione ha traduzioni per diverse lingue, ma non tutte le pagine sono tradotte e ci sono molte altre lingue che ci piacerebbe supportare! Se sei interessato a contribuire con nuove lingue o aggiornamenti guarda il [README della documentazione](https://github.com/vapor/docs#translating) o fatti sentire nel canale `#documentation` su Discord.

## Processo di Contribuzione

Se non hai mai lavorato ad un progetto open source, i passi per contribuire effettivamente potrebbero sembrare confusionari, ma sono molto semplici.

Primo, forka Vapor o qualsiasi repo sulla quale vuoi lavorare. Puoi farlo nell'interfaccia GitHub e GitHub ha [un'ottima documentazione](https://docs.github.com/en/get-started/quickstart/fork-a-repo) su come farlo.

A questo punto puoi fare cambiamenti nella tua fork con il solito processo di commit e push. Quando sei pronto a presentare i tuoi cambiamenti, puoi creare una PR sulla repo di Vapor. Di nuovo, GitHub ha [un'ottima documentazione](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork) su come farlo.

## Presentare una Pull Request

Quando presenti una pull request ci sono delle cose che dovresti controllare:

* Che tutti i test passino
* Che ci siano nuovi test aggiunti per ogni nuovo comportamento o bug fixato
* Che le nuove API pubbliche siano documentate. Usiamo DocC per la documentazione delle nostre API.

Vapor usa automazioni per ridurre il carico di lavoro richiesto per molti compiti. Per le pull requests, usiamo il [Bot Vapor](https://github.com/VaporBot) per generare release quando una pull request è unita. Il corpo e il titolo della pull request sono usati per generare le note sulla versione, quindi assicurati che abbiano senso e mettici quello che ti aspetti di vedere in una nota sulla versione. Ci sono più dettagli sulle [linee guida alla contribuzione di Vapor](https://github.com/vapor/vapor/blob/main/.github/contributing.md#release-title).
