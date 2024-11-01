import SwiftUI
import SwiftData

struct BookListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [Book]
    @State private var showingAddBook = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if books.isEmpty {
                    VStack {
                        Text("No books added yet.")
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(books) { book in
                            BookRow(book: book)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        book.cleanupStoredImage()
                                        modelContext.delete(book)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingAddBook = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Books")
            .sheet(isPresented: $showingAddBook) {
                BookAddView()
            }
        }
    }
}

struct BookRow: View {
    let book: Book
    
    var body: some View {
        NavigationLink(destination: BookView(book: book, currentPage: book.currentPage)) {
            HStack {
                if let image = try? book.loadCoverImage() {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 70)
                        .cornerRadius(4)
                } else {
                    Image(systemName: "book.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 70)
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading) {
                    Text(book.title)
                        .font(.headline)
                    let author = book.author
                    Text("by \(author)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("\(book.currentPage)/\(book.totalPages) pages")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
        }
    }
} 
