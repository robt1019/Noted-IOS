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

struct JsonReadyNote: Codable {
    var title: String
    var body: String
}

class NotesToJson {
    
    static func localNotesToJson(context: NSManagedObjectContext) -> String {
        
        let notesFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
                
        do {
            let fetchedNotes = try context.fetch(notesFetch) as! [Note]
            let encodableNotes = fetchedNotes.reduce(into: Dictionary<String, JsonReadyNote>()) {
                prev, curr in
                prev[curr.id!.uuidString] = JsonReadyNote(title: curr.title!, body: curr.body!)
            }
            do {
                let jsonified = try JSONEncoder().encode(encodableNotes)
                let jsonString = String(data: jsonified, encoding: .utf8)!
                jsonToNotes(jsonString: jsonString)
                return jsonString
            } catch {
                fatalError("Failed to encode json: \(error)")
            }

        } catch {
            fatalError("Failed to fetch notes: \(error)")
        }
    }
    
//    static func jsonToNotes(jsonString: String) {
//        let jsonData = jsonString.data(using: .utf8)!
//        let decodedNotesDictionary = try! JSONDecoder().decode([String: JsonReadyNote].self, from: jsonData)
//        var notesArray: [Note] = []
//        
//        decodedNotesDictionary.keys.forEach() {key in
//            let note = Note()
//            let dictionaryNote = decodedNotesDictionary[key]
//            note.title = dictionaryNote?.title
//            note.body = dictionaryNote?.body
//            note.id = UUID(uuidString: key)
//            notesArray.append(note)
//        }
//        
//        print(notesArray)
//    }
}
