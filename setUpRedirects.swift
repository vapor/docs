#!/usr/bin/swift

/*
    SPDX-License-Identifier: MIT

    Copyright (c) 2023 Vapor

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

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
    try createRedirect(directory: directory, newDirectory: "basics")
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
    let redirectString = "<meta http-equiv=\"refresh\" content=\"0; url=/\(newDirectory)/\(directory)/\">"
    let fileURL = URL(fileURLWithPath: "site/\(directory)/index.html")
    try FileManager.default.createDirectory(atPath: "site/\(directory)", withIntermediateDirectories: true, attributes: nil)
    try redirectString.write(to: fileURL, atomically: true, encoding: .utf8)
}
