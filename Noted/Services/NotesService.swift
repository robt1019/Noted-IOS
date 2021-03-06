//
//  NotesService.swift
//  Noted
//
//  Created by Robert Taylor on 28/07/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import Foundation
import SocketIO
import Network
import CoreData

open class NotesService {
    
    public static let shared = NotesService()
    
    private var socketManager: SocketManager? = nil
    private var socket: SocketIOClient? = nil
    private var authenticated = false
    
    private var _onNoteCreated: ((String, String, String) -> Void)? = nil
    private var _onNoteUpdated: ((String, Any, Any) -> Void)? = nil
    private var _onInitialNotes: ((Dictionary<String, JsonReadyNote>) -> Void)? = nil
    private var _onNoteDeleted: ((String) -> Void)? = nil
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "Monitor")
    public var online = false
    
    init() {
        self.monitorOnlineStatus()
    }
    
    public func reconnect() {
        self.socket?.connect()
    }
    
    public func createNote(id: String, title: String, body: String, context: NSManagedObjectContext) {
        let payload: [String: Any] = [
            "id": id,
            "title": title,
            "body": body,
        ]
        var serverGotTheMessage = false
        self.socket?.emitWithAck("createNote", payload).timingOut(after: 0) { _ in
            serverGotTheMessage = true
        }
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) {_ in
            if(!serverGotTheMessage) {
                Note.create(in: context, noteId: id, title: title, body: body)
                OfflineChanges.createNote(payload: payload)
                self.socket?.connect()
            }
        }
    }
    
    public func updateNote(prevTitle: String, prevBody: String, id: String, title: String, body: String, context: NSManagedObjectContext) {
        let titleDiff = NotesDiffer.shared.diff(notes1: prevTitle, notes2: title)
        let bodyDiff = NotesDiffer.shared.diff(notes1: prevBody, notes2: body)
        let payload: [String: Any] = [
            "id": id,
            "title": titleDiff,
            "body": bodyDiff,
        ]
        var serverGotTheMessage = false
        self.socket?.emitWithAck("updateNote", payload).timingOut(after: 0) { _ in
            serverGotTheMessage = true;
        }
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) {_ in
            if(!serverGotTheMessage) {
                print("server did not get the message :( ")
                let note = Note.noteById(id: id, in: context)
                Note.updateTitle(note: note!, title: title, in: context)
                Note.updateBody(note: note!, body: body, in: context)
                OfflineChanges.updateNote(payload: payload)
                self.socket?.connect()
            }
        }
    }
    
    public func deleteNote(id: String, context: NSManagedObjectContext) {
        
        var serverGotTheMessage = false
    
        self.socket?.emitWithAck("deleteNote", id).timingOut(after: 0) { _ in
            serverGotTheMessage = true
        }
    
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            if(!serverGotTheMessage) {
                let note = Note.noteById(id: id, in: context)
                Note.deleteNote(note: note!, in: context)
                OfflineChanges.deleteNote(payload: id)
                self.socket?.connect()
            }
        }
    }
    
    public func onNoteCreated(callback: @escaping (String, String, String) -> Void) {
        self._onNoteCreated = callback
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
    
    public func connectToSocket(token: String) {
        
        self.socket?.disconnect()
        
        self.socketManager = SocketManager(socketURL: URL(string: infoForKey("Notes API")!)!, config: [.log(false), .compress])
        self.socket = self.socketManager?.defaultSocket
        
        self.socket?.connect()
        
        self.socket?.on("noteCreated") {data, ack in
            let jsonData = data[0] as! NSDictionary
            let id = jsonData["id"]
            let title = jsonData["title"]
            let body = jsonData["body"]
            self._onNoteCreated!(id as! String, title as! String, body as! String)
        }
        
        self.socket?.on("noteUpdated") {data, ack in
            let jsonData = data[0] as! NSDictionary
            let id = jsonData["id"]
            let title = jsonData["title"]
            let body = jsonData["body"]
            self._onNoteUpdated!(id as! String, title as Any, body as Any)
        }
        
        self.socket?.on("noteDeleted") {data, ack in
            self._onNoteDeleted!(data[0] as! String)
        }
        
        self.socket?.on(clientEvent: .connect) {data, ack in
            self.authenticated = true;
            
            AuthService.getAccessToken (accessTokenFound: { token in
                self.socket?.emit("authenticate", ["token": token])
            }, noAccessToken: {}, forceLogin: true)
            
            self.socket?.once("authenticated", callback: { _, _ in
                
                OfflineChanges.processOfflineUpdates(socket: self.socket) {
                    self.socket?.emit("getInitialNotes")
                }
                
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
                self.authenticated = false;
                self.socket?.connect()
            }
            
        }
    }
    
    private func monitorOnlineStatus() {
        self.monitor.pathUpdateHandler = { path in
            if (path.status == .satisfied) {
                if (self.authenticated) {
                    self.socket?.connect()
                } else {
                    AuthService.getAccessToken(accessTokenFound: {token in
                        self.connectToSocket(token: token)
                    }, noAccessToken: {}, forceLogin: false)
                }
                self.online = true
            } else {
                self.online = false
            }
        }
        self.monitor.start(queue: self.queue)
    }
}
