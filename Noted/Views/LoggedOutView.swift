//
//  LoggedOutView.swift
//  Noted
//
//  Created by Robert Taylor on 07/08/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import SwiftUI

struct LoggedOutView: View {
    
    let onLoggedIn: (String) -> Void
    
    var body: some View {
        Button(action: {
            AuthService.getAccessToken(accessTokenFound: {token in
                self.onLoggedIn(token)
            }, noAccessToken: {}, forceLogin: true)
        }) {
            Text("Login")
        }
    }
}
