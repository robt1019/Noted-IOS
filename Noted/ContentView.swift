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
                    NotesView(onNoteUpdated: { note in
                        self.saveNoteToDevice(note: note)
                        
                        NotesToJson.localNotesToJson(context: self.viewContext)
                    })
                        .navigationBarTitle(Text("Notes"))
                        .navigationBarItems(
                            leading: LogoutButton(
                                onLoggedOut: {
                                    self.loggedIn = false
                            },
                                onLogoutFailure: {
                                    self.loggedIn = true
                            }),
                            trailing: Button(
                                action: {
                                    withAnimation { Note.create(in: self.viewContext) }
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
            self.listenForNotes()
        }
    }
    
    func saveNoteToDevice(note: Note) {
        Note.updateBody(note: note, body: note.body!, in: self.viewContext)
        Note.updateTitle(note: note, title: note.title!, in: self.viewContext)
    }
    
    func listenForNotes() {
        self.notes.on(event: "notesUpdated", callback: {
            diff in
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
