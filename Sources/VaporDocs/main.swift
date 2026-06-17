import Kiln

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
