import SwiftUI

struct BookCard: View {
    let book: Book
    let onDelete: () -> Void
    let currentGroup: BookGroup?
    
    var body: some View {
        NavigationLink(destination: BookView(book: book, currentPage: book.currentPage)) {
            BookCover(book: book, currentPage: book.currentPage)
        }
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                if let group = currentGroup {
                    Label("Remove from \(group.name)", systemImage: "folder.badge.minus")
                } else {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
        
} 
