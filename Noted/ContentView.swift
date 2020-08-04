//
//  ContentView.swift
//  Noted
//
//  Created by Robert Taylor on 16/07/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import SwiftUI
import Auth0
import JWTDecode

struct ContentView: View {
    
    @State private var latestServerNotes = ""
    @State private var isEditing = false
    private let notes = NotesService()
    @ObservedObject private var keyboard = KeyboardResponder()
    @State private var loggedIn = false
    @State private var logoutAlertIsVisible = false
    @State private var currentNotes: String = ""
    
    var body: some View {
        VStack {
            if self.loggedIn {
                VStack (alignment: .trailing) {
                    HStack(spacing: 10) {
                        Button(action: {
                            self.closeKeyboard()
                            self.notes.saveNotes(notes: self.currentNotes, prev: self.latestServerNotes)
                            self.isEditing = false
                        }) {
                            Text("Save")
                        }.disabled(self.latestServerNotes == self.currentNotes)
                        Button(action: {
                            self.logoutAlertIsVisible = true
                        }) {
                            Text("Logout")
                        }.alert(isPresented: $logoutAlertIsVisible) {() ->
                            Alert in
                            return Alert(title: Text("Logout"), message: Text("Press continue on the next prompt to log out"), dismissButton: .default(Text("OK")){
                                AuthService.logout(loggedOut: {
                                    self.currentNotes = ""
                                    self.loggedIn = false
                                }, failed: {
                                    self.loggedIn = true
                                })
                                })
                        }
                    }.padding()
                    TextView(text: Binding(
                        get: {self.currentNotes},
                        set: {
                            (newValue) in
                            self.currentNotes = newValue
                            self.isEditing = self.latestServerNotes != self.currentNotes
                    }
                    ))
                        .frame(maxHeight: .infinity)
                        .onAppear {
                            print("appearing")
                            self.notes.on(event: "notesUpdated", callback: {
                                notes in
                                print("got some updated notes")
                                if (!self.isEditing) {
                                    self.latestServerNotes = notes
                                    self.currentNotes = notes
                                }
                            })
                    }
                }
                .padding()
                .padding(.bottom, keyboard.currentHeight)
                .edgesIgnoringSafeArea(.bottom)
                .animation(.easeOut(duration: 0.16))
            } else {
                Button(action: {
                    AuthService.getAccessToken(accessTokenFound: {token in
                        self.notes.connectToSocket(token: token)
                        self.loggedIn = true
                    }, noAccessToken: {
                        self.loggedIn = false
                    })
                }) {
                    Text("Login")
                }
            }
        }
        .onAppear() {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: {_ in
                print("trying to figure out logged in status")
                AuthService.getAccessToken(accessTokenFound: {
                    token in
                    print("logged in!")
                    self.notes.connectToSocket(token: token)
                    self.loggedIn = true
                }, noAccessToken: {
                    print("logged out!")
                    self.loggedIn = false
                })
            })
        }
    }
    
    func closeKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
