import SwiftUI
import SwiftData

struct BookView: View {
    let book: Book
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var currentPage: Int

    public init(book: Book, currentPage: Int) {
        self.book = book
        self._currentPage = State(initialValue: currentPage)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                BookCoverView(book: book)
                BookDetailsView(book: book, currentPage: $currentPage, modelContext: modelContext)
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
        .sheet(isPresented: $isEditing) {
            NavigationView {
                BookEditView(book: book)
            }
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
                Text("\(Int((Double(currentPage) / Double(book.totalPages)) * 100))%")
            }
            .font(.subheadline)
            
            ProgressView(value: Double(currentPage), total: Double(book.totalPages))
                .tint(.blue)
            
            Stepper("Current Page: \(currentPage)", value: $currentPage, in: 0...book.totalPages)
                .onChange(of: currentPage) { oldValue, newValue in
                    book.currentPage = newValue
                    try? modelContext.save()
                }
        }
        .padding(.top)
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
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Book.self, configurations: config)
    
    let book = Book(
        title: "Sample Book",
        author: "John Doe",
        genre: "Fiction",
        notes: "This is a sample note about the book.",
        totalPages: 100
    )
    
    NavigationView {
        BookView(book: book, currentPage: book.currentPage)
    }
    .modelContainer(container)
}
