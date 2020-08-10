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
    @Environment(\.colorScheme)
    var colorScheme
    
    @State var loggedIn = false
    @State var initialised = false
    
    private var notes = NotesService.shared
    
    var body: some View {
        Group {
            if (self.initialised) {
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
                                        withAnimation {
                                            Note.create(in: self.viewContext)
                                        }
                                }
                                ) {
                                    Image(systemName: "plus")
                                }.padding()
                        )
                    }.navigationViewStyle(StackNavigationViewStyle())
                } else {
                    LoggedOutView(onLoggedIn: { token in
                        self.loggedIn = true
                        self.notes.connectToSocket(token: token)
                    })
                }
            } else {
                ZStack {
                    colorScheme == .dark ? Color.black : Color.white
                    Text("NOTED").foregroundColor(.white).bold()
                    Image("Noted-IOS").resizable().scaledToFit()
                }
            }
        }.onAppear {
            if(AuthService.hasCredentials()) {
                self.authenticate()
            } else {
                self.initialised = true
            }
            self.listenForInitialNotes()
            self.listenForNoteChanges()
            self.listenForNoteDeletions()
        }
    }
    
    func saveNoteToServer(id: String, title: String, body: String) {
        let prevNote = Note.noteById(id: id, in: self.viewContext)
        if(!(prevNote?.title == title && prevNote?.body == body)) {
            self.notes.saveNote(id: id, title: title, body: body, prevNote: prevNote)
        }
    }
    
    func listenForNoteDeletions() {
        self.notes.onNoteDeleted {
            noteId in
            let note = Note.noteById(id: noteId, in: self.viewContext)
            if(note != nil) {
                print("deleting note")
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
            Note.deleteAllNotesApartFrom(ids: [String] (initialNotes.keys), in: self.viewContext)
            initialNotes.keys.forEach { noteId in
                print(noteId)
                let newServerNote = initialNotes[noteId]
                let note = Note.noteById(id: noteId, in: self.viewContext)  
                if (note != nil) {
                    if (note!.title != newServerNote?.title) {
                        let newTitle = NotesDiffer.shared.patch(notes1: note!.title!, diff: NotesDiffer.shared.diff(notes1: note!.title!, notes2: newServerNote!.title))
                        Note.updateTitle(note: note!, title: newTitle, in: self.viewContext)
                    }
                    if (note!.body != newServerNote?.body) {
                        let newBody = NotesDiffer.shared.patch(notes1: note!.body!, diff: NotesDiffer.shared.diff(notes1: note!.body!, notes2: newServerNote!.body))
                        Note.updateBody(note: note!, body: newBody, in: self.viewContext)
                    }
                } else {
                    Note.create(in: self.viewContext, noteId: noteId, title: newServerNote?.title, body: newServerNote?.body)
                }
                
            }

            self.initialised = true
        })
    }
    
    func authenticate() {
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
