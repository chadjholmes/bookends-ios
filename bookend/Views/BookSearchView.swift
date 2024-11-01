import SwiftUI

struct BookSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var searchQuery: String
    @Binding var searchResults: [OpenLibraryBook]
    @Binding var isSearching: Bool
    var onBookSelected: (OpenLibraryBook) -> Void
    
    @State private var selectedBook: OpenLibraryBook?
    @State private var editions: [OpenLibraryEdition] = []
    @State private var showingEditions = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            Group {
                if showingEditions {
                    // Editions List
                    List(editions) { edition in
                        Button(action: {
                            // Convert edition to OpenLibraryBook format and select it
                            let book = OpenLibraryBook(
                                key: edition.key,
                                title: edition.title,
                                author_name: selectedBook?.author_name ?? [],
                                number_of_pages_median: edition.number_of_pages,
                                cover_i: edition.covers?.first,
                                first_publish_year: nil, // Could parse from publish_date if needed
                                publisher: edition.publishers,
                                isbn: [edition.displayISBN].compactMap { $0 }
                            )
                            onBookSelected(book)
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(edition.title)
                                    .font(.headline)
                                
                                Text(edition.displayPublisher)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if let publishDate = edition.publish_date {
                                    Text("Published: \(publishDate)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let pages = edition.number_of_pages {
                                    Text("\(pages) pages")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let isbn = edition.displayISBN {
                                    Text("ISBN: \(isbn)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Cover Image
                                if let coverUrl = edition.coverImageUrl {
                                    AsyncImage(url: URL(string: coverUrl)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(height: 100)
                                                .cornerRadius(4)
                                        case .failure(_):
                                            Image(systemName: "book.fill")
                                                .frame(height: 100)
                                        case .empty:
                                            ProgressView()
                                                .frame(height: 100)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } else {
                    // Search bar
                    HStack {
                        TextField("Search by title", text: $searchQuery)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: searchQuery) { oldValue, newValue in
                                searchBooks()
                            }
                        
                        if isSearching {
                            ProgressView()
                                .padding(.horizontal)
                        }
                    }
                    .padding()
                    
                    // Results list
                    List(searchResults) { book in
                        Button(action: {
                            selectedBook = book
                            Task {
                                do {
                                    editions = try await OpenLibraryService.shared.getEditions(workId: book.key)
                                    showingEditions = true
                                } catch {
                                    DispatchQueue.main.async {
                                        errorMessage = error.localizedDescription
                                        showError = true
                                        isSearching = false
                                    }
                                }
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                // Title and Author
                                Text(book.title)
                                    .font(.headline)
                                
                                Text(book.authorDisplay)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                // Cover Image
                                if let coverUrl = book.coverImageUrl {
                                    AsyncImage(url: URL(string: coverUrl)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(height: 100)
                                                .cornerRadius(4)
                                        case .failure(_):
                                            Image(systemName: "book.fill")
                                                .frame(height: 100)
                                        case .empty:
                                            ProgressView()
                                                .frame(height: 100)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                }
                                
                                // Additional Details
                                VStack(alignment: .leading, spacing: 4) {
                                    if let pages = book.number_of_pages_median {
                                        Text("\(pages) pages")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if let year = book.first_publish_year {
                                        Text("First published: \(year)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if let publishers = book.publisher?.prefix(3) {
                                        Text("Publishers: \(publishers.joined(separator: ", "))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Search Books")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
            .alert("Error", isPresented: $showError, presenting: errorMessage) { _ in
                Button("OK", role: .cancel) { }
            } message: { error in
                Text(error)
            }
        }
    }
    
    private func searchBooks() {
        guard searchQuery.count >= 2 else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        Task {
            do {
                let results = try await OpenLibraryService.shared.searchBooks(query: searchQuery)
                DispatchQueue.main.async {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    showError = true
                    isSearching = false
                }
            }
        }
    }
    
    private func loadEditions(for book: OpenLibraryBook) {
        isSearching = true
        
        // Just pass the whole key, let the service clean it
        Task {
            do {
                let editions = try await OpenLibraryService.shared.getEditions(workId: book.key)
                await MainActor.run {
                    self.editions = editions
                    self.showingEditions = true
                    isSearching = false
                }
            } catch {
                print("Edition fetch error: \(error)")  // Debug log
                await MainActor.run {
                    errorMessage = "Failed to load editions: \(error.localizedDescription)"
                    showError = true
                    isSearching = false
                }
            }
        }
    }
} 
