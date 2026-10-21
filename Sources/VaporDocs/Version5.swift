import Kiln

let v5_0 = DocVersion(
    id: "5.0",
    name: "5.0 Beta",
    isPrerelease: true,
    contentDirectory: "5.0",
    languages: languages
) {
    Page("Welcome", "index.md")
    Section("Install") {
        Page("macOS", "install/macos.md")
        Page("Linux", "install/linux.md")
    }
    Section("Getting Started") {
        Page("Hello, world", "getting-started/hello-world.md")
        Page("SwiftPM", "getting-started/spm.md")
        Page("Xcode", "getting-started/xcode.md")
    }
    Section("Contributing") {
        Page("Contributing Guide", "contributing/contributing-guide.md")
    }
}
