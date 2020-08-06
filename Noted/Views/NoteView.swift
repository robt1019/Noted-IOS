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
    
    @Environment(\.managedObjectContext)
    var viewContext
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @ObservedObject private var keyboard = KeyboardResponder()
    
    @State var noteTitle = ""
    @State var noteBody = ""
    
    let onNoteUpdated: (Note) -> Void
    
    var body: some View {
        VStack (alignment: .leading) {
            Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                Text(" Notes")
            }
            
            TextField("", text: $noteTitle)
                .font(Font.system(size: 24, weight: .heavy))
                .padding()
            
            TextView(text: $noteBody)
                .frame(maxHeight: .infinity)
                .padding(.leading, 11)
        }
        .padding()
        .padding(.bottom, keyboard.currentHeight + 16)
        .edgesIgnoringSafeArea(.bottom)
        .animation(.easeOut(duration: 0.16))
        .navigationBarTitle("").navigationBarHidden(true)
        .onAppear {
            self.noteTitle = self.note.title!
            self.noteBody = self.note.body!
        }
        .onDisappear {
            self.note.title = self.noteTitle
            self.note.body = self.noteBody
            self.onNoteUpdated(self.note)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            self.note.title = self.noteTitle
            self.note.body = self.noteBody
            self.onNoteUpdated(self.note)
        }
    }
}
