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
    @State var initialised = false
    
    var body: some View {
        Group {
            if (self.loggedIn) {
                NavigationView {
                    NotesView(onNoteUpdated: { note in
                        Note.updateBody(note: note, body: note.body!, in: self.viewContext)
                        Note.updateTitle(note: note, title: note.title!, in: self.viewContext)
                    })
                        .navigationBarTitle(Text("Notes"))
                        .navigationBarItems(
                            leading: LogoutButton(
                                onLoggedOut: {
                                    self.loggedIn = false
                                    print("logged out")
                            },
                                onLogoutFailure: {
                                    self.loggedIn = true
                                    print("logged in")
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
                LoggedOutView(onLoggedIn: {
                    self.loggedIn = true
                })
            }
        }.onAppear {
            self.determineIfLoggedIn()
        }
    }
    
    func determineIfLoggedIn() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: {_ in
            AuthService.getAccessToken(accessTokenFound: {
                token in
                self.loggedIn = true
            }, noAccessToken: {
                self.loggedIn = false
                self.initialised = true
            })
        })
    }
}

struct LogoutButton: View {
    
    @State var logoutAlertIsVisible = false
    let onLoggedOut: () -> Void
    let onLogoutFailure: () -> Void
    
    @Environment(\.managedObjectContext)
    var viewContext
    
    var body: some View {
        Button(action: {
            self.logoutAlertIsVisible = true
        }) {
            Text("Logout")
        }.alert(isPresented: $logoutAlertIsVisible) {() ->
            Alert in
            return Alert(title: Text("Logout"), message: Text("Press continue on the next prompt to log out"), dismissButton: .default(Text("OK")){
                AuthService.logout(loggedOut: {
                    self.onLoggedOut()
                }, failed: {
                    self.onLogoutFailure()
                })
                })
        }
    }
}

struct LoggedOutView: View {
    
    let onLoggedIn: () -> Void
    
    var body: some View {
        Button(action: {
            AuthService.getAccessToken(accessTokenFound: {token in
                self.onLoggedIn()
            }, noAccessToken: {
                print("could not log in")
            })
        }) {
            Text("Login")
        }
    }
}

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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return ContentView().environment(\.managedObjectContext, context)
    }
}
