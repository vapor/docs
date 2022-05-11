#!/usr/bin/swift

import Foundation

struct SearchIndex: Codable {
    let config: SearchIndexConfig
    var docs: [SearchIndexDocs]
}

struct SearchIndexConfig: Codable {
    let indexing: String
    let lang: [String]
    let minSearchLength: Int
    let prebuildIndex: Bool
    let separator: String

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

for doc in newSearchIndex.docs {
    if !doc.location.starts(with: "en/") 
      && !doc.location.starts(with: "de/")
      && !doc.location.starts(with: "fr/") 
      && !doc.location.starts(with: "nl/") {
          searchIndexDocs.append(doc)
    }
}

newSearchIndex.docs = searchIndexDocs

try JSONEncoder().encode(newSearchIndex).write(to: fileURL)
