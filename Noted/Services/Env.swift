//
//  File.swift
//  Noted
//
//  Created by Robert Taylor on 17/08/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import Foundation

func infoForKey(_ key: String) -> String? {
        return (Bundle.main.infoDictionary?[key] as? String)?
            .replacingOccurrences(of: "\\", with: "")
 }
