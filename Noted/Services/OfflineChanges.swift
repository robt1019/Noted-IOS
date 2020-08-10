//
//  OfflineChanges.swift
//  Noted
//
//  Created by Robert Taylor on 10/08/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import SwiftUI
import CoreData
import SocketIO

public class OfflineChanges {
    
    private static let key: String = "offlineUpdates"
    private static let defaults = UserDefaults.standard
    
    @Environment(\.managedObjectContext)
    private static var viewContext
    
    public static func createNote(id: String, title: String, body: String, context: NSManagedObjectContext) {
        var offlineUpdates = defaults.array(forKey: key)
        let action = ["createNote", id, title, body]
        if (offlineUpdates != nil) {
            offlineUpdates!.append(action)
        } else {
            offlineUpdates = [action]
        }
        defaults.set(offlineUpdates, forKey: key)
        Note.create(in: context, noteId: id, title: title, body: body)
    }
    
    public static func processOfflineUpdates(socket: SocketIOClient?, context: NSManagedObjectContext) {
        let offlineUpdates: [[Any]]? = defaults.array(forKey: key) as? [[Any]]
        if (offlineUpdates != nil) {
            offlineUpdates!.forEach { update in
                let action = update[0]
                if (action as! String == "createNote") {
                    let id = update[1]
                    let title = update[2]
                    let body = update[3]
                    NotesService.shared.createNote(id: id as! String, title: title as! String, body: body as! String, context: context)
                }
            }
        }
        
        defaults.set([], forKey: key)
    }
}
