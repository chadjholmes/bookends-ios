import SwiftUI
import SwiftData

struct BookAddView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allGroups: [BookGroup]
    
    @State private var title = ""
    @State private var author = ""
    @State private var totalPages = ""
    @State private var showingSearch = false
    @State private var searchQuery = ""
    @State private var searchResults: [OpenLibraryBook] = []
    @State private var isSearching = false
    @State private var selectedImage: UIImage?
    @State private var selectedBook: OpenLibraryBook?
    @State private var showingEditionPicker = false
    @State private var selectedGroups: Set<BookGroup> = []
    @State private var bookForEditing: Book?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Search")) {
                    Button("Search OpenLibrary") {
                        showingSearch = true
                    }
                }
                
                if bookForEditing == nil {
                    Section(header: Text("Book Details")) {
                        TextField("Title", text: $title)
                        TextField("Author", text: $author)
                        TextField("Total Pages", text: $totalPages)
                            .keyboardType(.numberPad)
                    }
                    
                    Section(header: Text("Groups")) {
                        ForEach(allGroups) { group in
                            Toggle(isOn: Binding(
                                get: { selectedGroups.contains(group) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedGroups.insert(group)
                                    } else {
                                        selectedGroups.remove(group)
                                    }
                                }
                            )) {
                                VStack(alignment: .leading) {
                                    Text(group.name)
                                    if let description = group.groupDescription {
                                        Text(description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
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
                .disabled(bookForEditing == nil && (title.isEmpty || author.isEmpty || totalPages.isEmpty))
            )
            .sheet(isPresented: $showingSearch) {
                BookSearchView(
                    searchQuery: $searchQuery,
                    searchResults: $searchResults,
                    isSearching: $isSearching,
                    onBookSelected: { book in
                        handleBookSelection(book)
                    }
                )
            }
            .sheet(item: $bookForEditing) { book in
                BookEditView(book: book)
            }
        }
    }
    
    private func handleBookSelection(_ book: OpenLibraryBook) {
        let newBook = Book(
            title: book.title,
            author: book.authorDisplay,
            totalPages: book.number_of_pages_median ?? 0,
            isbn: book.isbn?.first,
            publisher: book.publisher?.first,
            publishYear: book.first_publish_year,
            externalReference: ["openlibraryKey": book.key]
        )
        
        if let coverUrl = book.coverImageUrl {
            Task {
                if let url = URL(string: coverUrl),
                   let (data, _) = try? await URLSession.shared.data(from: url),
                   let image = UIImage(data: data) {
                    try? newBook.saveCoverImage(image)
                }
            }
        }
        
        modelContext.insert(newBook)
        
        bookForEditing = newBook
        showingSearch = false
    }
    
    private func saveBook() {
        // Remove or modify saveBook() since we're now handling it in the EditView
    }
    
    private func handleEditionSelection(_ edition: OpenLibraryEdition) {
        title = edition.title
        author = selectedBook?.authorDisplay ?? author
        if let pages = edition.number_of_pages {
            totalPages = String(pages)
        }
        
        if let coverUrl = edition.coverImageUrl {
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
        
        if let currentBook = selectedBook {
            let updatedBook = OpenLibraryBook(
                key: currentBook.key,
                title: edition.title,
                author_name: currentBook.author_name,
                number_of_pages_median: edition.number_of_pages,
                cover_i: edition.covers?.first,
                first_publish_year: Int(edition.publish_date ?? "0"),
                publisher: edition.publishers,
                isbn: [edition.displayISBN].compactMap { $0 }
            )
            selectedBook = updatedBook
        }
    }
}

#Preview {
    BookAddView()
} 
