//
//  ContentView.swift
//  Noted
//
//  Created by Robert Taylor on 06/08/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext)
    var viewContext   
    
    var body: some View {
        NavigationView {
            NotesView()
                .navigationBarTitle(Text("Notes"))
                .navigationBarItems(
                    trailing: Button(
                        action: {
                            withAnimation { Note.create(in: self.viewContext) }
                    }
                    ) {
                        Image(systemName: "plus")
                    }.padding()
            )
        }.navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
    
}

struct NotesView: View {
    
    @FetchRequest(sortDescriptors: [])
    var notes: FetchedResults<Note>
    
    @Environment(\.managedObjectContext)
    var viewContext
    
    var body: some View {
        List {
            ForEach(self.notes, id: \.self) { (note: Note) in
                NavigationLink(destination: NoteView(note: note)) {
                    Text(note.title!)
                }
            }.onDelete { indices in
                self.notes.delete(at: indices, from: self.viewContext)
            }
        }
    }
}

struct NoteView: View {
    @ObservedObject var note: Note
    
    @State var notesTitle: String = ""
    @State var notesBody: String = ""
    
    @Environment(\.managedObjectContext)
    var viewContext
    
    @ObservedObject private var keyboard = KeyboardResponder()
    
    var body: some View {
        VStack {
            TextField("", text: $notesTitle)
                .font(Font.system(size: 24, weight: .heavy))
                .padding()
            
            TextView(text: $notesBody)
            .frame(maxHeight: .infinity)
            .padding(.leading, 11)
            }
            .padding()
            .padding(.bottom, keyboard.currentHeight)
            .edgesIgnoringSafeArea(.bottom)
            .animation(.easeOut(duration: 0.16))
            .onAppear {
                self.notesTitle = self.note.title!
                self.notesBody = self.note.body!
            }
            .onDisappear {
                Note.updateBody(note: self.note, body: self.notesBody, in: self.viewContext)
                Note.updateTitle(note: self.note, title: self.notesTitle, in: self.viewContext)
            }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return ContentView().environment(\.managedObjectContext, context)
    }
}
