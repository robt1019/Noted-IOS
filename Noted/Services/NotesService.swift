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
    
    public static let shared = NotesService()
    
    private var socketManager: SocketManager? = nil
    private var socket: SocketIOClient? = nil
    private var connected = false
    
    private var _onNoteUpdated: ((String, Any, Any) -> Void)? = nil
    private var _onInitialNotes: ((Dictionary<String, JsonReadyNote>) -> Void)? = nil
    private var _onNoteDeleted: ((String) -> Void)? = nil
    
    public func saveNote(id: String, title: String, body: String, prevNote: Note? ) {
        if (prevNote != nil) {
            let titleDiff = NotesDiffer.shared.diff(notes1: prevNote!.title!, notes2: title)
            let bodyDiff = NotesDiffer.shared.diff(notes1: prevNote!.body!, notes2: body)
            let payload: [String: Any] = [
                "id": id,
                "title": titleDiff,
                "body": bodyDiff,
            ]
            self.socket?.emit("updateNote", payload)
        } else {
            let titleDiff = NotesDiffer.shared.diff(notes1: "", notes2: title)
            let bodyDiff = NotesDiffer.shared.diff(notes1: "", notes2: body)
            let payload: [String: Any] = [
                "id": id,
                "title": titleDiff,
                "body": bodyDiff,
            ]
            self.socket?.emit("updateNote", payload)
        }
    }
    
    public func deleteNote(id: String) {
        self.socket?.emit("deleteNote", id)
    }
    
    public func onNoteDeleted(callback: @escaping (String) -> Void) {
        self._onNoteDeleted = callback
    }
    
    public func onNoteUpdated(callback: @escaping (String, Any, Any) -> Void) {
        self._onNoteUpdated = callback
    }
    
    public func onInitialNotes(callback: @escaping(Dictionary<String, JsonReadyNote>) -> Void) {
        self._onInitialNotes = callback
    }
    
    public func connectToSocket(token: String, initialNotes: String = "") {
        
        self.socket?.disconnect()
        
        self.socketManager = SocketManager(socketURL: URL(string: "https://glacial-badlands-85832.herokuapp.com")!, config: [.log(false), .compress])
        self.socket = self.socketManager?.defaultSocket
                
        self.socket?.connect()
        
        self.socket?.on("noteUpdated") {data, ack in
            let jsonData = data[0] as! NSDictionary
            let id = jsonData["id"]
            let title = jsonData["title"]
            let body = jsonData["body"]
            self._onNoteUpdated!(id as! String, title, body)
        }
        
        self.socket?.on("noteDeleted") {data, ack in
            self._onNoteDeleted!(data[0] as! String)
        }
        
        self.socket?.on(clientEvent: .connect) {data, ack in
            self.connected = true;
            
            AuthService.getAccessToken (accessTokenFound: { token in
                self.socket?.emit("authenticate", ["token": token])
            }, noAccessToken: {})
            
            self.socket?.once("authenticated", callback: { _, _ in
                self.socket?.once("initialNotes") {data, ack in
                    let stringifiedJson = data[0] as? String
                    if (stringifiedJson != nil) {
                        self._onInitialNotes!(NotesToJsonService.jsonToNotesDictionary(jsonString: stringifiedJson!))
                    } else {
                        self._onInitialNotes!([:])
                    }
                }
            });
            
            
            self.socket?.on("unauthorized") {data, ack in
                self.socket?.connect()
            }
            
            self.socket?.on(clientEvent:  .disconnect) {data, ack in
                self.connected = false;
                self.socket?.connect()
            }
            
        }
    }
}
