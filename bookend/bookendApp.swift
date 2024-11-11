//
//  bookendApp.swift
//  bookend
//
//  Created by Chad Holmes on 11/1/24.
//

import SwiftUI
import SwiftData
import ActivityKit
import Dispatch

@main
struct BookendApp: App {
    let modelContainer: ModelContainer
    @Environment(\.scenePhase) private var scenePhase
    let semaphore = DispatchSemaphore(value: 0)
    
    init() {
        do {
            print("\n=== Initializing ModelContainer ===")
            
            let schema = Schema([
                Book.self,
                ReadingSession.self,
                ReadingGoal.self,
                BookGroup.self,
                BookGroupRelationship.self
            ])
            
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            print("\nCreating container...")
            modelContainer = try ModelContainer(
                for: schema,
                configurations: config
            )
            print("✅ ModelContainer initialized successfully")
            
        } catch {
            print("❌ Failed to initialize ModelContainer: \(error)")
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            LandingView()
                .modelContainer(modelContainer)
                .accentColor(.purple)
                .onDisappear {
                    Task.detached {
                        for activity in Activity<ReadingSessionAttributes>.activities {
                            do {
                                await activity.end(dismissalPolicy: .immediate)
                            } catch {
                                print("Error ending activity: \(error.localizedDescription)")
                            }
                        }
                        print("✅ All live activities ended.")
                        semaphore.signal()
                    }
                    semaphore.wait() // Wait for the signal after starting the task
                }
            
        }
        
        
    }
}
