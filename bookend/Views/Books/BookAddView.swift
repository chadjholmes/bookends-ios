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
    @State private var showingEditBook = false
    @State private var selectedGroups: Set<BookGroup> = []
    @State private var bookForEditing: Book?

    @State private var showToast = false
    @State private var newBook: Book? // Temporary book object
    @State private var addAnotherBook = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Search")) {
                    Button("Search OpenLibrary") {
                        showingSearch = true
                    }
                }
            }
            .navigationTitle("Add Book")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveBook() // Save the book only when confirmed
                }
                .disabled(newBook == nil || (title.isEmpty || author.isEmpty || totalPages.isEmpty))
            )
            .overlay(
                Group {
                    if showToast {
                        BookAddedToast(
                            message: "Book Successfully Added",
                            onDismiss: {
                                showToast = false // Hide the toast
                            },
                            onReturnToBookshelf: {
                                dismiss() // Navigate back to the bookshelf
                            }
                        )
                    }
                }
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
                BookEditView(book: book) { savedBook, success in
                    if success {
                        // Handle saving the book in BookAddView
                        do {
                            modelContext.insert(savedBook) // Insert the book into the context
                            try modelContext.save() // Save the context
                            print("Successfully saved book: \(savedBook.title)")
                            // Reset the bookForEditing state to close the sheet
                            bookForEditing = nil
                            showToast = true
                        } catch {
                            print("Failed to save book: \(error.localizedDescription)")
                        }
                    } else {
                        // Handle the case where a duplicate was found
                        print("Duplicate book found, not saving.")
                    }
                }
            }
        }
    }
    
    private func handleBookSelection(_ book: OpenLibraryBook) {
        // Create a temporary book object
        newBook = Book(
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
                    try? newBook?.saveCoverImage(image)
                }
            }
        }
        
        // Set the selected book for editing
        bookForEditing = newBook
        showingSearch = false
        showingEditBook = true
        searchQuery = ""
    }
    
    private func saveBook() {
        guard let bookToSave = newBook else { return }
        
        // Insert the book into the context
        modelContext.insert(bookToSave)
        
        // Optionally, show a toast or confirmation
        showToast = true
        
        // Dismiss the view
        dismiss()
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
