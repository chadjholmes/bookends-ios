import SwiftUI

struct BookEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: BookEditViewModel
    @State private var showEditionsView = false

    init(book: Book? = nil) {
        _viewModel = StateObject(wrappedValue: BookEditViewModel(book: book))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Cover Image Section
                Section(header: Text("Cover Image")) {
                    CoverImageView(
                        coverImageData: viewModel.selectedImage?.pngData(),
                        coverImageURL: viewModel.selectedEdition?.coverImageUrl ?? viewModel.selectedBook?.coverImageUrl,
                        selectedImage: $viewModel.selectedImage
                    )
                    
                    Button("Change Edition") {
                        showEditionsView = true
                    }
                }
                
                // Book Details Section
                Section(header: Text("Book Details")) {
                    TextField("Title", text: $viewModel.title)
                        .disableAutocorrection(true)
                    
                    TextField("Author", text: $viewModel.author)
                        .disableAutocorrection(true)
                    
                    if viewModel.selectedEdition == nil {
                        TextField("Total Pages", text: $viewModel.totalPages)
                            .keyboardType(.numberPad)
                    }
                }
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
                if let selectedBook = viewModel.selectedBook {
                    BookEditionsView(
                        selectedBook: selectedBook,
                        onEditionSelected: { edition in
                            viewModel.selectedEdition = edition
                            viewModel.title = edition.title.isEmpty ? selectedBook.title : edition.title
                            viewModel.totalPages = edition.number_of_pages != nil ? String(edition.number_of_pages!) : ""
                            viewModel.selectedImage = nil // Reset the image before loading a new one
                            viewModel.loadCoverImage(from: edition.coverImageUrl)
                            // Update other properties as needed
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
            book.coverImageData = viewModel.selectedImage?.pngData() ?? book.coverImageData
            // Update other properties as needed
        } else {
            // Create a new book
            let newBook = Book(
                title: viewModel.title,
                author: viewModel.author,
                totalPages: Int(viewModel.totalPages) ?? 0,
                externalReference: [:] // Provide an empty dictionary or appropriate data
                // Initialize other properties as needed
            )
            modelContext.insert(newBook)
        }
        
        // Save the context
        do {
            try modelContext.save()
            // After saving, dismiss the view to return to the book list
            dismiss()
        } catch {
            // Handle the error, e.g., show an alert
            viewModel.alertMessage = "Failed to save the book. Please try again."
            viewModel.showAlert = true
        }
    }
}
