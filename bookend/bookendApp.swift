//
//  bookendApp.swift
//  bookend
//
//  Created by Chad Holmes on 11/1/24.
//

import SwiftUI
import SwiftData

@main
struct bookendApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Book.self,
            ReadingSession.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            LandingView()
        }
        .modelContainer(sharedModelContainer)
    }
}
