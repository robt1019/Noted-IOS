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
    
    static func logout(loggedOut: @escaping () -> Void, failed: @escaping () -> Void) {
        let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
        credentialsManager.clear()
        Auth0
            .webAuth()
            .clearSession(federated:false) {
                switch $0 {
                case true:
                    print("logged out")
                    loggedOut()
                case false:
                    print("oh noes. Could not log out")
                    failed()
                }
        }
    }
    
    static func getAccessToken(accessTokenFound: @escaping (String) -> Void, noAccessToken: @escaping () -> Void) {
        let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
        if(credentialsManager.hasValid()) {
            credentialsManager.credentials(callback: {err, credentials in
                if(err != nil) {
                    print("problem with credentials manager")
                    print(err)
                    login(onSuccess: {  credentials in
                        print("storing creds")
                        credentialsManager.store(credentials: credentials)
                        accessTokenFound(credentials.accessToken!)
                    }, onFailure: {
                        noAccessToken()
                    })
                } else {
                    print("using stored credentials")
                    accessTokenFound((credentials?.accessToken)!)
                }
            })
        } else {
            print("no credentials stored")
            let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
            login(onSuccess: {  credentials in
                print("storing creds")
                credentialsManager.store(credentials: credentials)
                accessTokenFound(credentials.accessToken!)
            }, onFailure: {
                print("whoopsie")
            })
        }
    }
}
