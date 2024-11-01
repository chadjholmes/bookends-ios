import SwiftUI
import SwiftData

struct BookAddView: View {
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
    
    @State private var selectedImage: UIImage?
    @State private var selectedEdition: OpenLibraryBook?
    @State private var showingEditionPicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Search")) {
                    Button("Search OpenLibrary") {
                        showingSearch = true
                    }
                }
                
                if let selectedEdition = selectedEdition {
                    Section(header: Text("Selected Edition")) {
                        VStack(alignment: .leading) {
                            Text("Publisher: \(selectedEdition.publisher?.first ?? "Unknown")")
                            if let year = selectedEdition.first_publish_year {
                                Text("Published: \(year)")
                            }
                            if let pages = selectedEdition.number_of_pages_median {
                                Text("Pages: \(pages)")
                            }
                            if let isbn = selectedEdition.isbn?.first {
                                Text("ISBN: \(isbn)")
                            }
                        }
                        Button("Change Edition") {
                            showingEditionPicker = true
                        }
                    }
                }
                
                Section(header: Text("Book Details")) {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                    if selectedEdition == nil {
                        TextField("Total Pages", text: $totalPages)
                            .keyboardType(.numberPad)
                    }
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
                .disabled(title.isEmpty || author.isEmpty || (selectedEdition == nil && totalPages.isEmpty))
            )
            .sheet(isPresented: $showingSearch) {
                BookSearchView(
                    searchQuery: $searchQuery,
                    searchResults: $searchResults,
                    isSearching: $isSearching,
                    onBookSelected: { book in
                        selectedEdition = book
                        title = book.title
                        author = book.authorDisplay
                        if let pages = book.number_of_pages_median {
                            totalPages = String(pages)
                        }
                        if let coverUrl = book.coverImageUrl {
                            Task {
                                if let url = URL(string: coverUrl),
                                   let (data, _) = try? await URLSession.shared.data(from: url),
                                   let image = UIImage(data: data) {
                                    await MainActor.run {
                                        selectedImage = image
                                    }
                                }
                            }
                        }
                        showingSearch = false
                    }
                )
            }
        }
    }
    
    private func saveBook() {
        let pages = selectedEdition?.number_of_pages_median ?? Int(totalPages) ?? 0
        
        let book = Book(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            author: author.trimmingCharacters(in: .whitespacesAndNewlines),
            genre: "",
            notes: "",
            totalPages: pages,
            isbn: selectedEdition?.isbn?.first,
            publisher: selectedEdition?.publisher?.first,
            publishYear: selectedEdition?.first_publish_year,
            currentPage: 0,
            createdAt: Date()
        )
        
        // Handle the image separately after creation
        if let image = selectedImage {
            try? book.saveCoverImage(image)
        }
        
        modelContext.insert(book)
        dismiss()
    }
}

#Preview {
    BookAddView()
} 
