import SwiftUI
import SwiftData

struct BookAddView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allGroups: [BookGroup]
    
    @State private var title = ""
    @State private var author = ""
    @State private var totalPages = ""
    @State private var showingSearch = true
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
            BookSearchView(
                searchQuery: $searchQuery,
                searchResults: $searchResults,
                isSearching: $isSearching,
                onBookSelected: { book in
                    handleBookSelection(book)
                }
            )
            .toast(isPresenting: $showToast) {
                ToastView(
                    message: "Thy royal collection grows ever grander.",
                    primaryButton: ToastButton(
                        title: "Add More",
                        action: {
                            showToast = false
                            showingSearch = true
                        }
                    ),
                    secondaryButton: ToastButton(
                        title: "Done",
                        action: {
                            showToast = false
                            dismiss()
                        }
                    )
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveBook() // Save the book only when confirmed
                }
                .disabled(newBook == nil || (title.isEmpty || author.isEmpty || totalPages.isEmpty))
            )
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
        
        Task {
            if let coverUrl = book.coverImageUrl {
                do {
                    guard let url = URL(string: coverUrl) else {
                        print("Invalid cover URL: \(coverUrl)")
                        return
                    }
                    
                    let (data, response) = try await URLSession.shared.data(from: url)
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        print("Invalid response for cover image")
                        return
                    }
                    
                    guard let image = UIImage(data: data) else {
                        print("Failed to create image from data")
                        return
                    }
                    
                    // Ensure we're on the main thread when modifying the book
                    await MainActor.run {
                        do {
                            try newBook?.saveCoverImage(image)
                            print("Successfully saved cover image")
                            // Only now show the edit view
                            bookForEditing = newBook
                            showingSearch = false
                            showingEditBook = true
                            searchQuery = ""
                        } catch {
                            print("Failed to save cover image: \(error)")
                        }
                    }
                } catch {
                    print("Error loading cover image: \(error)")
                }
            } else {
                // If there's no cover image, proceed directly to edit
                await MainActor.run {
                    bookForEditing = newBook
                    showingSearch = false
                    showingEditBook = true
                    searchQuery = ""
                }
            }
        }
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
