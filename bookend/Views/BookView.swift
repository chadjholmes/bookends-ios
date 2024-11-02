import SwiftUI
import SwiftData

struct BookView: View {
    let book: Book
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var currentPage: Int
    @State private var showingReadingSession = false
    
    public init(book: Book, currentPage: Int) {
        self.book = book
        self._currentPage = State(initialValue: currentPage)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                BookCoverView(book: book)
                BookDetailsView(book: book, currentPage: $currentPage, modelContext: modelContext)
                
                Button(action: {
                    showingReadingSession = true
                }) {
                    Label("Add Reading Session", systemImage: "book.closed")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $showingReadingSession) {
            NavigationView {
                ReadingSessionView(book: book, currentPage: $currentPage)
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationView {
                BookEditView(book: book)
            }
            .interactiveDismissDisabled()
        }
    }
}

// Cover Image Component
struct BookCoverView: View {
    let book: Book
    
    var body: some View {
        Group {
            if let image = try? book.loadCoverImage() {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 250)
                    .cornerRadius(8)
                    .shadow(radius: 5)
            } else if let coverUrl = book.coverImageURL,
                      let url = URL(string: coverUrl.absoluteString),
                      let data = try? Data(contentsOf: url),
                      let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 250)
                    .cornerRadius(8)
                    .shadow(radius: 5)
            } else {
                Image(systemName: "book.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 250)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
    }
}

// Book Details Component
struct BookDetailsView: View {
    let book: Book
    @Binding var currentPage: Int
    let modelContext: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(book.title)
                .font(.title)
                .bold()
            
            if !book.author.isEmpty {
                Text("by \(book.author)")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            ReadingProgressView(book: book, currentPage: $currentPage, modelContext: modelContext)
            
            BookMetadataView(book: book)
        }
        .padding()
    }
}

// Reading Progress Component
struct ReadingProgressView: View {
    let book: Book
    @Binding var currentPage: Int
    let modelContext: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reading Progress")
                .font(.headline)
            
            HStack {
                Text("\(currentPage) of \(book.totalPages) pages")
                Spacer()
                Text("\(calculateProgress())%")
            }
            .font(.subheadline)
            
            ProgressView(value: Double(currentPage), total: Double(book.totalPages))
                .tint(.blue)
            
            Stepper("Current Page: \(currentPage)", value: $currentPage, in: 0...book.totalPages)
                .onChange(of: currentPage) { oldValue, newValue in
                    book.currentPage = newValue
                    do {
                        try modelContext.save()
                    } catch {
                        print("Failed to save current page: \(error.localizedDescription)")
                    }
                }
        }
        .padding(.top)
    }

    private func calculateProgress() -> String {
        guard book.totalPages > 0 else { return "0" }
        let progress = (Double(currentPage) / Double(book.totalPages)) * 100
        return String(format: "%.0f", progress)
    }
}

// Book Metadata Component
struct BookMetadataView: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Added on \(book.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top)
        
            if let publisher = book.publisher {
                Text("Publisher: \(publisher)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        
            if let publishYear = book.publishYear {
                Text("Published: \(publishYear)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        
            if let isbn = book.isbn {
                Text("ISBN: \(isbn)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
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
