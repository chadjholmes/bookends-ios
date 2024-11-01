import SwiftUI
import SwiftData

struct AddBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var author = ""
    @State private var totalPages = ""
    @State private var coverImage: String?
    
    @State private var showingSearch = false
    @State private var searchQuery = ""
    @State private var searchResults: [OpenLibraryBook] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Search")) {
                    Button("Search OpenLibrary") {
                        showingSearch = true
                    }
                }
                
                Section(header: Text("Book Details")) {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                    TextField("Total Pages", text: $totalPages)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Book")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveBook()
                }
                .disabled(title.isEmpty || author.isEmpty || totalPages.isEmpty)
            )
            .sheet(isPresented: $showingSearch) {
                SearchView(
                    searchQuery: $searchQuery,
                    searchResults: $searchResults,
                    isSearching: $isSearching,
                    onBookSelected: { book in
                        title = book.title
                        author = book.authorDisplay
                        if let pages = book.number_of_pages_median {
                            totalPages = String(pages)
                        }
                        if let coverUrl = book.coverImageUrl {
                            coverImage = coverUrl
                        }
                        showingSearch = false
                    }
                )
            }
        }
    }
    
    private func saveBook() {
        guard let pages = Int(totalPages) else { return }
        
        let book = Book(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            author: author.trimmingCharacters(in: .whitespacesAndNewlines),
            coverImage: coverImage ?? "",
            genre: "",
            notes: "",
            totalPages: pages
        )
        
        modelContext.insert(book)
        dismiss()
    }
}

#Preview {
    AddBookView()
} 
