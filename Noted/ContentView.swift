//
//  ContentView.swift
//  Noted
//
//  Created by Robert Taylor on 06/08/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext)
    var viewContext
    
    @State var loggedIn = false
    
    private var notes = NotesService.shared
    
    var body: some View {
        Group {
            if (self.loggedIn) {
                NavigationView {
                    NotesView(onNoteUpdated: { id, title, body in
                        print(id)
                        print(title)
                        print(body)
                        self.saveNoteToServer(id: id, title: title, body: body)
                    })
                        .navigationBarTitle(Text("Notes"))
                        .navigationBarItems(
                            leading: LogoutButton(
                                onLoggedOut: {
                                    self.loggedIn = false
                                    Note.deleteAllNotes(in: self.viewContext)
                            },
                                onLogoutFailure: {
                                    self.loggedIn = true
                            }),
                            trailing: Button(
                                action: {
                                    withAnimation { Note.create(in: self.viewContext, title: "New note...", body: "body...") }
                            }
                            ) {
                                Image(systemName: "plus")
                            }.padding()
                    )
                }.navigationViewStyle(DoubleColumnNavigationViewStyle())
            } else {
                LoggedOutView(onLoggedIn: { token in
                    self.loggedIn = true
                    self.notes.connectToSocket(token: token)
                })
            }
        }.onAppear {
            self.determineIfLoggedIn()
            self.listenForInitialNotes()
            self.listenForNoteChanges()
            self.listenForNoteDeletions()
        }
    }
    
    func saveNoteToServer(id: String, title: String, body: String) {
        let prevNote = Note.noteById(id: id, in: self.viewContext)
        print("prevNote: \(prevNote)")
        if(!(prevNote?.title == title && prevNote?.body == body)) {
            self.notes.saveNote(id: id, title: title, body: body, prevNote: prevNote)
        }
    }
    
    func listenForNoteDeletions() {
        self.notes.onNoteDeleted {
            noteId in
            let note = Note.noteById(id: noteId, in: self.viewContext)
            if(note != nil) {
                Note.deleteNote(note: note!, in: self.viewContext)
            }
        }
    }
    
    func listenForNoteChanges() {
        self.notes.onNoteUpdated {
            id, titleDiff, bodyDiff in
            
            print("new notes coming in")
            
            let note = Note.noteById(id: id, in: self.viewContext)
            
            if (note != nil) {
                let newTitle = NotesDiffer.shared.patch(notes1: note!.title!, diff: titleDiff)
                let newBody = NotesDiffer.shared.patch(notes1: note!.body!, diff: bodyDiff)
                
                Note.updateTitle(note: note!, title: newTitle, in: self.viewContext)
                Note.updateBody(note: note!, body: newBody, in: self.viewContext)
            } else {
                let newTitle = NotesDiffer.shared.patch(notes1: "", diff: titleDiff)
                let newBody = NotesDiffer.shared.patch(notes1: "", diff: bodyDiff)
                Note.create(in: self.viewContext, noteId: id, title: newTitle, body: newBody)
            }
        }
    }
    
    func listenForInitialNotes() {
        self.notes.onInitialNotes(callback: {
            initialNotes in
            print(initialNotes)
            initialNotes.keys.forEach { noteId in
                print(noteId)
                let newServerNote = initialNotes[noteId]
                let note = Note.noteById(id: noteId, in: self.viewContext)
                if (note != nil) {
                    print("found existing note to update")
                    print(note?.title)
                    print(note?.body)
                    if (note!.title != newServerNote?.title) {
                        let newTitle = NotesDiffer.shared.patch(notes1: note!.title!, diff: NotesDiffer.shared.diff(notes1: note!.title!, notes2: newServerNote!.title))
                        Note.updateTitle(note: note!, title: newTitle, in: self.viewContext)
                    }
                    if (note!.body != newServerNote?.body) {
                        let newBody = NotesDiffer.shared.patch(notes1: note!.body!, diff: NotesDiffer.shared.diff(notes1: note!.body!, notes2: newServerNote!.body))
                        Note.updateBody(note: note!, body: newBody, in: self.viewContext)
                    }
                } else {
                    print("creating new note")
                    Note.create(in: self.viewContext, noteId: noteId, title: newServerNote?.title, body: newServerNote?.body)
                }
                
            }
        })
    }
    
    func determineIfLoggedIn() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: {_ in
            AuthService.getAccessToken(accessTokenFound: {
                token in
                self.notes.connectToSocket(token: token)
                self.loggedIn = true
            }, noAccessToken: {
                self.loggedIn = false
            })
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return ContentView().environment(\.managedObjectContext, context)
    }
}
