//
//  ContentView.swift
//  Noted
//
//  Created by Robert Taylor on 16/07/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @State private var message = ""
    @State private var textStyle = UIFont.TextStyle.body
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            TextView(text: $message, textStyle: $textStyle)
                .padding(.horizontal)
            Button(action: {
                self.closeKeyboard()
                self.saveNotes()
            }) {
                Text("Save")
            }
            .padding()
        }.onAppear {
            self.getNotes()
        }
    }
    
    func getNotes() {
        let session = URLSession.shared
        let url = URL(string: "https://glacial-badlands-85832.herokuapp.com/notes")!
        
        let task = session.dataTask(with: url, completionHandler: { data, response, error in
            
            if let json = try? JSONSerialization.jsonObject(with: data!, options: []) {
                let jsonDict = json as? NSDictionary
                self.message = jsonDict?["content"] as! String
            }
        })
        
        task.resume()
    }
    
    func saveNotes() {
        let session = URLSession.shared
        let url = URL(string: "https://glacial-badlands-85832.herokuapp.com/notes")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let json = [
            "username": "robt1019",
            "content": self.message
        ]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        
        let task = session.uploadTask(with: request, from: Data(jsonData)) { data, response, error in
        }
        
        task.resume()
    }
    
    func closeKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
