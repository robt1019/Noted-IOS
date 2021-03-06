//
//  ContentView.swift
//  Noted
//
//  Created by Robert Taylor on 06/08/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import SwiftUI
import Network

struct ContentView: View {
    @Environment(\.managedObjectContext)
    var viewContext
    @Environment(\.colorScheme)
    var colorScheme
    
    @State var loggedIn = false
    @State var initialised = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "Monitor")
    
    private var notes = NotesService.shared
    
    var body: some View {
        Group {
            if (self.initialised) {
                if (self.loggedIn) {
                    NavigationView {
                        NotesView(onNoteUpdated: { prevTitle, prevBody, id, title, body in
                            self.updateNote(prevTitle: prevTitle, prevBody: prevBody, id: id, title: title, body: body)
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
                                            self.createNote()
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
                        self.initialised = false
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
                if(self.notes.online) {
                    self.loggedIn = false
                    self.initialised = false
                    self.authenticate()
                } else {
                    self.loggedIn = true
                    self.initialised = true
                }
            } else {
                self.initialised = true
            }
            self.listenForInitialNotes()
            self.listenForNoteCreations()
            self.listenForNoteChanges()
            self.listenForNoteDeletions()
        }
    }
    
    func createNote() {
        self.notes.createNote(id: UUID().uuidString, title: "New...", body: "Body...", context: self.viewContext)
    }
    
    func updateNote(prevTitle: String, prevBody: String, id: String, title: String, body: String) {
        self.notes.updateNote(prevTitle: prevTitle, prevBody: prevBody, id: id, title: title, body: body, context: self.viewContext)
    }
    
    func listenForNoteCreations() {
        self.notes.onNoteCreated { id, title, body in
            Note.create(in: self.viewContext, noteId: id, title: title, body: body)
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
            
            let note = Note.noteById(id: id, in: self.viewContext)
        
            let newTitle = NotesDiffer.shared.patch(notes1: note!.title!, diff: titleDiff)
            let newBody = NotesDiffer.shared.patch(notes1: note!.body!, diff: bodyDiff)
            
            Note.updateTitle(note: note!, title: newTitle, in: self.viewContext)
            Note.updateBody(note: note!, body: newBody, in: self.viewContext)
        }
    }
    
    func listenForInitialNotes() {
        self.notes.onInitialNotes(callback: {
            initialNotes in
            initialNotes.keys.forEach { noteId in
                let newServerNote = initialNotes[noteId]
                let note = Note.noteById(id: noteId, in: self.viewContext)  
                if (note != nil) {
                    let newTitle = NotesDiffer.shared.patch(notes1: note!.title!, diff: NotesDiffer.shared.diff(notes1: note!.title!, notes2: newServerNote!.title))
                    let newBody = NotesDiffer.shared.patch(notes1: note!.body!, diff: NotesDiffer.shared.diff(notes1: note!.body!, notes2: newServerNote!.body))
                    Note.updateTitle(note: note!, title: newTitle, in: self.viewContext)
                    Note.updateBody(note: note!, body: newBody, in: self.viewContext)
                } else {
                    Note.create(in: self.viewContext, noteId: noteId, title: newServerNote?.title, body: newServerNote?.body)
                }
            }
            
            Note.deleteAllNotesApartFrom(ids: [String] (initialNotes.keys), in: self.viewContext)

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
            }, forceLogin: false)
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return ContentView().environment(\.managedObjectContext, context)
    }
}
