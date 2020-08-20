//
//  NotesToJsonService.swift
//  Noted
//
//  Created by Robert Taylor on 07/08/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import Foundation
import SwiftUI
import CoreData

public struct JsonReadyNote: Codable {
    var title: String
    var body: String
}

class NotesToJsonService {
    
    static func jsonToNotesDictionary(jsonString: String) -> Dictionary<String, JsonReadyNote> {
        if(jsonString == "null") {
            return[:]
        }
        let jsonData = jsonString.data(using: .utf8)!
        let decodedNotesDictionary = try! JSONDecoder().decode([String: JsonReadyNote].self, from: jsonData)
        return decodedNotesDictionary
    }
}
