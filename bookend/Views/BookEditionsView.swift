import SwiftUI

struct BookEditionsView: View {
    let selectedBook: OpenLibraryBook
    let onEditionSelected: (OpenLibraryEdition) -> Void
    
    @State private var editions: [OpenLibraryEdition] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var hasLoadedEditions = false
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading Editions...")
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List(editions) { edition in
                        Button(action: {
                            onEditionSelected(edition)
                        }) {
                            HStack {
                                editionCoverImage(url: edition.coverImageUrl)
                                
                                editionDetails(edition: edition)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Edition")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // Dismiss without selecting an edition
                    }
                }
            }
            .onAppear {
                if !hasLoadedEditions {
                    fetchEditions()
                    hasLoadedEditions = true
                }
            }
        }
    }
    
    private func editionCoverImage(url: String?) -> some View {
        Group {
            if let urlString = url, let imageUrl = URL(string: urlString) {
                AsyncImage(url: imageUrl) { phase in
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
            } else {
                Image(systemName: "book")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 75)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func editionDetails(edition: OpenLibraryEdition) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(edition.title)
                .font(.headline)
            
            if let pages = edition.number_of_pages {
                Text("Pages: \(pages)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            let year = BookTransformer.parsePublishYear(from: edition.publish_date ?? "")
            if let year = year {
                Text("Published: \(year)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            let publisherText = edition.displayPublisher ?? ""
            Text("Publisher: \(publisherText)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    /// Fetches editions for the selected book using OpenLibraryService.
    private func fetchEditions() {
        isLoading = true
        Task {
            do {
                let workId = selectedBook.key
                let fetchedEditions = try await OpenLibraryService.shared.getEditions(workId: workId)
                DispatchQueue.main.async {
                    self.editions = fetchedEditions
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load editions: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}
