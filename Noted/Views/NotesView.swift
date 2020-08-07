//
//  NotesView.swift
//  Noted
//
//  Created by Robert Taylor on 07/08/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import SwiftUI

struct NotesView: View {
    
    @FetchRequest(sortDescriptors: [])
    var notes: FetchedResults<Note>
    
    @Environment(\.managedObjectContext)
    var viewContext
    
    let onNoteUpdated: (Note) -> Void
    
    var body: some View {
        List {
            ForEach(self.notes, id: \.self) { (note: Note) in
                NavigationLink(destination: NoteView(note: note, onNoteUpdated: { updatedNote in
                    self.onNoteUpdated(updatedNote)
                })) {
                    Text(note.title!)
                }
            }.onDelete { indices in
                self.notes.delete(at: indices, from: self.viewContext)
            }
        }
    }
}

