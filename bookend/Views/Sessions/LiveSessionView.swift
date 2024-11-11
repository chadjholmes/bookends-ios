import SwiftUI
import SwiftData
import WidgetKit
import ActivityKit
import ReadingSessionExtension
import Dispatch

struct LiveSessionView: View {
    var book: Book
    var onSessionSaved: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var isRunning: Bool = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showSessionInput: Bool = false
    @State private var showToast: Bool = false
    @State private var isReadingSessionActive = false
    @State private var liveActivity: Activity<ReadingSessionAttributes>?

    @Query private var readingGoals: [ReadingGoal]
    @Query private var readingSessions: [ReadingSession]
    let semaphore = DispatchSemaphore(value: 0)

    var body: some View {
        VStack {
            // 1. Cover image of the book's cover
            if let coverImage = try? book.loadCoverImage() { // Load cover image from the Book model
                Image(uiImage: coverImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            } else {
                Text("No Cover Image Available") // Fallback if no image is available
                    .frame(height: 200)
            }

            // 2. Stopwatch with pause/resume capability
            Text(formatElapsedTime(elapsedTime)) // Format elapsed time
                .font(.largeTitle)
                .padding()

            HStack(spacing: 40) {
                // Reverse 10 Seconds Button
                Button(action: {
                    reverseTenSeconds()
                }) {
                    Image(systemName: "gobackward.10") // Use system image for reverse
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40) // Adjust size as needed
                }

                // Play/Pause Button
                Button(action: {
                    if isRunning {
                        pauseTimer()
                    } else {
                        startTimer()
                    }
                }) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill") // Use system images for play/pause
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40) // Adjust size as needed
                }

                // Fast Forward 10 Seconds Button
                Button(action: {
                    fastForwardTenSeconds()
                }) {
                    Image(systemName: "goforward.10") // Use system image for fast forward
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40) // Adjust size as needed
                }
            }
            .padding()

            // 3. Start Page indicator
            Text("Start Page: \(book.currentPage)") // Display current page from the Book model
                .font(.headline)
                .padding()

            // Navigation link to save session
            Button(action: {
                showSessionInput = false
                isReadingSessionActive = true
            }) {
                Text("Save Session")
            }
        }
        .navigationDestination(isPresented: $isReadingSessionActive) {
            ReadingSessionView(
                book: book,
                currentPage: .constant(book.currentPage),
                duration: Int(elapsedTime),
                onSessionAdded: { session in
                    isReadingSessionActive = false
                    dismiss() // Dismiss LiveSessionView
                    onSessionSaved?() // Trigger toast in BookView
                    endLiveActivity() // End live activity when session is saved
                }
            )
        }
        .onDisappear {
            timer?.invalidate() // Invalidate timer when view disappears
            Task.detached {
                await endLiveActivity() // End live activity when view disappears
            }
        }
    }

    // Timer functions
    private func startTimer() {
        isRunning = true
        startLiveActivity() // Start Live Activity when the timer starts
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
            updateLiveActivity() // Update live activity with new elapsed time
        }
    }

    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
    }

    // Reverse 10 seconds
    private func reverseTenSeconds() {
        elapsedTime = max(0, elapsedTime - 10) // Ensure elapsed time doesn't go below 0
    }

    // Fast forward 10 seconds
    private func fastForwardTenSeconds() {
        elapsedTime += 10 // Increase elapsed time by 10 seconds
    }

    // Custom function to format elapsed time
    private func formatElapsedTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds) // HH:mm:ss
        } else {
            return String(format: "%02d:%02d", minutes, seconds) // mm:ss
        }
    }

    // Timer functions
    private func startLiveActivity() {
        let attributes = ReadingSessionAttributes(title: book.title, author: book.author)
        let dailyGoal = readingGoals.filter { $0.period == .daily }.first
        let dailyGoalTarget = (dailyGoal?.target ?? 0) * 60 ?? 0 // Convert minutes to seconds
        // ^^ SWIFT IS WEIRD
        print("readingSessions: \(readingSessions)")
        let existingProgress = dailyGoal?.calculateProgress(from: readingSessions) ?? 0.0
        print("existingProgress: \(existingProgress)")
        let initialState = ReadingSessionAttributes.ContentState(
          elapsedTime: formatElapsedTime(elapsedTime),
          dailyGoalProgress: (existingProgress + (elapsedTime / Double(dailyGoalTarget)))
        )
        do {
            liveActivity = try Activity<ReadingSessionAttributes>.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
        } catch {
            print("Failed to start live activity: \(error.localizedDescription)")
        }
    }

    private func updateLiveActivity() {
        guard let activity = liveActivity else { return }
        let dailyGoal = readingGoals.filter { $0.period == .daily }.first
        let dailyGoalTarget = (dailyGoal?.target ?? 0) * 60 ?? 0 // Convert minutes to seconds
        // ^^ SWIFT IS WEIRD
        let existingProgress = dailyGoal?.calculateProgress(from: readingSessions) ?? 0.0
        let updatedState = ReadingSessionAttributes.ContentState(
          elapsedTime: formatElapsedTime(elapsedTime),
          dailyGoalProgress: (existingProgress + (elapsedTime / Double(dailyGoalTarget)))
        )
        Task {
            await activity.update(using: updatedState)
        }
    }

    private func endLiveActivity() {
        guard let activity = liveActivity else { return }
        Task {
            await activity.end(dismissalPolicy: .immediate)
        }
        semaphore.signal() // Signal the semaphore
    }
    
}

// Preview
struct LiveSessionView_Previews: PreviewProvider {
    static var previews: some View {
        let mockBook = Book(
            title: "Sample Book",
            author: "Author Name",
            totalPages: 100,
            currentPage: 1,
            externalReference: [:]
        )
        
        // Create mock reading sessions with correct initializer
        let mockSessions = [
            ReadingSession(id: UUID(), book: mockBook, startPage: 1, endPage: 2, duration: 1200, date: Date()), // 20 minutes
            ReadingSession(id: UUID(), book: mockBook, startPage: 1, endPage: 2, duration: 1800, date: Date().addingTimeInterval(-86400)) // 30 minutes yesterday
        ]
        
        // Create mock reading goals
        let mockGoals = [
            ReadingGoal(type: .minutes, target: 30, period: .daily, isActive: true),
            ReadingGoal(type: .minutes, target: 300, period: .weekly, isActive: true)
        ]
        
        // Create a model container for the preview
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: ReadingGoal.self, ReadingSession.self, configurations: config)
        
        return Group {
            // Light mode preview
            LiveSessionView(book: mockBook, onSessionSaved: {})
                .previewLayout(.sizeThatFits)
                .padding()
            
            // Dark mode preview
            LiveSessionView(book: mockBook, onSessionSaved: {})
                .preferredColorScheme(.dark)
                .previewLayout(.sizeThatFits)
                .padding()
        }
    }
}
