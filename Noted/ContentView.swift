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
    
    @State private var message = "loading notes"
    @State private var savedMessage = ""
    private let notes = NotesService()
    
    let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
    
    var body: some View {
        VStack() {
            HStack() {
                Button(action: {
                    self.closeKeyboard()
                    self.notes.saveNotes(notes: self.message)
                }) {
                    Text("Save")
                }
                .padding()
                Button(action: {
                    self.logout()
                }) {
                    Text("Logout")
                }
                .padding()
            }
            TextView(text: $message)
                .padding(.horizontal)
        }.onAppear {
            self.notes.on(event: "notesUpdated", callback: {
                notes in
                print("got some updated notes")
                self.message = notes
            })
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: {
                _ in
                self.authenticate()
            })
        }.onDisappear {
            print("disappearing")
            self.notes.saveNotes(notes: self.message)
        }
    }
    
    func authenticate() {

        if(self.credentialsManager.hasValid()) {
            self.credentialsManager.credentials(callback: {err, credentials in
                if(err != nil) {
                    print("problem with credentials manager")
                    print(err)
                    AuthService.login(onSuccess: {  credentials in
                        print("storing creds")
                        self.credentialsManager.store(credentials: credentials)
                        self.notes.connectToSocket(token: (credentials.accessToken!))
                    }, onFailure: {
                        print("whoopsie")
                    })
                } else {
                    print("using stored credentials")
                    self.notes.connectToSocket(token: (credentials?.accessToken!)!)
                }
            })
        } else {
            print("no credentials stored")
            AuthService.login(onSuccess: {  credentials in
                print("storing creds")
                self.credentialsManager.store(credentials: credentials)
                self.notes.connectToSocket(token: (credentials.accessToken!))
            }, onFailure: {
                print("whoopsie")
            })
        }
    }
    
    
    
    func logout() {
        self.credentialsManager.clear()
        Auth0
            .webAuth()
            .clearSession(federated:false) {
                switch $0 {
                case true:
                    self.message="login to view notes (restart app)"
                case false:
                    print("oh noes. Could not log out")
                }
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
