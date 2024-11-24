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
    @State private var showingReadingSessionEdit = false
    @State private var selectedSession: ReadingSession?
    @State private var isSessionsExpanded = false
    @State private var showingCurrentPagePicker = false
    @State private var showToast = false
    
    // State variable to hold reading sessions
    @State private var readingSessions: [ReadingSession] = []
    
    @State private var coverUIImage: UIImage? = nil
    
    public init(book: Book, currentPage: Int) {
        self.book = book
        self._currentPage = State(initialValue: currentPage)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                HStack {
                    if let coverImage = coverUIImage {
                        Image(uiImage: coverImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 270)
                    } else {
                        ProgressView()
                            .frame(width: 180, height: 270)
                    }
                    BookDetails(book: book)
                }
                BookPageSelector(
                    currentPage: Binding(
                        get: { currentPage },
                        set: { newValue in
                            currentPage = newValue
                            book.currentPage = newValue
                            try? modelContext.save()
                        }
                    ),
                    totalPages: book.totalPages
                )
                HStack {
                    NavigationLink(destination: LiveSessionView(book: book)) {
                        HStack {
                            Image(systemName: "record.circle")
                                .resizable()
                                .scaledToFit()
                                .tint(.white)
                                .frame(width: 20, height: 20)
                            Text("Record Session")
                                .font(.title2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("Accent1"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .id(UUID())
                }
                
                // Accordion section for reading sessions
                List {
                    Section(isExpanded: $isSessionsExpanded, content: {
                        Button(action: {
                            showingReadingSession = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .tint(Color("Accent1"))
                                    .frame(width: 20, height: 20)
                                Text("Add")
                                    .font(.title3)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray4))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .listRowBackground(Color.clear)
                        if !readingSessions.isEmpty {
                            ForEach(readingSessions) { session in
                                ReadingSessionCard(session: session)
                                    .background(Color.clear)
                                    .listRowBackground(Color.clear)
                                    .swipeActions {
                                        // Delete Action
                                        Button(role: .destructive, action: {
                                            deleteSession(session)
                                        }) {
                                            Label("Delete", systemImage: "trash")
                                                .tint(.red)
                                        }
                                        Button(action: {
                                            selectedSession = session
                                            showingReadingSessionEdit = true
                                        }) {
                                            Label("Edit", systemImage: "pencil")
                                                .tint(Color("Accent1"))
                                        }
                                    }
                            }
                        } else {
                            Text("No reading sessions available.")
                                .foregroundColor(.gray)
                                .listRowBackground(Color.clear)
                        }
                    }, header: {
                        Text("Reading Sessions (\(readingSessions.count))")
                            .font(.headline)
                            .padding(.trailing)
                        Spacer()
                    })
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }
                .listStyle(SidebarListStyle())
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)
                .frame(maxWidth: .infinity, minHeight: CGFloat(100 * (readingSessions.count + 1)))
            }
            .padding(.horizontal)
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
        }
        .sheet(isPresented: $showingReadingSession, onDismiss: {
            fetchReadingSessions()
        }) {
            NavigationView {
                ReadingSessionView(book: book, currentPage: $currentPage, onSessionAdded: { newSession in
                    showingReadingSession = false  // Dismiss the sheet
                    showToast = true  // Show success toast if you have one
                })
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationView {
                BookEditView(book: book) { savedBook, success in
                    if success {
                        // Handle saving the book in BookView
                        do {
                            modelContext.insert(savedBook)
                            try modelContext.save()
                            print("Successfully saved book: \(savedBook.title)")
                            isEditing = false
                        } catch {
                            print("Failed to save book: \(error.localizedDescription)")
                        }
                    } else {
                        print("Duplicate book found, not saving.")
                    }
                }
            }
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showingReadingSessionEdit) {
            NavigationView {
                ReadingSessionView(book: book, currentPage: $currentPage, duration: selectedSession?.duration, startPage: selectedSession?.startPage, endPage: selectedSession?.endPage, date: selectedSession?.date, onSessionAdded: nil, existingSession: selectedSession)
            }
            .onDisappear {
                fetchReadingSessions()
            }
        }
        .onAppear {
            loadCoverImage()
            fetchReadingSessions()
        }
    }
    
    // MARK: - Image Loading
    
    private func loadCoverImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = try? book.loadCoverImage() {
                DispatchQueue.main.async {
                    self.coverUIImage = image
                }
            } else {
                DispatchQueue.main.async {
                    self.coverUIImage = nil
                }
            }
        }
    }
    
    // MARK: - Data Fetching
    
    private func fetchReadingSessions() {
        do {
            let allSessions = try modelContext.fetch(FetchDescriptor<ReadingSession>())
            readingSessions = allSessions
                .filter { session in
                    session.book?.id == self.book.id
                }
                .sorted { $0.date > $1.date }  // Sort by date descending
        } catch {
            print("Failed to fetch reading sessions: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Session Management
    
    private func deleteSession(_ session: ReadingSession) {
        if let index = readingSessions.firstIndex(of: session) {
            readingSessions.remove(at: index)
            modelContext.delete(session)
            
            do {
                try modelContext.save()
                print("Successfully deleted session.")
            } catch {
                print("Failed to delete session: \(error.localizedDescription)")
            }
        }
    }
}

struct BookView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Book.self, ReadingSession.self, configurations: config)
        
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
