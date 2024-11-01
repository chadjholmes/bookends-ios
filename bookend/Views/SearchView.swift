import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var searchQuery: String
    @Binding var searchResults: [OpenLibraryBook]
    @Binding var isSearching: Bool
    var onBookSelected: (OpenLibraryBook) -> Void
    
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            VStack {
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
                        onBookSelected(book)
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
} 