import SwiftUI
import SwiftData

struct BookEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: BookEditViewModel
    @State private var showEditionsView = false
    @Query private var allGroups: [BookGroup]
    @Query private var relationships: [BookGroupRelationship]

    init(book: Book? = nil) {
        _viewModel = StateObject(wrappedValue: BookEditViewModel(book: book))
    }

    var body: some View {
        NavigationStack {
            Form {
                CoverImageSection(viewModel: viewModel, showEditionsView: $showEditionsView)
                GroupsSection(allGroups: allGroups, isBookInGroup: isBookInGroup, toggleGroup: toggleGroup)
                BookDetailsSection(viewModel: viewModel)
            }
            .padding()
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
        // Check if we are editing an existing book or creating a new one
        if let book = viewModel.book {
            // Update the existing book
            book.title = viewModel.title
            book.author = viewModel.author
            book.totalPages = Int(viewModel.totalPages) ?? 0
            book.isbn = viewModel.isbn
            book.publisher = viewModel.publisher
            book.publishYear = Int(viewModel.publishYear) ?? nil
            book.genre = viewModel.genre
            book.notes = viewModel.notes
            book.coverImageData = viewModel.selectedImage?.pngData() ?? book.coverImageData
            
            // Group relationships are managed separately through BookGroupRelationship
            print("Saving book: \(book.title)")
        } else {
            // Create a new book
            let newBook = Book(
                title: viewModel.title,
                author: viewModel.author,
                genre: viewModel.genre,
                notes: viewModel.notes,
                totalPages: Int(viewModel.totalPages) ?? 0,
                isbn: viewModel.isbn,
                publisher: viewModel.publisher,
                publishYear: Int(viewModel.publishYear) ?? nil,
                externalReference: [:]
            )
            modelContext.insert(newBook)
            viewModel.book = newBook  // Set the book reference
        }
        
        // Save the context
        do {
            try modelContext.save()
            print("Successfully saved book")
            dismiss()
        } catch {
            print("Failed to save: \(error)")
            viewModel.alertMessage = "Failed to save the book. Please try again."
            viewModel.showAlert = true
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
