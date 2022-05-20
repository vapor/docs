#!/usr/bin/swift

import Foundation

let basicDirectories = [
    "async",
    "client",
    "content",
    "environment",
    "errors",
    "logging",
    "routing",
    "validation"
]

let advancedDirectories = [
    "apns",
    "commands",
    "files",
    "middleware",
    "queues",
    "server",
    "services",
    "sessions",
    "testing",
    "websockets",
]

let gettingStartedDirectories = [
    "folder-structure",
    "hello-world",
    "spm",
    "xcode",
]

let securityDirectories = [
    "authentication",
    "crypto",
    "jwt",
    "passwords",
]

for directory in basicDirectories {
    try createRedirect(directory: directory, newDirectory: "basic")
}

for directory in advancedDirectories {
    try createRedirect(directory: directory, newDirectory: "advanced")
}

for directory in gettingStartedDirectories {
    try createRedirect(directory: directory, newDirectory: "getting-started")
}

for directory in securityDirectories {
    try createRedirect(directory: directory, newDirectory: "security")
}

func createRedirect(directory: String, newDirectory: String) throws {
    let redirectString = "<meta http-equiv=\"refresh\" content=\"0; url=/\(newDirectory)/\(directory)\">"
    let fileURL = URL(fileURLWithPath: "site/\(directory)/index.html")
    try FileManager.default.createDirectory(atPath: "site/\(directory)", withIntermediateDirectories: true, attributes: nil)
    try redirectString.write(to: fileURL, atomically: true, encoding: .utf8)
}