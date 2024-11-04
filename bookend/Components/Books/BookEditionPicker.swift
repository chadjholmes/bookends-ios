import SwiftUI

struct BookEditionPicker: View {
    let edition: OpenLibraryEdition
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                AsyncImageView(
                    url: edition.coverImageUrl,
                    width: 50,
                    height: 75
                )
                
                EditionDetails(edition: edition)
            }
        }
    }
}

struct EditionDetails: View {
    let edition: OpenLibraryEdition
    
    var body: some View {
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
                Text("Published: \(String(year))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("Publisher: \(edition.displayPublisher)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
} 