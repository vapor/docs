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

struct SearchIndex: Codable {
    let config: SearchIndexConfig
    var docs: [SearchIndexDocs]
}

struct SearchIndexConfig: Codable {
    let indexing: String?
    let lang: [String]
    let minSearchLength: Int?
    let prebuildIndex: Bool?
    let separator: String?

    enum CodingKeys: String, CodingKey {
        case indexing
        case lang
        case minSearchLength = "min_search_length"
        case prebuildIndex = "prebuild_index"
        case separator
    }
}

struct SearchIndexDocs: Codable {
    let location: String
    let text: String
    let title: String
}

let searchIndexPath = "site/search/search_index.json"

let fileURL = URL(fileURLWithPath: searchIndexPath)
let indexData = try Data(contentsOf: fileURL)
let searchIndex = try JSONDecoder().decode(SearchIndex.self, from: indexData)
var newSearchIndex = searchIndex
var searchIndexDocs = [SearchIndexDocs]()

let knownLanguages = [
        "en",
        "de",
        "es",
        "fr",
        "it",
        "ja",
        "ko",
        "nl",
        "pl",
        "zh",
    ].map { "\($0)/" }


for doc in newSearchIndex.docs {
    if !knownLanguages.contains(where: { doc.location.starts(with: $0) }) {
        searchIndexDocs.append(doc)
    }
}

newSearchIndex.docs = searchIndexDocs

try JSONEncoder().encode(newSearchIndex).write(to: fileURL)
