import SwiftUI
import SwiftData

struct BookEditView: View {
    @Environment(\.dismiss) private var dismiss
    let book: Book
    
    @State private var title: String
    @State private var author: String
    @State private var totalPages: String
    @State private var selectedImage: UIImage?
    
    @State private var showingSearch = false
    @State private var searchQuery = ""
    @State private var searchResults: [OpenLibraryBook] = []
    @State private var isSearching = false
    @State private var selectedEdition: OpenLibraryBook?
    
    init(book: Book) {
        self.book = book
        _title = State(initialValue: book.title)
        _author = State(initialValue: book.author)
        _totalPages = State(initialValue: String(book.totalPages))
        
        if let isbn = book.isbn,
           let publisher = book.publisher,
           let publishYear = book.publishYear {
            _selectedEdition = State(initialValue: OpenLibraryBook(
                key: "",
                title: book.title,
                author_name: [book.author],
                number_of_pages_median: book.totalPages,
                cover_i: nil,
                first_publish_year: publishYear,
                publisher: [publisher],
                isbn: [isbn]
            ))
        }
    }
    
    var body: some View {
        Form {
            Section("Cover Image") {
                if let image = try? book.loadCoverImage() {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                }
            }
            
            if let selectedEdition = selectedEdition {
                Section(header: Text("Current Edition")) {
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
                        showingSearch = true
                    }
                }
            } else {
                Section {
                    Button("Select Edition") {
                        showingSearch = true
                    }
                }
            }
            
            Section("Book Details") {
                TextField("Title", text: $title)
                TextField("Author", text: $author)
                if selectedEdition == nil {
                    TextField("Total Pages", text: $totalPages)
                        .keyboardType(.numberPad)
                }
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
        .sheet(isPresented: $showingSearch) {
            BookSearchView(
                searchQuery: $searchQuery,
                searchResults: $searchResults,
                isSearching: $isSearching,
                onBookSelected: { newEdition in
                    selectedEdition = newEdition
                    title = newEdition.title
                    author = newEdition.authorDisplay
                    if let pages = newEdition.number_of_pages_median {
                        totalPages = String(pages)
                    }
                    if let coverUrl = newEdition.coverImageUrl {
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
    
    private func updateBook() {
        book.title = title.isEmpty ? "Untitled" : title
        book.author = author.isEmpty ? "" : author
        
        if let edition = selectedEdition {
            book.totalPages = edition.number_of_pages_median ?? Int(totalPages) ?? book.totalPages
            book.isbn = edition.isbn?.first
            book.publisher = edition.publisher?.first
            book.publishYear = edition.first_publish_year
        } else {
            book.totalPages = Int(totalPages) ?? book.totalPages
        }
        
        if let newImage = selectedImage {
            try? book.saveCoverImage(newImage)
        }
    }
} 
