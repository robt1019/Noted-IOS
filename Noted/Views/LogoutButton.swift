//
//  LogoutButton.swift
//  Noted
//
//  Created by Robert Taylor on 07/08/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import SwiftUI

struct LogoutButton: View {
    
    @State var logoutAlertIsVisible = false
    let onLoggedOut: () -> Void
    let onLogoutFailure: () -> Void
    
    @Environment(\.managedObjectContext)
    var viewContext
    
    var body: some View {
        Button(action: {
            self.logoutAlertIsVisible = true
        }) {
            Text("Logout")
        }.alert(isPresented: $logoutAlertIsVisible) {() ->
            Alert in
            return Alert(title: Text("Logout"), message: Text("Press continue on the next prompt to log out"), dismissButton: .default(Text("OK")){
                AuthService.logout(loggedOut: {
                    self.onLoggedOut()
                }, failed: {
                    self.onLogoutFailure()
                })
                })
        }
    }
}
