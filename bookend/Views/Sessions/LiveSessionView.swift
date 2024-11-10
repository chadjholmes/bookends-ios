import SwiftUI

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
                }
            )
        }
        .onDisappear {
            timer?.invalidate() // Invalidate timer when view disappears
        }
    }

    // Timer functions
    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
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
}

// Preview
struct LiveSessionView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock Book instance for preview
        let mockBook = Book(
            title: "Sample Book",
            author: "Author Name",
            totalPages: 100,
            currentPage: 1,
            externalReference: [:]
        )
        
        LiveSessionView(book: mockBook)
            .previewLayout(.sizeThatFits) // Adjust the preview layout
            .padding() // Add padding for better visibility
    }
}
