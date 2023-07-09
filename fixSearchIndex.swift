#!/usr/bin/swift

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
