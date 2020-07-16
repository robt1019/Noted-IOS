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
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
