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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return ContentView().environment(\.managedObjectContext, context)
    }
}
