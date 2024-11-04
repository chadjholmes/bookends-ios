import SwiftUI

struct BookSearchResult: View {
    let book: OpenLibraryBook
    let onSelect: (OpenLibraryBook) -> Void
    
    var body: some View {
        Button(action: { onSelect(book) }) {
            HStack {
                AsyncImageView(
                    url: book.coverImageUrl,
                    width: 50,
                    height: 75
                )
                
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
} 