//
//  NotesDiffer.swift
//  Noted
//
//  Created by Robert Taylor on 05/08/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import UIKit
import JavaScriptCore

class NotesDiffer: NSObject {
    
    static let shared = NotesDiffer()
    private let vm = JSVirtualMachine()
    private let context: JSContext

    override init() {
        let jsCode = try? String.init(contentsOf: Bundle.main.url(forResource: "Noted.bundle", withExtension: "js")!)
        self.context = JSContext(virtualMachine: self.vm)
        self.context.evaluateScript(jsCode)
    }
    
    func diff(notes1: String, notes2: String) -> [Any] {
        let jsModule = self.context.objectForKeyedSubscript("Noted")
        let diffMatchPatch = jsModule?.objectForKeyedSubscript("diffMatchPatch")
        let result = diffMatchPatch!.objectForKeyedSubscript("diff_main").call(withArguments: [notes1, notes2])
        return (result!.toArray())
    }
    
    func patch(notes1: String, diff: Any) -> String {
        let jsModule = self.context.objectForKeyedSubscript("Noted")
        let diffMatchPatch = jsModule?.objectForKeyedSubscript("diffMatchPatch")
        let patch = diffMatchPatch!.objectForKeyedSubscript("patch_make").call(withArguments: [notes1, diff])
        let patched = diffMatchPatch!.objectForKeyedSubscript("patch_apply").call(withArguments: [patch, notes1])
        return (patched?.toArray()[0])! as! String
    }
}
