import SwiftUI
import SwiftData

struct BookView: View {
    let book: Book
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var currentPage: Int
    @State private var showingReadingSession = false
    @State private var selectedBook: Book?
    @State private var showingClearSessionsAlert = false
    @State private var isSessionsExpanded = false
    @State private var showingCurrentPagePicker = false
    @State private var showToast = false
    
    // State variable to hold reading sessions
    @State private var readingSessions: [ReadingSession] = []
    
    public init(book: Book, currentPage: Int) {
        self.book = book
        self._currentPage = State(initialValue: currentPage)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                HStack {
                    BookCover(book: book, currentPage: currentPage, width: 180, height: 270, showSubtitles: false)
                    BookDetails(book: book)
                }
                HStack {
                    NavigationLink(destination: LiveSessionView(book: book, onSessionSaved: {
                        showToast = true
                    })) {
                        Text("Record Session")
                            .frame(maxWidth: .infinity) // Ensure full width
                            .padding()
                            .background(Color("Accent1"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity)
                    Button(action: {
                        showingReadingSession = true
                    }) {
                        Text("Enter Session")
                            .frame(maxWidth: .infinity) // Ensure full width
                            .padding()
                            .background(Color("Accent1"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                // Current Page Display with Slider
                // Accordion section for reading sessions (moved below Current Page)
                DisclosureGroup("Reading Sessions (\(readingSessions.count))", isExpanded: $isSessionsExpanded) {
                    if !readingSessions.isEmpty {
                        ForEach(readingSessions, id: \.self) { session in
                            ReadingSessionCard(session: session)
                        }
                    } else {
                        Text("No reading sessions available.")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .accentColor(Color("Accent1"))
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .frame(maxWidth: .infinity) // Ensure full width to match button
            }
            .padding(.horizontal) // Add horizontal padding to the entire VStack
            .toast(isPresented: $showToast, message: "Session saved successfully!")
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    isEditing = true
                    selectedBook = book
                }
                .foregroundColor(Color("Accent1"))
            }
            ToolbarItem(placement: .bottomBar) {
                Button("Clear Reading Sessions") {
                    showingClearSessionsAlert = true
                }
                .foregroundColor(.red)
                .padding(.top, 20)
            }
        }
        .sheet(isPresented: $showingReadingSession) {
            NavigationView {
                ReadingSessionView(book: book, currentPage: $currentPage) { newSession in
                    // Update the reading sessions list when a new session is added
                    readingSessions.append(newSession)
                    // Save the new session to the model context
                    do {
                        try modelContext.insert(newSession)
                        try modelContext.save()
                    } catch {
                        print("Failed to save new reading session: \(error.localizedDescription)")
                    }
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationView {
                BookEditView(book: book) { savedBook, success in
                    if success {
                        // Handle saving the book in BookView
                        do {
                            modelContext.insert(savedBook) // Insert the book into the context
                            try modelContext.save() // Save the context
                            print("Successfully saved book: \(savedBook.title)")
                            isEditing = false
                        } catch {
                            print("Failed to save book: \(error.localizedDescription)")
                        }
                    } else {
                        // Handle the case where a duplicate was found
                        print("Duplicate book found, not saving.")
                    }
                }
            }
            .interactiveDismissDisabled()
        }
        .alert("Clear All Reading Sessions for This Book?", isPresented: $showingClearSessionsAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clearAllReadingSessionsForBook()
            }
        } message: {
            Text("This will delete all reading sessions for this book. This action cannot be undone.")
        }
        .onAppear {
            fetchReadingSessions() // Fetch reading sessions when the view appears
        }
    }
    
    private func fetchReadingSessions() {
        do {
            // Fetch all reading sessions first
            let allSessions = try modelContext.fetch(FetchDescriptor<ReadingSession>())
            
            // Filter sessions based on the current book's ID
            readingSessions = allSessions.filter { session in
                session.book?.id == self.book.id
            }
        } catch {
            print("Failed to fetch reading sessions: \(error.localizedDescription)")
        }
    }
    
    private func clearAllReadingSessionsForBook() {
        print("Clearing all reading sessions for book: \(book.title)")
        
        // Fetch sessions to delete
        do {
            let sessionsToDelete = try modelContext.fetch(FetchDescriptor<ReadingSession>()).filter { $0.book == book }
            
            for session in sessionsToDelete {
                modelContext.delete(session)
            }
            
            // Save changes and handle potential errors
            try modelContext.save()
            
            // Clear the readingSessions array to reflect the changes
            readingSessions.removeAll() // Clear the local array
            print("All reading sessions for this book cleared.")
        } catch {
            print("Failed to clear reading sessions: \(error.localizedDescription)")
        }
    }
}

// Preview provider
struct BookView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Book.self, configurations: config)
        
        let book = Book(
            title: "Sample Book",
            author: "John Doe",
            genre: "Fiction",
            notes: "This is a sample note about the book.",
            totalPages: 300,
            isbn: "1234567890",
            publisher: "Sample Publisher",
            publishYear: 2023,
            externalReference: ["openlibraryKey": "OL1234567890"]
        )
        
        NavigationView {
            BookView(book: book, currentPage: 50)
        }
        .modelContainer(container)
    }
}
