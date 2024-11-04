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
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Search")) {
                    Button("Search OpenLibrary") {
                        showingSearch = true
                    }
                }
                
                if let book = selectedBook {
                    Section(header: Text("Selected Edition")) {
                        HStack {
                            AsyncImageView(
                                url: book.coverImageUrl,
                                width: 60,
                                height: 90
                            )
                            
                            BookMetadata(book: Book(
                                title: book.title,
                                author: book.authorDisplay,
                                totalPages: book.number_of_pages_median ?? 0,
                                isbn: book.isbn?.first,
                                publisher: book.publisher?.first,
                                publishYear: book.first_publish_year,
                                externalReference: ["openlibraryKey": book.key]
                            ))
                        }
                        
                        Button("Change Edition") {
                            showingEditionPicker = true
                        }
                    }
                }
                
                Section(header: Text("Book Details")) {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                    if selectedBook == nil {
                        TextField("Total Pages", text: $totalPages)
                            .keyboardType(.numberPad)
                    }
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
            .navigationTitle("Add Book")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveBook()
                }
                .disabled(title.isEmpty || author.isEmpty || (selectedBook == nil && totalPages.isEmpty))
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
            .sheet(isPresented: $showingEditionPicker) {
                if let book = selectedBook {
                    let transformedBook = BookTransformer.transformToBook(book: book)
                    BookEditionsView(
                        selectedBook: transformedBook,
                        onEditionSelected: { newEdition in
                            handleEditionSelection(newEdition)
                            showingEditionPicker = false
                        }
                    )
                }
            }
        }
    }
    
    private func handleBookSelection(_ book: OpenLibraryBook) {
        selectedBook = book
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
    
    private func saveBook() {
        let pages = selectedBook?.number_of_pages_median ?? Int(totalPages) ?? 0
        
        let book = Book(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            author: author.trimmingCharacters(in: .whitespacesAndNewlines),
            totalPages: pages,
            isbn: selectedBook?.isbn?.first,
            publisher: selectedBook?.publisher?.first,
            publishYear: selectedBook?.first_publish_year,
            externalReference: ["openlibraryKey": selectedBook?.key ?? ""]
        )
        
        if let image = selectedImage {
            try? book.saveCoverImage(image)
        }
        
        modelContext.insert(book)
        
        for group in selectedGroups {
            let relationship = BookGroupRelationship(book: book, group: group)
            modelContext.insert(relationship)
        }
        
        dismiss()
    }
    
    private func handleEditionSelection(_ edition: OpenLibraryEdition) {
        title = edition.title
        author = selectedBook?.authorDisplay ?? author
        if let pages = edition.number_of_pages {
            totalPages = String(pages)
        }
        
        // Update cover image if available
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
        
        // Create a new OpenLibraryBook with updated edition data
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
