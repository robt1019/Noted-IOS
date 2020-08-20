//
//  NotesView.swift
//  Noted
//
//  Created by Robert Taylor on 07/08/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import SwiftUI

struct NotesView: View {
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Note.title, ascending: true)])
    var notes: FetchedResults<Note>
    
    @Environment(\.managedObjectContext)
    var viewContext
    
    let onNoteUpdated: (String, String, String, String, String) -> Void
    
    var body: some View {
        List {
            ForEach(self.notes, id: \.self) { (note: Note) in
                NavigationLink(destination: NoteView(note: note, onNoteUpdated: { prevTitle, prevBody, id, title, body in
                    self.onNoteUpdated(prevTitle, prevBody, id, title, body)
                })) {
                    Text(note.title!)
                }
            }.onDelete { indices in
                self.notes.delete(at: indices, in: self.viewContext)
            }
        }
    }
}

