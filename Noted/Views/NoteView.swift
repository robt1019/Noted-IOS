//
//  Note.swift
//  Noted
//
//  Created by Robert Taylor on 06/08/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import SwiftUI

struct NoteView: View {
    @ObservedObject var note: Note
    
    @State var notesTitle: String = ""
    @State var notesBody: String = ""
    
    @Environment(\.managedObjectContext)
    var viewContext
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @ObservedObject private var keyboard = KeyboardResponder()
    
    var body: some View {
        VStack (alignment: .leading) {
            Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                Text(" Notes")
            }
            
            TextField("", text: $notesTitle)
                .font(Font.system(size: 24, weight: .heavy))
                .padding()
            
            TextView(text: $notesBody)
                .frame(maxHeight: .infinity)
                .padding(.leading, 11)
        }
        .padding()
        .padding(.bottom, keyboard.currentHeight + 16)
        .edgesIgnoringSafeArea(.bottom)
        .animation(.easeOut(duration: 0.16))
        .onAppear {
            self.notesTitle = self.note.title!
            self.notesBody = self.note.body!
        }
        .onDisappear {
            Note.updateBody(note: self.note, body: self.notesBody, in: self.viewContext)
            Note.updateTitle(note: self.note, title: self.notesTitle, in: self.viewContext)
        }.navigationBarTitle("").navigationBarHidden(true)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                Note.updateBody(note: self.note, body: self.notesBody, in: self.viewContext)
                Note.updateTitle(note: self.note, title: self.notesTitle, in: self.viewContext)
        }
    }
}
