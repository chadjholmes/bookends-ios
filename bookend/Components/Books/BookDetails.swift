import SwiftUI

struct BookDetails: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(book.title)
                .lineLimit(2)
                .font(.title2)
                .bold()
                .foregroundColor(Color("Accent1"))
                .fixedSize(horizontal: false, vertical: true)
            
            if !book.author.isEmpty {
                Text("by \(book.author)")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            BookMetadata(book: book)
        }
        .padding()
    }
}

struct BookMetadata: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
        
            if let publisher = book.publisher {
                Text("Publisher: \(publisher)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top)
            }
            if let publishYear = book.publishYear {
                Text("Published: \(String(publishYear))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text("Total Pages: \(String(book.totalPages))")
                .font(.subheadline)
                .foregroundColor(.secondary)
    
            if let isbn = book.isbn {
                Text("ISBN: \(isbn)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Text("Added on: \(book.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
} 
