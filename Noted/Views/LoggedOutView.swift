//
//  LoggedOutView.swift
//  Noted
//
//  Created by Robert Taylor on 07/08/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import SwiftUI

struct LoggedOutView: View {
    
    let onLoggedIn: () -> Void
    
    var body: some View {
        Button(action: {
            AuthService.getAccessToken(accessTokenFound: {token in
                self.onLoggedIn()
            }, noAccessToken: {
                print("could not log in")
            })
        }) {
            Text("Login")
        }
    }
}
