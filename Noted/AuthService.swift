//
//  AuthService.swift
//  Noted
//
//  Created by Robert Taylor on 28/07/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import Foundation
import Auth0

class AuthService {
    static func login(onSuccess: @escaping (Credentials) -> Void, onFailure: @escaping () -> Void) {
        print("logging in")
        Auth0
            .webAuth()
            .scope("openid offline_access")
            .audience("https://glacial-badlands-85832.herokuapp.com")
            .start {
                switch $0 {
                case .failure(let error):
                    // Handle the error
                    print("Failed to login")
                    print("Error: \(error)")
                    onFailure()
                case .success(let credentials):
                    print("logged in")
                    onSuccess(credentials)
                }
        }
    }
}
