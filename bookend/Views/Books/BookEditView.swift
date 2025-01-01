import SwiftUI
import SwiftData

struct BookEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: BookEditViewModel
    @State private var showEditionsView = false
    @Query private var allGroups: [BookGroup]
    @Query private var relationships: [BookGroupRelationship]
    @Query private var existingBooks: [Book]
    var book: Book
    var onSave: (Book, Bool) -> Void // Closure for save handling
    @State private var usePercentage = false

    init(book: Book, onSave: @escaping (Book, Bool) -> Void) {
        self.book = book
        self._viewModel = StateObject(wrappedValue: BookEditViewModel(book: book))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    CoverImageSection(viewModel: viewModel, showEditionsView: $showEditionsView)
                    GroupsSection(allGroups: allGroups.sorted(by: { $0.name < $1.name }),
                                  isBookInGroup: isBookInGroup,
                                  toggleGroup: toggleGroup)
                    BookDetailsSection(viewModel: viewModel, usePercentage: $usePercentage)
                }
                .padding()
            }
            .navigationTitle(viewModel.book == nil ? "Add Book" : "Edit Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBook()
                    }
                    .disabled(!canSave)
                    .foregroundColor(Color("Accent1")) // Match button color with BookView
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationDestination(isPresented: $showEditionsView) {
                if let selectedBook = viewModel.book {
                    BookEditionsView(
                        selectedBook: selectedBook,
                        onEditionSelected: { edition in
                            // Update the viewModel properties directly from the selected edition
                            viewModel.selectedEdition = edition
                            
                            // Update the viewModel properties
                            viewModel.title = edition.title.isEmpty ? selectedBook.title : edition.title
                            viewModel.author = selectedBook.author // Keep existing author
                            viewModel.totalPages = edition.number_of_pages != nil ? String(edition.number_of_pages!) : String(selectedBook.totalPages)
                            viewModel.currentPage = "0"
                            viewModel.isbn = edition.displayISBN ?? selectedBook.isbn ?? ""
                            viewModel.publisher = edition.displayPublisher ?? selectedBook.publisher ?? ""
                            viewModel.publishYear = edition.publish_date != nil ? 
                                (BookTransformer.parsePublishYear(from: edition.publish_date!).map { String($0) } ?? "") : 
                                (selectedBook.publishYear != nil ? String(selectedBook.publishYear!) : "")
                            viewModel.genre = selectedBook.genre ?? "" // Keep existing genre
                            viewModel.notes = selectedBook.notes ?? "" // Keep existing notes
                            
                            if let coverImageUrl = edition.coverImageUrl {
                                viewModel.loadCoverImage(from: coverImageUrl)
                            }
                            
                            showEditionsView = false // Dismiss the view
                        }
                    )
                }
            }
        }
    }

    private var canSave: Bool {
        !viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !viewModel.author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (!selectedEditionInfoRequired || !viewModel.totalPages.isEmpty)
    }

    private var selectedEditionInfoRequired: Bool {
        return viewModel.selectedEdition == nil
    }

    private func saveBook() {
        // Convert percentage to page number if needed
        viewModel.prepareForSave(usePercentage: usePercentage)

        if isBookDuplicate(title: viewModel.title, isbn: viewModel.isbn) {
            viewModel.alertMessage = "A book with the same title or ISBN already exists"
            viewModel.showAlert = true
            onSave(book, false)
            return
        }

        if let book = viewModel.book {
            // Update existing book
            book.title = viewModel.title
            book.author = viewModel.author
            book.totalPages = Int(viewModel.totalPages) ?? 0
            book.currentPage = Int(viewModel.currentPage) ?? 0  // Now using converted value
            book.isbn = viewModel.isbn
            book.publisher = viewModel.publisher
            book.publishYear = Int(viewModel.publishYear) ?? nil
            book.genre = viewModel.genre
            book.notes = viewModel.notes
            book.coverImageData = viewModel.selectedImage?.pngData() ?? book.coverImageData
            
            print("Updating book: \(book.title)")
            onSave(book, true) // Indicate success
        } else {
            // Create new book with modified current page calculation
            let newBook = Book(
                title: viewModel.title,
                author: viewModel.author,
                genre: viewModel.genre,
                notes: viewModel.notes,
                totalPages: Int(viewModel.totalPages) ?? 0,
                isbn: viewModel.isbn, 
                publisher: viewModel.publisher,
                publishYear: Int(viewModel.publishYear) ?? nil,
                currentPage: Int(viewModel.currentPage) ?? 0,  // Use calculated page
                externalReference: [:]
            )
            print("Creating new book: \(newBook.title)")
            onSave(newBook, true) // Indicate success
        }
    }

    private func isBookDuplicate(title: String, isbn: String?) -> Bool {
        return existingBooks.contains { existingBook in
            (existingBook.title == title || existingBook.isbn == isbn) && existingBook.id != book.id
        }
    }

    private func isBookInGroup(_ group: BookGroup) -> Bool {
        relationships.contains { relationship in
            relationship.book.id == viewModel.book?.id && 
            relationship.group.id == group.id
        }
    }
    
    private func toggleGroup(_ group: BookGroup) {
        guard let book = viewModel.book else { return }
        
        if isBookInGroup(group) {
            // Remove relationship
            if let relationshipToDelete = relationships.first(where: { 
                $0.book.id == book.id && $0.group.id == group.id 
            }) {
                modelContext.delete(relationshipToDelete)
            }
        } else {
            // Add relationship
            let newRelationship = BookGroupRelationship(book: book, group: group)
            modelContext.insert(newRelationship)
        }
        
        try? modelContext.save()
    }
}
