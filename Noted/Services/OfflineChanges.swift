//
//  OfflineChanges.swift
//  Noted
//
//  Created by Robert Taylor on 10/08/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import SwiftUI
import CoreData
import SocketIO

public class OfflineChanges {
    
    private static let key: String = "offlineUpdates"
    private static let defaults = UserDefaults.standard
    
    
    public static func createNote(payload: Any) {
        var offlineUpdates = defaults.array(forKey: key)
        let action = ["createNote", payload]
        if (offlineUpdates != nil) {
            offlineUpdates!.append(action)
        } else {
            offlineUpdates = [action]
        }
        defaults.set(offlineUpdates, forKey: key)
    }
    
    public static func updateNote(payload: Any) {
        var offlineUpdates = defaults.array(forKey: key)
        let action = ["updateNote", payload]
        if (offlineUpdates != nil) {
            offlineUpdates!.append(action)
        } else {
            offlineUpdates = [action]
        }
        defaults.set(offlineUpdates, forKey: key)
    }
    
    public static func deleteNote(payload: Any) {
        var offlineUpdates = defaults.array(forKey: key)
        let action = ["deleteNote", payload]
        if (offlineUpdates != nil) {
            offlineUpdates!.append(action)
        } else {
            offlineUpdates = [action]
        }
        defaults.set(offlineUpdates, forKey: key)
    }
    
    public static func processOfflineUpdates(socket: SocketIOClient?, done: @escaping () -> Void) {
        let offlineUpdates: [[Any]]? = defaults.array(forKey: key) as? [[Any]]
        if (offlineUpdates != nil && offlineUpdates?.count ?? 0 > 0) {
            socket?.emit("offlineUpdates", offlineUpdates!)
            socket?.once("offlineUpdatesProcessed") { data, ack in
                done()
            }
        } else {
            done()
        }
        
        defaults.set([], forKey: key)
    }
}
