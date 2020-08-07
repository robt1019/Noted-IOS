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
    
    static func localNotesToJson(context: NSManagedObjectContext) -> String {
        
        let notesFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
                
        do {
            let fetchedNotes = try context.fetch(notesFetch) as! [Note]
            let encodableNotes = fetchedNotes.reduce(into: Dictionary<String, JsonReadyNote>()) {
                prev, curr in
                prev[curr.id] = JsonReadyNote(title: curr.title!, body: curr.body!)
            }
            do {
                let jsonified = try JSONEncoder().encode(encodableNotes)
                let jsonString = String(data: jsonified, encoding: .utf8)!
                return jsonString
            } catch {
                fatalError("Failed to encode json: \(error)")
            }

        } catch {
            fatalError("Failed to fetch notes: \(error)")
        }
    }
        
    static func jsonToNotesDictionary(jsonString: String) -> Dictionary<String, JsonReadyNote> {
        if(jsonString == "null") {
            return[:]
        }
        let jsonData = jsonString.data(using: .utf8)!
        let decodedNotesDictionary = try! JSONDecoder().decode([String: JsonReadyNote].self, from: jsonData)
        return decodedNotesDictionary
    }
}
