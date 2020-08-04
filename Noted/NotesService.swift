//
//  NotesService.swift
//  Noted
//
//  Created by Robert Taylor on 28/07/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import Foundation
import SocketIO

open class NotesService {
    
    private var socketManager: SocketManager? = nil
    private var socket: SocketIOClient? = nil
    private var connected = false

    private var onNotesUpdated: ((String) -> Void)? = nil
    
    public func saveNotes(notes: String, prev: String, online: Bool) {
        
        print("notes: ")
        print(notes)
        print("prev: ")
        print(prev)
        if (online) {
            let payload = [
                "content": notes,
                "prev": prev
            ]
            
            print("emitting: ")
            print(payload)
            self.socket?.emit("updateNotes", payload)
        } else {
            let defaults = UserDefaults.standard
            var offlineChanges = defaults.array(forKey: "OfflineChanges") ?? [[String]]()
            offlineChanges.append([prev, notes])
            defaults.set(offlineChanges, forKey: "OfflineChanges")
        }
    }
    
    public func on(event: String, callback: @escaping (String) -> Void) {
        if(event == "notesUpdated") {
            self.onNotesUpdated = callback
            print("notesUpdated callback registered")
        }
    }
    
    public func connectToSocket(token: String) {
        
        self.socket?.disconnect()
        
        self.socketManager = SocketManager(socketURL: URL(string: "https://glacial-badlands-85832.herokuapp.com")!, config: [.log(false), .compress])
        self.socket = self.socketManager?.defaultSocket
        
        print("trying to connect to socket")
        
        self.socket?.connect()
        
        self.socket?.on("notesUpdated") {data, ack in
            print("notes received")
            let jsonDict = data[0] as? NSDictionary
            let newNotes = jsonDict?["content"] as! String
            self.onNotesUpdated!(newNotes)
        }
        
        self.socket?.on(clientEvent: .connect) {data, ack in
            print("socket connected")
            self.connected = true;
            
            AuthService.getAccessToken (accessTokenFound: { token in
                self.socket?.emit("authenticate", ["token": token])
                print("authenticating")
            }, noAccessToken: {
                print("authentication failed")
            })
            
            self.socket?.once("authenticated", callback: { _, _ in
                print("authenticated")
                self.socket?.once("initialNotes") {data, ack in
                    print("initial notes received")
                    let jsonDict = data[0] as? NSDictionary
                    let newNotes = jsonDict?["content"] as! String
                    self.onNotesUpdated!(newNotes)
                    self.processOfflineChanges()
                }
            });
            
            
            self.socket?.on("unauthorized") {data, ack in
                print("unauthorized, reconnecting")
                self.socket?.connect()
            }
            
            self.socket?.on(clientEvent:  .disconnect) {data, ack in
                print("socket disconnected, reconnecting")
                self.connected = false;
                self.socket?.connect()
            }
            
        }
    }
    
    public func processOfflineChanges() {
        let defaults = UserDefaults.standard
        let offlineChanges = defaults.array(forKey: "OfflineChanges") ?? [[String]]()
        for change in offlineChanges {
            let changeArray = change as! [String]
            print("updating notes?")
            let prev = changeArray[0]
            let notes = changeArray[1]
            self.saveNotes(notes: notes, prev: prev, online: true)
        }
        defaults.set([], forKey: "OfflineChanges")
    }
}
