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
    
    public static func noteById(id: String, in context: NSManagedObjectContext) -> Note? {
        let serverNotesFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
        serverNotesFetch.predicate = NSPredicate(format: "id = %@", id)
        
        do {
            let fetchedNotes = try context.fetch(serverNotesFetch) as! [Note]
            if(fetchedNotes.count > 0) {
                return fetchedNotes[0]
            } else {
                return nil
            }
        } catch {
            fatalError("Failed to fetch note by id: \(error)")
        }
    }
    
    static func create(in managedObjectContext: NSManagedObjectContext, noteId: String? = nil, title: String? = nil, body: String? = nil) -> Note{
        let newNote = self.init(context: managedObjectContext)
        newNote.id = noteId ?? UUID().uuidString
        newNote.title = title ?? ""
        newNote.body = body ?? ""
        do {
            try  managedObjectContext.save()
            return newNote
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    static func updateTitle(note: Note, title: String, in managedObjectContext: NSManagedObjectContext) {
        note.title = title
        
        do {
            try managedObjectContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    static func updateBody(note: Note, body: String, in managedObjectContext: NSManagedObjectContext) {
        note.body = body
        
        do {
            try managedObjectContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    public static func deleteAllNotes(in managedObjectContext: NSManagedObjectContext) {
        // Create Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")

        // Create Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try managedObjectContext.execute(batchDeleteRequest)

        } catch {
            // Error Handling
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    public static func deleteAllNotesApartFrom(ids: [String], in managedObjectContext: NSManagedObjectContext) {
        let notesFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
        notesFetch.predicate = NSPredicate(format: "NOT id IN %@", ids)
        do {
            let fetchedNotes = try managedObjectContext.fetch(notesFetch) as! [Note]
            fetchedNotes.forEach { note in
                managedObjectContext.delete(note)
            }
            try managedObjectContext.save()
        } catch {
            fatalError("Failed to fetch note by id: \(error)")
        }
    }
    
    public static func deleteNote(note: Note, in managedObjectContext: NSManagedObjectContext) {
        managedObjectContext.delete(note)
        do {
            try managedObjectContext.save()
        } catch {
            // Error Handling
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
}

extension Collection where Element == Note, Index == Int {
    func delete(at indices: IndexSet, in managedObjectContext: NSManagedObjectContext) {
        indices.forEach {
            NotesService.shared.deleteNote(id: self[$0].id!, context: managedObjectContext)
        }
    }
}
