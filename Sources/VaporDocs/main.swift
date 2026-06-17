import Kiln

// Vapor's documentation site, ported from MkDocs (`mkdocs.yml`) to Kiln.
// Content still lives under `docs/` using the same locale-suffix layout
// (`index.de.md`, …). Run with `swift run VaporDocs`; output goes to `site/`.

let languages: [Language] = [
    Language(
        .english,
        isDefault: true,
        localisation: .init(
            searchPlaceholder: "Quick search",
            tableOfContentsTitle: "Table of contents"
        )
    ),

    Language(
        .german,
        siteName: "Vapor Dokumentation",
        description: "Vapors Dokumentation (Web-Framework für Swift).",
        navTranslations: [
            "Advanced": "Erweitert",
            "Authentication": "Authentifzierung",
            "Basics": "Grundlagen",
            "Commands": "Befehle",
            "Content": "Modelbindung",
            "Contributing": "Mitwirken",
            "Contributing Guide": "Leitfaden für Beiträge",
            "Deploy": "Bereitstellung",
            "Environment": "Umgebung",
            "Errors": "Fehlerbehandlung",
            "Files": "Dateien",
            "Folder Structure": "Verzeichnis",
            "Getting Started": "Einführung",
            "Hello, world": "Hallo Welt",
            "Install": "Installation",
            "Logging": "Protokollierung",
            "Migrations": "Migrationen",
            "Model": "Models",
            "Overview": "Übersicht",
            "Query": "Abfrage",
            "Relations": "Beziehungen",
            "Security": "Sicherheit",
            "Services": "Dienste",
            "Sessions": "Sitzungen",
            "Testing": "Testen",
            "Transactions": "Transaktionen",
            "Validation": "Validierung",
            "Welcome": "Begrüßung",
        ],
        localisation: .init(
            searchPlaceholder: "Suchen",
            searchNoResults: "Keine Ergebnisse gefunden",
            tableOfContentsTitle: "Auf dieser Seite",
            previousPage: "Zurück",
            nextPage: "Weiter",
            editPage: "Diese Seite bearbeiten",
            fallbackTitle: "Übersetzung nicht verfügbar",
            fallbackMessage: "Diese Seite wurde noch nicht übersetzt, daher wird die Standardsprache angezeigt.",
            notFoundTitle: "Seite nicht gefunden",
            notFoundMessage: "Die gesuchte Seite wurde möglicherweise verschoben, umbenannt oder existiert nicht.",
            notFoundLink: "Zurück zur Startseite",
            toggleNavigation: "Navigation umschalten",
            toggleColourScheme: "Farbschema umschalten"
        )
    ),

    Language(
        .spanish,
        siteName: "Documentación de Vapor",
        description: "Documentación de Vapor (framework web para Swift).",
        navTranslations: [
            "APNS": "APNS",
            "Advanced": "Avanzado",
            "Async": "Asincronía",
            "Authentication": "Autenticación",
            "Basics": "Fundamentos",
            "Client": "Cliente",
            "Commands": "Comandos",
            "Content": "Content",
            "Contributing": "Colaborar",
            "Contributing Guide": "Guía para Colaborar",
            "Controllers": "Controladores",
            "Crypto": "Criptografía",
            "Custom Tags": "Etiquetas Personalizadas",
            "Deploy": "Desplegar",
            "Environment": "Entorno",
            "Errors": "Errores",
            "Files": "Ficheros",
            "Fluent": "Fluent",
            "Folder Structure": "Estructura de Carpetas",
            "Getting Started": "Comenzando",
            "Hello, world": "Hola, mundo",
            "Install": "Instalación",
            "JWT": "JWT",
            "Leaf": "Leaf",
            "Logging": "Logging",
            "Middleware": "Middleware",
            "Migrations": "Migraciones",
            "Model": "Modelo",
            "Overview": "Presentación",
            "Passwords": "Contraseñas",
            "Query": "Consultas",
            "Queues": "Colas",
            "Redis": "Redis",
            "Relations": "Relaciones",
            "Release Notes": "Notas de Versiones",
            "Request": "Solicitud",
            "Routing": "Routing",
            "Schema": "Esquema",
            "Security": "Seguridad",
            "Server": "Servidor",
            "Services": "Servicios",
            "Sessions": "Sesiones",
            "SwiftPM": "SwiftPM",
            "Testing": "Testing",
            "Transactions": "Transacciones",
            "Upgrading": "Actualizar",
            "Validation": "Validación",
            "Version (4.0)": "Versión (4.0)",
            "WebSockets": "WebSockets",
            "Welcome": "Bienvenido",
            "Xcode": "Xcode",
        ],
        localisation: .init(
            searchPlaceholder: "Buscar",
            searchNoResults: "No se encontraron resultados",
            tableOfContentsTitle: "En esta página",
            previousPage: "Anterior",
            nextPage: "Siguiente",
            editPage: "Editar esta página",
            fallbackTitle: "Traducción no disponible",
            fallbackMessage: "Esta página aún no se ha traducido, por lo que se muestra el idioma predeterminado.",
            notFoundTitle: "Página no encontrada",
            notFoundMessage: "Es posible que la página que buscas se haya movido, cambiado de nombre o que nunca haya existido.",
            notFoundLink: "Volver a la página de inicio",
            toggleNavigation: "Alternar la navegación",
            toggleColourScheme: "Alternar el esquema de color"
        )
    ),

    Language(
        .french,
        siteName: "Documentation du framework Vapor",
        description: "Documentation du framework Vapor (développez pour le web en Swift).",
        navTranslations: [
            "Advanced": "Avancé",
            "Async": "Code asynchrone et concurrence",
            "Authentication": "Authentification",
            "Basics": "Les bases",
            "Client": "Client HTTP",
            "Commands": "Commandes",
            "Content": "Décoder et encoder du contenu",
            "Contributing": "Contribuer",
            "Contributing Guide": "Guide de contribution",
            "Controllers": "Les contrôleurs",
            "Custom Tags": "Tags customisés",
            "Errors": "Gestion des erreurs",
            "Deploy": "Deployer",
            "Environment": "Environnement, configuration et variables",
            "Files": "Fichiers",
            "Folder Structure": "Structure des dossiers",
            "Getting Started": "Premiers pas",
            "Hello, world": "Hello, world",
            "Install": "Installation",
            "Logging": "Journalisation, logs",
            "Migrations": "Migrations",
            "Overview": "Aperçu",
            "Passwords": "Mots de passe",
            "Query": "Query",
            "Queues": "Files d'attente",
            "Relations": "Relations",
            "Release Notes": "Notes de Version",
            "Request": "Requête",
            "Routing": "Le routage",
            "Schema": "Schema",
            "Security": "Securité",
            "Services": "Services",
            "Sessions": "Sessions",
            "Testing": "Test",
            "Transactions": "Transactions",
            "Upgrading": "Mettre à jour",
            "Validation": "La validation de données",
            "Version (4.0)": "Version (4.0)",
            "Welcome": "Bienvenue",
        ],
        localisation: .init(
            searchPlaceholder: "Rechercher",
            searchNoResults: "Aucun résultat trouvé",
            tableOfContentsTitle: "Sur cette page",
            previousPage: "Précédent",
            nextPage: "Suivant",
            editPage: "Modifier cette page",
            fallbackTitle: "Traduction indisponible",
            fallbackMessage: "Cette page n'a pas encore été traduite, la langue par défaut est donc affichée.",
            notFoundTitle: "Page introuvable",
            notFoundMessage: "La page que vous recherchez a peut-être été déplacée, renommée ou n'a jamais existé.",
            notFoundLink: "Retour à la page d'accueil",
            toggleNavigation: "Afficher/masquer la navigation",
            toggleColourScheme: "Changer de thème de couleur"
        )
    ),

    Language(
        .italian,
        siteName: "Documentazione di Vapor",
        description: "Documentazione di Vapor (framework web per Swift).",
        navTranslations: [
            "APNS": "APNS",
            "Advanced": "Avanzate",
            "Async": "Asincrono",
            "Authentication": "Autenticazione",
            "Basics": "Basi",
            "Client": "Client",
            "Commands": "Comandi",
            "Content": "Contenuto",
            "Contributing": "Contribuire",
            "Contributing Guide": "Guida alla Contribuzione",
            "Controllers": "Controller",
            "Crypto": "Crittografia",
            "Custom Tags": "Tag Personalizzati",
            "Deploy": "Deploy",
            "Environment": "Ambiente",
            "Errors": "Errori",
            "Files": "File",
            "Fluent": "Fluent",
            "Folder Structure": "Struttura della Cartella",
            "Getting Started": "Inizio",
            "Hello, world": "Ciao, mondo",
            "Install": "Installazione",
            "JWT": "JWT",
            "Leaf": "Leaf",
            "Logging": "Logging",
            "Middleware": "Middleware",
            "Migrations": "Migrazioni",
            "Model": "Modello",
            "Overview": "Panoramica",
            "Passwords": "Password",
            "Query": "Query",
            "Queues": "Code",
            "Redis": "Redis",
            "Relations": "Relazioni",
            "Release Notes": "Note sulla Versione",
            "Routing": "Routing",
            "Schema": "Schema",
            "Security": "Sicurezza",
            "Server": "Server",
            "Services": "Servizi",
            "Sessions": "Sessioni",
            "SwiftPM": "SwiftPM",
            "Testing": "Test",
            "Transactions": "Transazioni",
            "Upgrading": "Aggiornamento",
            "Validation": "Validazione",
            "Version (4.0)": "Versione (4.0)",
            "WebSockets": "WebSockets",
            "Welcome": "Benvenuto",
            "Xcode": "Xcode",
        ],
        localisation: .init(
            searchPlaceholder: "Cerca",
            searchNoResults: "Nessun risultato trovato",
            tableOfContentsTitle: "In questa pagina",
            previousPage: "Precedente",
            nextPage: "Successivo",
            editPage: "Modifica questa pagina",
            fallbackTitle: "Traduzione non disponibile",
            fallbackMessage: "Questa pagina non è ancora stata tradotta, pertanto viene mostrata la lingua predefinita.",
            notFoundTitle: "Pagina non trovata",
            notFoundMessage: "La pagina che stai cercando potrebbe essere stata spostata, rinominata o non essere mai esistita.",
            notFoundLink: "Torna alla home page",
            toggleNavigation: "Attiva/disattiva la navigazione",
            toggleColourScheme: "Cambia combinazione di colori"
        )
    ),

    Language(
        .japanese,
        siteName: "Vapor ドキュメント",
        description: "Vaporのドキュメント（Swift用Webフレームワーク）。",
        navTranslations: [
            "Advanced": "上級",
            "Async": "非同期",
            "Authentication": "認証",
            "Basics": "基礎",
            "Client": "クライアント",
            "Commands": "コマンド",
            "Content": "コンテンツ",
            "Contributing": "貢献",
            "Contributing Guide": "貢献ガイド",
            "Controllers": "コントローラー",
            "Crypto": "暗号",
            "Custom Tags": "カスタムタグ",
            "Deploy": "デプロイ",
            "Environment": "環境",
            "Errors": "エラー",
            "Files": "ファイル",
            "Folder Structure": "フォルダ構造",
            "Getting Started": "はじめに",
            "Install": "インストール",
            "Logging": "ロギング",
            "Migrations": "マイグレーション",
            "Model": "モデル",
            "Overview": "概要",
            "Passwords": "パスワード",
            "Query": "クエリ",
            "Queues": "キュー",
            "Relations": "関係",
            "Release Notes": "リリースノート",
            "Routing": "ルーティング",
            "Schema": "スキーマ",
            "Security": "セキュリティ",
            "Services": "サービス",
            "Sessions": "セッション",
            "Testing": "テスト",
            "Transactions": "トランザクション",
            "Upgrading": "アップグレード",
            "Validation": "バリデーション",
            "Welcome": "ようこそ",
        ],
        localisation: .init(
            searchPlaceholder: "検索",
            searchNoResults: "結果が見つかりません",
            tableOfContentsTitle: "このページの内容",
            previousPage: "前へ",
            nextPage: "次へ",
            editPage: "このページを編集",
            fallbackTitle: "翻訳がありません",
            fallbackMessage: "このページはまだ翻訳されていないため、デフォルトの言語で表示されています。",
            notFoundTitle: "ページが見つかりません",
            notFoundMessage: "お探しのページは移動または名称変更されたか、存在しない可能性があります。",
            notFoundLink: "ホームページに戻る",
            toggleNavigation: "ナビゲーションの切り替え",
            toggleColourScheme: "配色の切り替え"
        )
    ),

    Language(
        .korean,
        siteName: "Vapor 문서",
        description: "Vapor 문서 (Swift용 웹 프레임워크).",
        navTranslations: [
            "Advanced": "고급",
            "Async": "비동기 처리",
            "Authentication": "인증",
            "Basics": "기본 사항",
            "Client": "클라이언트",
            "Commands": "명령어",
            "Content": "컨텐츠",
            "Contributing": "기여하기",
            "Contributing Guide": "기여 가이드",
            "Controllers": "컨트롤러",
            "Crypto": "암호화",
            "Custom Tags": "사용자 정의 태그",
            "Deploy": "배포",
            "Environment": "환경 설정",
            "Errors": "에러",
            "Files": "파일",
            "Folder Structure": "폴더 구조",
            "Getting Started": "시작하기",
            "Install": "설치",
            "Logging": "로깅",
            "Migrations": "마이그레이션",
            "Model": "모델",
            "Overview": "개요",
            "Passwords": "비밀번호",
            "Query": "쿼리",
            "Queues": "대기열",
            "Relations": "관계",
            "Routing": "라우팅",
            "Schema": "스키마",
            "Security": "보안",
            "Services": "서비스",
            "Sessions": "세션",
            "Testing": "테스트",
            "Transactions": "트랜잭션",
            "Upgrading": "업그레이드",
            "Validation": "유효성 검사",
            "Version (4.0)": "버전 (4.0)",
            "WebSockets": "웹소켓",
            "Welcome": "환영합니다",
        ],
        localisation: .init(
            searchPlaceholder: "검색",
            searchNoResults: "결과를 찾을 수 없습니다",
            tableOfContentsTitle: "이 페이지에서",
            previousPage: "이전",
            nextPage: "다음",
            editPage: "이 페이지 편집",
            fallbackTitle: "번역 없음",
            fallbackMessage: "이 페이지는 아직 번역되지 않아 기본 언어로 표시됩니다.",
            notFoundTitle: "페이지를 찾을 수 없습니다",
            notFoundMessage: "찾고 있는 페이지가 이동되었거나 이름이 변경되었거나 존재하지 않을 수 있습니다.",
            notFoundLink: "홈페이지로 돌아가기",
            toggleNavigation: "내비게이션 전환",
            toggleColourScheme: "색 구성표 전환"
        )
    ),

    Language(
        .dutch,
        siteName: "Vapor Documentatie",
        description: "Vapor documentatie (webframework voor Swift).",
        navTranslations: [
            "Advanced": "Geavanceerd",
            "Async": "Asynchroon",
            "Authentication": "Authenticatie",
            "Basics": "Basis",
            "Commands": "Commando's",
            "Content": "Inhoud",
            "Contributing": "Bijdragen",
            "Contributing Guide": "Gids Bijdragen",
            "Crypto": "Encryptie",
            "Custom Tags": "Zelfgemaakte Tags",
            "Deploy": "Opzetten",
            "Environment": "Omgeving",
            "Files": "Bestanden",
            "Folder Structure": "Folder Structuur",
            "Getting Started": "Aan De Slag",
            "Hello, world": "Hallo, wereld",
            "Install": "Installeren",
            "Logging": "Loggen",
            "Migrations": "Migraties",
            "Overview": "Overzicht",
            "Passwords": "Wachtwoorden",
            "Query": "Opvragen",
            "Queues": "Wachtrijen",
            "Relations": "Relaties",
            "Routing": "Routering",
            "Schema": "Schema",
            "Security": "Veiligheid",
            "Services": "Diensten",
            "Sessions": "Sessies",
            "Testing": "Testen",
            "Transactions": "Transacties",
            "Upgrading": "Upgraden",
            "Validation": "Validatie",
            "Version (4.0)": "Versie (4.0)",
            "Welcome": "Welkom",
        ],
        localisation: .init(
            searchPlaceholder: "Zoeken",
            searchNoResults: "Geen resultaten gevonden",
            tableOfContentsTitle: "Op deze pagina",
            previousPage: "Vorige",
            nextPage: "Volgende",
            editPage: "Deze pagina bewerken",
            fallbackTitle: "Vertaling niet beschikbaar",
            fallbackMessage: "Deze pagina is nog niet vertaald, daarom wordt de standaardtaal weergegeven.",
            notFoundTitle: "Pagina niet gevonden",
            notFoundMessage: "De pagina die je zoekt is mogelijk verplaatst, hernoemd of heeft nooit bestaan.",
            notFoundLink: "Terug naar de startpagina",
            toggleNavigation: "Navigatie schakelen",
            toggleColourScheme: "Kleurenschema schakelen"
        )
    ),

    Language(
        .polish,
        siteName: "Dokumentacja Vapor",
        description: "Dokumentacja Vapor (framework webowy dla Swift).",
        navTranslations: [
            "APNS": "APNS",
            "Advanced": "Zaawansowane",
            "Async": "Asynchroniczność",
            "Authentication": "Autentykacja",
            "Basics": "Podstawy",
            "Client": "Klient",
            "Commands": "Komendy",
            "Content": "Kontent",
            "Contributing": "Kontrybucja",
            "Contributing Guide": "Przewodnik do kontrybucji",
            "Crypto": "Kryptografia",
            "Custom Tags": "Własne tagi",
            "Deploy": "Wdrożenie",
            "Environment": "Środowisko",
            "Errors": "Błędy",
            "Files": "Pliki",
            "Fluent": "Fluent",
            "Folder Structure": "Struktura folderów",
            "Getting Started": "Jak zacząć",
            "Hello, world": "Witaj, świecie",
            "Install": "Instalacja",
            "JWT": "JWT",
            "Leaf": "Leaf",
            "Logging": "Logowanie",
            "Middleware": "Middleware",
            "Migrations": "Migracje",
            "Model": "Model",
            "Overview": "Prezentacja",
            "Passwords": "Hasła",
            "Query": "Zapytania",
            "Queues": "Kolejki",
            "Redis": "Redis",
            "Relations": "Relacje",
            "Release Notes": "Informacja o wersji",
            "Routing": "Kierowanie ruchem",
            "Schema": "Schematy",
            "Security": "Bezpieczeństwo",
            "Server": "Serwer",
            "Services": "Serwisy",
            "Sessions": "Sesje",
            "SwiftPM": "SwiftPM",
            "Testing": "Testowanie",
            "Transactions": "Transakcje",
            "Upgrading": "Aktualizacja",
            "Validation": "Walidacja",
            "Version (4.0)": "Wersja (4.0)",
            "WebSockets": "WebSockety",
            "Welcome": "Witaj",
            "Xcode": "Xcode",
        ],
        localisation: .init(
            searchPlaceholder: "Szukaj",
            searchNoResults: "Nie znaleziono wyników",
            tableOfContentsTitle: "Na tej stronie",
            previousPage: "Poprzednia",
            nextPage: "Następna",
            editPage: "Edytuj tę stronę",
            fallbackTitle: "Tłumaczenie niedostępne",
            fallbackMessage: "Ta strona nie została jeszcze przetłumaczona, dlatego wyświetlany jest język domyślny.",
            notFoundTitle: "Nie znaleziono strony",
            notFoundMessage: "Strona, której szukasz, mogła zostać przeniesiona, zmieniona lub nigdy nie istniała.",
            notFoundLink: "Powrót do strony głównej",
            toggleNavigation: "Przełącz nawigację",
            toggleColourScheme: "Przełącz schemat kolorów"
        )
    ),

    Language(
        .chinese,
        siteName: "Vapor 中文文档",
        description: "Vapor 文档（Swift Web 框架）。",
        navTranslations: [
            "APNS": "苹果推送服务",
            "Advanced": "进阶",
            "Async": "异步",
            "Authentication": "认证",
            "Basics": "入门",
            "Client": "客户端",
            "Commands": "命令",
            "Content": "内容",
            "Contributing": "贡献",
            "Contributing Guide": "贡献指南",
            "Crypto": "加密",
            "Custom Tags": "自定义标签",
            "Deploy": "部署",
            "Environment": "环境",
            "Errors": "错误",
            "Files": "文件",
            "Fluent": "Fluent",
            "Folder Structure": "项目结构",
            "Getting Started": "开始",
            "Hello, world": "你好世界",
            "Install": "安装",
            "JWT": "JWT",
            "Leaf": "Leaf",
            "Logging": "日志",
            "Middleware": "中间件",
            "Migrations": "迁移",
            "Model": "模型",
            "Overview": "概述",
            "Passwords": "密码",
            "Query": "查询",
            "Queues": "队列",
            "Redis": "Redis",
            "Relations": "关联",
            "Routing": "路由",
            "Schema": "模式",
            "Security": "安全",
            "Server": "服务器",
            "Services": "服务",
            "Sessions": "会话",
            "SwiftPM": "Swift 包管理器",
            "Testing": "测试",
            "Transactions": "事务",
            "Validation": "验证",
            "Version (4.0)": "版本 (4.0)",
            "WebSockets": "即时通讯",
            "Welcome": "序言",
            "Xcode": "Xcode",
        ],
        localisation: .init(
            searchPlaceholder: "搜索",
            searchNoResults: "未找到结果",
            tableOfContentsTitle: "本页内容",
            previousPage: "上一页",
            nextPage: "下一页",
            editPage: "编辑此页",
            fallbackTitle: "暂无翻译",
            fallbackMessage: "此页面尚未翻译，因此显示默认语言。",
            notFoundTitle: "未找到页面",
            notFoundMessage: "您要查找的页面可能已被移动、重命名或从未存在。",
            notFoundLink: "返回首页",
            toggleNavigation: "切换导航",
            toggleColourScheme: "切换配色方案"
        )
    ),
]

// The current documentation (Vapor 4.0). This is the default version, served at
// the site root with unchanged URLs; its content lives under docs/4.0/.
let v4_0 = DocVersion(
    id: "4.0",
    name: "4.0 (latest)",
    isDefault: true,
    contentDirectory: "4.0",
    languages: languages
) {
        Page("Welcome", "index.md")
        Section("Install") {
            Page("macOS", "install/macos.md")
            Page("Linux", "install/linux.md")
        }
        Section("Getting Started") {
            Page("Hello, world", "getting-started/hello-world.md")
            Page("Folder Structure", "getting-started/folder-structure.md")
            Page("SwiftPM", "getting-started/spm.md")
            Page("Xcode", "getting-started/xcode.md")
        }
        Section("Basics") {
            Page("Routing", "basics/routing.md")
            Page("Controllers", "basics/controllers.md")
            Page("Content", "basics/content.md")
            Page("Client", "basics/client.md")
            Page("Validation", "basics/validation.md")
            Page("Async", "basics/async.md")
            Page("Logging", "basics/logging.md")
            Page("Environment", "basics/environment.md")
            Page("Errors", "basics/errors.md")
        }
        Section("Fluent") {
            Page("Overview", "fluent/overview.md")
            Page("Model", "fluent/model.md")
            Page("Relations", "fluent/relations.md")
            Page("Migrations", "fluent/migration.md")
            Page("Query", "fluent/query.md")
            Page("Transactions", "fluent/transaction.md")
            Page("Schema", "fluent/schema.md")
            Page("Advanced", "fluent/advanced.md")
        }
        Section("Leaf") {
            Page("Getting Started", "leaf/getting-started.md")
            Page("Overview", "leaf/overview.md")
            Page("Custom Tags", "leaf/custom-tags.md")
        }
        Section("Redis") {
            Page("Overview", "redis/overview.md")
            Page("Sessions", "redis/sessions.md")
        }
        Section("Advanced") {
            Page("Middleware", "advanced/middleware.md")
            Page("Testing", "advanced/testing.md")
            Page("Server", "advanced/server.md")
            Page("Files", "advanced/files.md")
            Page("Commands", "advanced/commands.md")
            Page("Queues", "advanced/queues.md")
            Page("WebSockets", "advanced/websockets.md")
            Page("Sessions", "advanced/sessions.md")
            Page("Services", "advanced/services.md")
            Page("Request", "advanced/request.md")
            Page("APNS", "advanced/apns.md")
            Page("Tracing", "advanced/tracing.md")
        }
        Section("Security") {
            Page("Authentication", "security/authentication.md")
            Page("Crypto", "security/crypto.md")
            Page("Passwords", "security/passwords.md")
            Page("JWT", "security/jwt.md")
        }
        Section("Deploy") {
            Page("DigitalOcean", "deploy/digital-ocean.md")
            Page("Fly", "deploy/fly.md")
            Page("Heroku", "deploy/heroku.md")
            Page("Supervisor", "deploy/supervisor.md")
            Page("Systemd", "deploy/systemd.md")
            Page("Nginx", "deploy/nginx.md")
            Page("Docker", "deploy/docker.md")
        }
        Section("Contributing") {
            Page("Contributing Guide", "contributing/contributing.md")
        }
        Section("Version (4.0)") {
            Page("Upgrading", "upgrading.md")
        }
        Page("Release Notes", "release-notes.md")
}

let site = KilnSite(
    name: "Vapor Docs",
    url: "https://docs.vapor.codes/",
    author: "Vapor Community",
    description: "Vapor's documentation (web framework for Swift).",
    image: "assets/social-card.png",
    twitterSite: "@codevapor",
    repository: .init(
        name: "Vapor GitHub",
        url: "https://github.com/vapor/vapor",
        editURI: "https://github.com/vapor/docs/edit/main/docs/4.0/"
    ),
    copyright: "Vapor Documentation © 2026 by Vapor is licensed under CC BY-NC-SA 4.0",
    // Custom theme: a thin docs-specific layer over the shared Vapor design
    // system (design.vapor.codes). Templates live in ./Theme; see that dir.
    theme: .custom(
        directory: "Theme",
        palette: .autoLightDark(primary: .black, accent: .blue),
        logo: "assets/logo.png",
        favicon: "assets/favicon.png",
        fonts: Fonts(text: "Roboto", code: "Roboto Mono")
    ),
    social: [
        .init(icon: .github, link: "https://github.com/vapor"),
        .init(icon: .discord, link: "https://discord.gg/vapor"),
        .init(icon: .twitter, link: "https://twitter.com/codevapor"),
        .init(icon: .mastodon, link: "https://hachyderm.io/@codevapor"),
    ],
    carbonAds: .init(serve: "CK7DT2QW", placement: "vaporcodes"),
    extraCSS: ["stylesheets/fonts.css"],
    // Newest first: current stable, then the imported legacy versions.
    versions: [v4_0, v3_0, v2_0, v1_5]
)

let outputDirectory = "site"
print("Building Vapor docs into ./\(outputDirectory) …")
// `.error` fails the build (non-zero exit) on any broken internal link, so CI
// catches them.
try await Kiln.build(site, contentDirectory: "docs", outputDirectory: outputDirectory, linkChecking: .error)

print("Done.")
