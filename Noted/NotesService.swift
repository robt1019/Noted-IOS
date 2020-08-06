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
    private var localNotes = ""

    private var onNotesUpdated: ((Any) -> Void)? = nil
    
    public func saveNotes(notes: String, prev: String, online: Bool) {
        let diff = NotesDiffer.shared.diff(notes1: prev, notes2: notes)
        if (online) {
            let payload = [
                "diff": diff,
            ]
            self.socket?.emit("updateNotes", payload)
        } else {
            let defaults = UserDefaults.standard
            var offlineChanges = defaults.array(forKey: "OfflineChanges") ?? [[String]]()
            offlineChanges.append([prev, notes])
            defaults.set(offlineChanges, forKey: "OfflineChanges")
        }
    }
    
    public func on(event: String, callback: @escaping (Any) -> Void) {
        if(event == "notesUpdated") {
            self.onNotesUpdated = callback
            print("notesUpdated callback registered")
        }
    }
    
    public func connectToSocket(token: String, initialNotes: String = "") {
        
        self.localNotes = initialNotes
        
        self.socket?.disconnect()
        
        self.socketManager = SocketManager(socketURL: URL(string: "https://glacial-badlands-85832.herokuapp.com")!, config: [.log(false), .compress])
        self.socket = self.socketManager?.defaultSocket
        
        print("trying to connect to socket")
        
        self.socket?.connect()
        
        self.socket?.on("notesUpdated") {data, ack in
            print("notes received")
            let jsonDict = data[0] as? NSDictionary
            let diff = jsonDict?["diff"] as! String
            self.onNotesUpdated!(diff)
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
                    let notes = jsonDict?["content"] as! String
                    if(UserDefaults.standard.array(forKey: "OfflineChanges")?.count ?? 0 > 0) {
                        self.processOfflineChanges()
                    } else {
                        self.onNotesUpdated!(NotesDiffer.shared.diff(notes1: self.localNotes, notes2: notes))
                    }
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
    
    public func restart(localNotes: String) {
        self.localNotes = localNotes
        self.socket?.connect()
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
