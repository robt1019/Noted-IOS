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
                    AuthService.logout()
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
                AuthService.getAccessToken { token in
                    self.notes.connectToSocket(token: token)
                }
            })
        }.onDisappear {
            print("disappearing")
            self.notes.saveNotes(notes: self.message)
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
