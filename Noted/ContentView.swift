//
//  ContentView.swift
//  Noted
//
//  Created by Robert Taylor on 16/07/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import SwiftUI
import SocketIO
import Auth0
import JWTDecode

struct ContentView: View {
    
    @State private var message = "loading notes"
    @State private var savedMessage = ""
    @State private var textStyle = UIFont.TextStyle.body
    @State private var socketManager = SocketManager(socketURL: URL(string: "https://glacial-badlands-85832.herokuapp.com")!, config: [.log(false), .compress])
    @State private var socket: SocketIOClient? = nil
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            TextView(text: $message, textStyle: $textStyle)
                .padding(.horizontal)
            Button(action: {
                self.closeKeyboard()
                self.saveNotes()
            }) {
                Text("Save")
            }
            .padding()
        }.onAppear {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                Auth0
                    .webAuth()
                    .scope("openid email")
                    .audience("https://glacial-badlands-85832.herokuapp.com")
                    .start {
                        switch $0 {
                        case .failure(let error):
                            // Handle the error
                            print("Error: \(error)")
                        case .success(let credentials):
                            
                            // Do something with credentials e.g.: save them.
                            // Auth0 will automatically dismiss the login page
                            self.connectToSocket(token: credentials.accessToken ?? "")
                        }
                }
            }
        }.onDisappear {
            self.saveNotes()
        }
    }
    
    func connectToSocket(token: String) {
        
        self.socket = self.socketManager.defaultSocket
        
        self.socket?.on(clientEvent: .connect) {data, ack in
            print("socket connected")
            self.socket?.emit("authenticate", ["token": token])
            
            self.socket?.on("authenticated", callback: { _, _ in
              // use the socket as usual
                self.socket?.on("notesUpdated") {data, ack in
                    print("notes received")
                    print(data[0])
                    let jsonDict = data[0] as? NSDictionary
                    self.message = jsonDict?["content"] as! String
                    self.savedMessage = self.message
                }
                
                self.socket?.onAny ({thing in
                    print(thing)
                })
            });
            
            
            self.socket?.on("unauthorized") {data, ack in
                print(data)
            }

        }
        

        
        self.socket?.connect()
    }
    
    func saveNotes() {
        let payload = [
            "content": self.message
        ]
        
        self.socket?.emit("updateNotes", payload)
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
