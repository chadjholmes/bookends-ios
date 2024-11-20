import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [Book]
    @Query private var goals: [ReadingGoal]
    @Query private var sessions: [ReadingSession]
    @State private var showingAddBook = false
    @State private var wiggle = false
    @State private var imageOffset: CGFloat = UIScreen.main.bounds.height
    @State private var rotationAngle: Double = 0
    @State private var showSpeechBubble = false
    @State private var idleTimer: Timer?
    @State private var remainingIdleTime: TimeInterval = 15.0
    @State private var slideTimer: Timer?
    @State private var isAnimating = false
    
    var body: some View {
        NavigationStack {
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            
            ScrollView {
                ZStack {
                    VStack(alignment: .leading) {
                        Spacer()
                            .padding(.bottom, screenHeight * 0.1)
                        GoalRings(goals: goals, sessions: sessions)
                            .frame(maxWidth: screenWidth, alignment: .center)
                            .padding(.horizontal, screenWidth * 0.05)
                        Text("Jump back in...")
                            .bold()
                            .frame(maxWidth: screenWidth, alignment: .leading)
                            .padding(.leading, screenWidth * 0.05)
                            .font(.system(size: screenWidth * 0.035))
                        if books.isEmpty {
                            EmptyBooksList(showingAddBook: $showingAddBook)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            BookCarousel(books: books, modelContext: modelContext)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, screenWidth * 0.05)
                        }
                    }
                    .padding(.bottom, screenHeight * 0.025)
                    .onAppear {
                        resetIdleTimer() // Reset the idle timer when the view appears
                        resumeIdleTimer() // Resume the idle timer when the view appears
                    }
                    .onDisappear {
                        pauseIdleTimer() // Pause the idle timer when the view disappears
                        resetAnimationState() // Reset animation state
                    }
                    .onTapGesture {
                        resetIdleTimer() // Reset the idle timer on user interaction
                    }

                    if isAnimating {
                        VStack {
                            Spacer()
                                .padding(.bottom, screenHeight * 0.1)
                            
                            ZStack(alignment: .center) {
                                Button(action: {
                                    isAnimating = false // Set isAnimating to false when the button is tapped
                                }) {
                                    Image("King")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: screenWidth * 0.75)
                                        .offset(y: imageOffset - screenHeight * 0.065)
                                        .rotationEffect(.degrees(rotationAngle))
                                        .zIndex(1)
                                }
                                
                                if showSpeechBubble {
                                    Button(action: {
                                        isAnimating = false // Set isAnimating to false when the speech bubble button is tapped
                                    }) {
                                        Text("Why dost thou linger? Read thy books!")
                                            .padding()
                                            .background(Color.white.opacity(1.0))
                                            .foregroundColor(Color("Accent3"))
                                            .cornerRadius(10)
                                            .offset(y: screenHeight * 0.06)
                                            .font(.system(size: screenWidth * 0.030))
                                            .zIndex(2)
                                    }
                                }
                            }
                        }
        
                    }
                }
            }
            .scrollDisabled(true)
            .navigationBarHidden(true)
            .edgesIgnoringSafeArea(.top)
            .sheet(isPresented: $showingAddBook) {
                BookAddView()
            }
            .background(Color("Primary"))
        }
        .background(Color("Primary"))
    }
    
    private func startAnimationCycle() {
        slideImage()
    }
    
    private func resetAnimationState() {
        idleTimer?.invalidate()
        idleTimer = nil
        slideTimer?.invalidate()
        slideTimer = nil
        imageOffset = UIScreen.main.bounds.height
        rotationAngle = 0
        showSpeechBubble = false
    }
    
    private func slideImage() {
        withAnimation(Animation.easeIn(duration: 5.0)) {
            imageOffset = UIScreen.main.bounds.height * 0.1
        }
        
        // Delay the wiggle animation until the slide-in is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation(Animation.easeInOut(duration: 0.25).repeatForever(autoreverses: true)) {
                rotationAngle = 5 // Add a small rotation for the wiggle effect
            }
            showSpeechBubble = true
        }
        
        slideTimer?.invalidate()
        slideTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            // Check if the image should disappear
            if self.remainingIdleTime <= 0 {
                withAnimation {
                    self.imageOffset = UIScreen.main.bounds.height // Move the image off-screen
                    self.rotationAngle = 0 // Reset rotation
                    self.showSpeechBubble = false // Hide the speech bubble
                }
                timer.invalidate() // Stop the timer
            }
        }
        
        // Set the time after which the image should disappear
        remainingIdleTime = 5.0
    }
    
    private func resumeIdleTimer() {
        idleTimer?.invalidate() // Invalidate any existing idle timer
        idleTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            remainingIdleTime -= 1
            if remainingIdleTime <= 0 {
                timer.invalidate()
                isAnimating = true
                startAnimationCycle() // Start animation when idle time is up
            }
        }
    }
    
    private func pauseIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = nil
    }
    
    private func resetIdleTimer() {
        remainingIdleTime = 15.0
        resumeIdleTimer()
    }
}

private struct EmptyBooksList: View {
    @Binding var showingAddBook: Bool
    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        VStack {
            Text("No books added yet.")
                .foregroundColor(.gray)
                .font(.system(size: screenWidth * 0.04))
                .padding(.bottom, screenHeight * 0.025)
            
            Button(action: {
                showingAddBook = true
            }) {
                Text("Add a Book")
                    .font(.system(size: screenWidth * 0.04))
                    .foregroundColor(Color("Accent1"))
                    .padding(.vertical, screenHeight * 0.015)
                    .padding(.horizontal, screenWidth * 0.05)
                    .cornerRadius(8)
            }
            .background(Color("Accent1").opacity(0.2))
            .cornerRadius(12)
        }
        .padding(.bottom, screenHeight * 0.1)
    }
}

private struct BookCarousel: View {
    let books: [Book]
    let modelContext: ModelContext
    @Query private var allSessions: [ReadingSession]
    
    var sortedBooks: [Book] {
        Array(books.sorted { book1, book2 in
            let lastSession1 = allSessions
                .filter { $0.book?.persistentModelID == book1.persistentModelID }
                .max(by: { $0.date < $1.date })?.date ?? .distantPast
            let lastSession2 = allSessions
                .filter { $0.book?.persistentModelID == book2.persistentModelID }
                .max(by: { $0.date < $1.date })?.date ?? .distantPast
            return lastSession1 > lastSession2
        }
        .prefix(10))
    }
    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: screenWidth * 0.05) {
                ForEach(sortedBooks) { book in
                    BookCard(book: book, onDelete: {
                        book.cleanupStoredImage()
                        modelContext.delete(book)
                    }, currentGroup: nil)
                }
            }
            .padding(.horizontal, screenWidth * 0.05)
        }
        .frame(height: screenHeight * 0.25)
        .padding(.bottom, screenHeight * 0.1)
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Book.self, ReadingGoal.self, ReadingSession.self, configurations: config)
        
        // Add sample data
        let context = container.mainContext
        
        // Create a sample book
        let book = Book(
            title: "The Great Gatsby", 
            author: "F. Scott Fitzgerald",
            totalPages: 180,
            externalReference: ["openLibraryKey": "OL26874A"]
        )
        context.insert(book)
        
        // Create a sample reading goal
        let goal = ReadingGoal(
            type: .books,
            target: 12,
            period: .yearly
        )
        context.insert(goal)
        
        // Create a sample reading session
        let session = ReadingSession(
            id: UUID(),
            book: book,
            startPage: 1,
            endPage: 20,
            duration: 1800,
            date: Date()
        )
        context.insert(session)
        
        return HomeView()
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview")
    }
}
