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
    
    static func hasCredentials() -> Bool {
        let credentialsManager = CredentialsManager(authentication: Auth0.authentication(clientId: infoForKey("Auth0 clientid")!, domain: infoForKey("Auth0 domain")!))
        return credentialsManager.hasValid()
    }
    
    static func login(onSuccess: @escaping (Credentials) -> Void, onFailure: @escaping () -> Void) {
        Auth0
            .webAuth(clientId: infoForKey("Auth0 clientid")!, domain: infoForKey("Auth0 domain")!)
            .scope("openid offline_access")
            .audience(infoForKey("Notes API")!)
            .start {
                switch $0 {
                case .failure(let error):
                    // Handle the error
                    onFailure()
                case .success(let credentials):
                    onSuccess(credentials)
                }
        }
    }
    
    static func logout(loggedOut: @escaping () -> Void, failed: @escaping () -> Void) {
        let credentialsManager = CredentialsManager(authentication: Auth0.authentication(clientId: infoForKey("Auth0 clientid")!, domain: infoForKey("Auth0 domain")!))
        credentialsManager.clear()
        Auth0
            .webAuth(clientId: infoForKey("Auth0 clientid")!, domain: infoForKey("Auth0 domain")!)
            .clearSession(federated:false) {
                switch $0 {
                case true:
                    loggedOut()
                case false:
                    failed()
                }
        }
    }
    
    static func getAccessToken(accessTokenFound: @escaping (String) -> Void, noAccessToken: @escaping () -> Void, forceLogin: Bool) {
        let credentialsManager = CredentialsManager(authentication: Auth0.authentication(clientId: infoForKey("Auth0 clientid")!, domain: infoForKey("Auth0 domain")!))
        if(credentialsManager.hasValid()) {
            credentialsManager.credentials(callback: {err, credentials in
                if(err != nil) {
                    if(forceLogin) {
                        login(onSuccess: {  credentials in
                            credentialsManager.store(credentials: credentials)
                            accessTokenFound(credentials.accessToken!)
                        }, onFailure: {
                            noAccessToken()
                        })
                    } else {
                        noAccessToken()
                    }
                } else {
                    accessTokenFound((credentials?.accessToken)!)
                }
            })
        } else {
            if(forceLogin) {
                login(onSuccess: {  credentials in
                    credentialsManager.store(credentials: credentials)
                    accessTokenFound(credentials.accessToken!)
                }, onFailure: {})
            }
        }
    }
}
