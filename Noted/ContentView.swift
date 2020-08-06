//
//  ContentView.swift
//  Noted
//
//  Created by Robert Taylor on 06/08/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import SwiftUI

private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .medium
    return dateFormatter
}()

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
                    }
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

struct DetailView: View {
    @ObservedObject var event: Event
    
    var body: some View {
        Text("\(event.timestamp!, formatter: dateFormatter)")
            .navigationBarTitle(Text("Detail"))
    }
}

struct NoteView: View {
    @ObservedObject var note: Note
    var body: some View {
        VStack {
            Text(note.title!).fontWeight(.bold)
            Text(note.body!)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return ContentView().environment(\.managedObjectContext, context)
    }
}
