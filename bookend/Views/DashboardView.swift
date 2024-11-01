//
//  ContentView.swift
//  bookend
//
//  Created by Chad Holmes on 11/1/24.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var books: [Book]
    @Query private var sessions: [ReadingSession]
    
    var body: some View {
        NavigationStack {
            List {
                Section("Basic Stats") {
                    HStack {
                        Text("Total Books")
                        Spacer()
                        Text("\(books.count)")
                    }
                    
                    HStack {
                        Text("Reading Sessions")
                        Spacer()
                        Text("\(sessions.count)")
                    }
                    
                    HStack {
                        Text("Pages Read")
                        Spacer()
                        Text("\(totalPagesRead)")
                    }
                }
            }
            .navigationTitle("Dashboard")
        }
    }
    
    private var totalPagesRead: Int {
        sessions.reduce(0) { sum, session in
            sum + (session.endPage - session.startPage)
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Book.self, ReadingSession.self], inMemory: true)
}
