import SwiftUI

struct BookSearchView: View {
    @Binding var searchQuery: String
    @Binding var searchResults: [OpenLibraryBook]
    @Binding var isSearching: Bool
    let onBookSelected: (OpenLibraryBook) -> Void
    @State private var searchDebounceTimer: Timer? = nil
    
    var body: some View {
        NavigationView {
            List(searchResults) { book in
                Button(action: {
                    onBookSelected(book)
                }) {
                    HStack {
                        AsyncImage(url: URL(string: book.coverImageUrl ?? "")) { phase in
                            switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 50, height: 75)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 75)
                                        .cornerRadius(4)
                                        .shadow(radius: 2)
                                case .failure:
                                    Image(systemName: "book")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 75)
                                        .foregroundColor(.gray)
                                @unknown default:
                                    EmptyView()
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.headline)
                            Text(book.authorDisplay)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Search Books")
            .searchable(text: $searchQuery, prompt: "Search by title or author")
            .onChange(of: searchQuery) { newValue in
                searchDebounceTimer?.invalidate() // Cancel any existing timer
                searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                    performSearch()
                }
            }
            .overlay(
                Group {
                    if isSearching {
                        ProgressView("Searching...")
                    }
                }
            )
            .onAppear {
                print("BookSearchView appeared")
                print("searchQuery: \(searchQuery)")
                print("searchResults: \(searchResults)")
            }
            .onChange(of: searchResults) { newValue in
                print("searchResults changed to: \(newValue)")
            }
        }
    }
    
    /// Performs the search using OpenLibraryService.
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        isSearching = true
        Task {
            do {
                let results = try await OpenLibraryService.shared.searchBooks(query: searchQuery)
                DispatchQueue.main.async {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                print("Search failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isSearching = false
                }
            }
        }
    }
} 
