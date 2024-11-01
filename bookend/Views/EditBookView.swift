import SwiftUI
import SwiftData

struct EditBookView: View {
    @Environment(\.dismiss) private var dismiss
    let book: Book
    
    @State private var title: String
    @State private var author: String = ""
    @State private var totalPages: String
    
    init(book: Book) {
        self.book = book
        _title = State(initialValue: book.title)
        _author = State(initialValue: book.author ?? "")
        _totalPages = State(initialValue: String(book.totalPages))
    }
    
    var body: some View {
        Form {
            Section("Book Details") {
                TextField("Title", text: $title)
                TextField("Author", text: $author)
                TextField("Total Pages", text: $totalPages)
                    .keyboardType(.numberPad)
            }
        }
        .navigationTitle("Edit Book")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    updateBook()
                    dismiss()
                }
            }
        }
    }
    
    private func updateBook() {
        book.title = title.isEmpty ? "Untitled" : title
        book.author = author.isEmpty ? "" : author
        book.totalPages = Int(totalPages) ?? book.totalPages
    }
} 