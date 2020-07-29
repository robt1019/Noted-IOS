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
    
    @State private var message = ""
    private let notes = NotesService()
    @ObservedObject private var keyboard = KeyboardResponder()
    
    var body: some View {
        VStack (alignment: .trailing) {
            HStack(spacing: 10) {
                Button(action: {
                    self.closeKeyboard()
                    self.notes.saveNotes(notes: self.message)
                }) {
                    Text("Save")
                }
                NavigationLink(destination: Text("Logout")) {
                    /*@START_MENU_TOKEN@*/ /*@PLACEHOLDER=Label Content@*/Text("Logout")/*@END_MENU_TOKEN@*/
                }
            }.padding()
            NavigationView {
                TextView(text: $message)
                    .padding(.horizontal)
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
            }
            .padding()
            .frame(maxHeight: .infinity)
            .onAppear {
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
        }.padding()
        .padding(.bottom, keyboard.currentHeight)
        .edgesIgnoringSafeArea(.bottom)
        .animation(.easeOut(duration: 0.16))
        
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
