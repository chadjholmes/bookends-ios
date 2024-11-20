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
    @Environment(\.presentationMode) var presentationMode
    @State private var isRunning: Bool = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showSessionInput: Bool = false
    @State private var showToast: Bool = false
    @State private var isReadingSessionActive = false
    @State private var liveActivity: Activity<ReadingSessionAttributes>?
    @State private var sessionStartDate: Date?
    @State private var sessionLastUpdated: Date?

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
            if isRunning {
                Text(Date(timeIntervalSinceNow: -elapsedTime), style: .timer)
                    .font(.largeTitle)
                    .padding()
            } else {
                Text(formatElapsedTime(elapsedTime))
                    .font(.largeTitle)
                    .padding()
            }

            HStack(spacing: 40) {
                // Reverse 10 Seconds Button
                Button(action: {
                    reverseTenSeconds()
                }) {
                    Image(systemName: "gobackward.10") // Use system image for reverse
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40) // Adjust size as needed
                        .foregroundStyle(Color("Accent1"))
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
                        .foregroundStyle(Color("Accent1"))
                }

                // Fast Forward 10 Seconds Button
                Button(action: {
                    fastForwardTenSeconds()
                }) {
                    Image(systemName: "goforward.10") // Use system image for fast forward
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40) // Adjust size as needed
                        .foregroundStyle(Color("Accent1"))
                }
            }
            .padding()

            // 3. Start Page indicator
            Text("Start Page: \(book.currentPage)") // Display current page from the Book model
                .font(.headline)
                .padding()

            // Navigation link to save session
            Button(action: {
                if(isRunning) {
                    pauseTimer()
                }
                showSessionInput = false
                isReadingSessionActive = true
            }) {
                Text("Save Session")
                    .bold()
                    .padding()
                    .background(Color("Accent1"))
                    .cornerRadius(20)
                    .foregroundColor(.white)
            }
            .padding(.top, 50)
        }
        .navigationDestination(isPresented: $isReadingSessionActive) {
            ReadingSessionView(
                book: book,
                currentPage: .constant(book.currentPage),
                duration: Int(elapsedTime),
                onSessionAdded: { session in
                    isReadingSessionActive = false
                    dismissToBooksView() // Dismiss LiveSessionView and ReadingSessionView
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

    private func dismissToBooksView() {
        // Dismiss the current view (ReadingSessionView)
        presentationMode.wrappedValue.dismiss()
        // Dismiss the previous view (LiveSessionView)
        DispatchQueue.main.async {
            presentationMode.wrappedValue.dismiss()
        }
    }

    // Timer functions
    private func startTimer() {
        isRunning = true
        if sessionStartDate == nil {
            // First time starting
            sessionStartDate = Date()
            sessionLastUpdated = Date()
            startLiveActivity()
        } else {
            // Resuming from pause
            sessionLastUpdated = Date()
            updateLiveActivity()
        }
    }

    private func pauseTimer() {
        isRunning = false
        elapsedTime += Date().timeIntervalSince(sessionLastUpdated ?? Date())
        updateLiveActivity()
        print("elapsedTimeDouble: \(elapsedTime)")
        print("elapsedTimeInt: \(Int(elapsedTime))")
    }

    // Reverse 10 seconds
    private func reverseTenSeconds() {
        elapsedTime = max(0, elapsedTime - 10) // Ensure elapsed time doesn't go below 0
    }

    // Fast forward 10 seconds
    private func fastForwardTenSeconds() {
        elapsedTime += 10 // Increase elapsed time by 10 seconds
    }


    // Timer functions
    private func startLiveActivity() {
        // Process and scale down the cover image
        var compressedImageData: Data? = nil
        
        if let coverImage = try? book.loadCoverImage() {
            print("loaded cover for live activity")
            let maxDimension: CGFloat = 100
            let scale = min(maxDimension / coverImage.size.width, maxDimension / coverImage.size.height)
            let newSize = CGSize(width: coverImage.size.width * scale, height: coverImage.size.height * scale)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            coverImage.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            var compressionQuality: CGFloat = 0.5
            while compressionQuality > 0.1 {
                if let data = resizedImage?.jpegData(compressionQuality: compressionQuality) {
                    if data.count < 2500 {
                        compressedImageData = data
                        print("Final compressed size: \(data.count) bytes with quality: \(compressionQuality)")
                        break
                    }
                }
                compressionQuality -= 0.05
            }
        }
        else {
            print("could not load cover for live activity")
            let previewImage = UIImage(named: "book-cover-placeholder") ??
                              UIImage(systemName: "book.closed.fill") ??
                              UIImage()
            
            let maxDimension: CGFloat = 100
            let scale = min(maxDimension / previewImage.size.width, maxDimension / previewImage.size.height)
            let newSize = CGSize(width: previewImage.size.width * scale, height: previewImage.size.height * scale)
            
            // Resize image
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            previewImage.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            // Compress with the same logic
            var compressionQuality: CGFloat = 0.5
            while compressionQuality > 0.1 {
                if let data = resizedImage?.jpegData(compressionQuality: compressionQuality) {
                    if data.count < 3000 {
                        compressedImageData = data
                        break
                    }
                }
                compressionQuality -= 0.05
            }
        }

        let dailyGoal = readingGoals.filter { $0.period == .daily }.first
        let dailyGoalTarget = Double(dailyGoal?.target ?? 60) * 60

        let attributes = ReadingSessionAttributes(
            title: book.title, 
            author: book.author,
            coverImageData: compressedImageData,
            dailyGoalTarget: Int(dailyGoalTarget)
        )
    
        let existingProgress = dailyGoal?.calculateProgress(from: readingSessions, on: sessionStartDate ?? Date()) ?? 0.0
        let progress = min(existingProgress + (elapsedTime / dailyGoalTarget), 1.0)
        
        let initialState = ReadingSessionAttributes.ContentState(
            elapsedTime: elapsedTime,
            dailyGoalProgress: progress,
            startDate: sessionStartDate ?? Date(),
            isTimerRunning: true
        )
        
        do {
            liveActivity = try Activity<ReadingSessionAttributes>.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
        } catch {
            print("Failed to start live activity: \(error)")
            print("Attributes: \(attributes)")
            print("Initial State: \(initialState)")
        }
    }

    private func updateLiveActivity() {
        guard let activity = liveActivity else { return }
        
        let dailyGoal = readingGoals.filter { $0.period == .daily }.first
        let dailyGoalTarget = Double(dailyGoal?.target ?? 60) * 60
        let existingProgress = dailyGoal?.calculateProgress(from: readingSessions, on: sessionStartDate ?? Date()) ?? 0.0
        let progress = min(existingProgress + (elapsedTime / dailyGoalTarget), 1.0)
        
        let updatedState = ReadingSessionAttributes.ContentState(
            elapsedTime: elapsedTime,
            dailyGoalProgress: progress,
            startDate: sessionLastUpdated ?? Date(),
            isTimerRunning: isRunning
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

    func formatElapsedTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds) // h:mm:ss
        } else {
            return String(format: "%d:%02d", minutes, seconds) // m:ss
        }
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
