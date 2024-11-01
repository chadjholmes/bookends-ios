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
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Cover Image Section
                if let coverUrl = book.coverImage,
                   let url = URL(string: coverUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 250)
                                .cornerRadius(8)
                                .shadow(radius: 5)
                        case .failure(_):
                            Image(systemName: "book.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 250)
                                .foregroundColor(.gray)
                        case .empty:
                            ProgressView()
                                .frame(height: 250)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal)
                } else {
                    Image(systemName: "book.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 250)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
                
                // Book details
                VStack(alignment: .leading, spacing: 12) {
                    Text(book.title)
                        .font(.title)
                        .bold()
                    
                    if !book.author.isEmpty {
                        Text("by \(book.author)")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Reading progress
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
                        
                        // Page update stepper
                        Stepper("Current Page: \(currentPage)", value: $currentPage, in: 0...book.totalPages)
                            .onChange(of: currentPage) { oldValue, newValue in
                                book.currentPage = newValue
                                try? modelContext.save()
                            }
                    }
                    .padding(.top)
                    
                    // Added date
                    Text("Added on \(book.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .padding()
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
                EditBookView(book: book)
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
        coverImage: "https://covers.openlibrary.org/b/id/12547191-L.jpg", // Sample cover URL
        genre: "Fiction",
        notes: "This is a sample note about the book.",
        totalPages: 100
    )
    
    return NavigationView {
        BookView(book: book, currentPage: book.currentPage)
    }
    .modelContainer(container)
}
