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
    @State private var showingCurrentPagePicker = false // State for showing the current page picker
    
    // State variable to hold reading sessions
    @State private var readingSessions: [ReadingSession] = []
    
    public init(book: Book, currentPage: Int) {
        self.book = book
        self._currentPage = State(initialValue: currentPage)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    BookCover(book: book, currentPage: currentPage, width: 180, height: 270, showSubtitles: false)
                    BookDetails(book: book)
                }
                 // Add Reading Session Button
                Button(action: {
                    showingReadingSession = true
                }) {
                    Label("Add Reading Session", systemImage: "book.closed")
                        .frame(maxWidth: .infinity) // Ensure full width
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal)
                // Current Page Display with Button
                Button(action: {
                    showingCurrentPagePicker = true
                }) {
                    HStack {
                        Text("Current Page: \(currentPage) of \(book.totalPages)")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right") // Arrow indicating more options
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
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
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .frame(maxWidth: .infinity) // Ensure full width to match button
            }
            .padding(.horizontal) // Add horizontal padding to the entire VStack
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    isEditing = true
                    selectedBook = book
                }
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
                BookEditView(book: book)
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
        .sheet(isPresented: $showingCurrentPagePicker) {
            NavigationView {
                Picker("Select Current Page", selection: $currentPage) {
                    ForEach(1...book.totalPages, id: \.self) { page in
                        Text("\(page)").tag(page)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .navigationTitle("Select Current Page")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            // Update the book's currentPage when done
                            book.currentPage = currentPage // Ensure this line updates the Book model
                            print("Current page updated to: \(book.currentPage)") // Log the updated current page
                            showingCurrentPagePicker = false
                        }
                    }
                }
            }
            .presentationDetents([.height(250)]) // Optional: Adjust height as needed
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
