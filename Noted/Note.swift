//
//  Note.swift
//  Noted
//
//  Created by Robert Taylor on 06/08/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import SwiftUI
import CoreData

extension Note {
    static func create(in managedObjectContext: NSManagedObjectContext, notes: Notes){
        let newNote = self.init(context: managedObjectContext)
        newNote.id = UUID()
        newNote.title = ""
        newNote.body = ""
        newNote.notes = notes
        
        do {
            try  managedObjectContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
}
