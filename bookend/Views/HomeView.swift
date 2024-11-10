import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [Book]
    @Query private var goals: [ReadingGoal]
    @Query private var sessions: [ReadingSession]
    @State private var showingAddBook = false
    
    var body: some View {
        NavigationStack {
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            
            ScrollView {
                VStack(spacing: screenHeight * 0.025) {
                    Text("Bookends")
                        .font(.system(size: screenWidth * 0.08))
                        .bold()
                        .frame(maxWidth: screenWidth, alignment: .leading)
                        .padding(.horizontal, screenWidth * 0.05)
                        .padding(.top, screenHeight * 0.07)
                        .padding(.leading, screenWidth * 0.05)
                    Spacer()
                    GoalRings(goals: goals, sessions: sessions)
                        .frame(maxWidth: screenWidth, alignment: .center)
                        .padding(.horizontal, screenWidth * 0.05)
                    Text("Jump back in...")
                        .bold()
                        .frame(maxWidth: screenWidth, alignment: .leading)
                        .padding(.leading, screenWidth * 0.05)
                        .font(.system(size: screenWidth * 0.035))
                    if books.isEmpty {
                        EmptyBooksList(showingAddBook: $showingAddBook)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        BookCarousel(books: books, modelContext: modelContext)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, screenWidth * 0.05)
                    }
                }
                .padding(.bottom, screenHeight * 0.025)
            }
            .scrollDisabled(true)
            .navigationBarHidden(true)
            .edgesIgnoringSafeArea(.top)
            .sheet(isPresented: $showingAddBook) {
                BookAddView()
            }
        }
    }
}

private struct EmptyBooksList: View {
    @Binding var showingAddBook: Bool
    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        VStack {
            Text("No books added yet.")
                .foregroundColor(.gray)
                .font(.system(size: screenWidth * 0.04))
                .padding(.bottom, screenHeight * 0.025)
            
            Button(action: {
                showingAddBook = true
            }) {
                Text("Add a Book")
                    .font(.system(size: screenWidth * 0.04))
                    .foregroundColor(.purple)
                    .padding(.vertical, screenHeight * 0.015)
                    .padding(.horizontal, screenWidth * 0.05)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.bottom, screenHeight * 0.1)
    }
}

private struct BookCarousel: View {
    let books: [Book]
    let modelContext: ModelContext
    @Query private var allSessions: [ReadingSession]
    
    var sortedBooks: [Book] {
        Array(books.sorted { book1, book2 in
            let lastSession1 = allSessions
                .filter { $0.book?.persistentModelID == book1.persistentModelID }
                .max(by: { $0.date < $1.date })?.date ?? .distantPast
            let lastSession2 = allSessions
                .filter { $0.book?.persistentModelID == book2.persistentModelID }
                .max(by: { $0.date < $1.date })?.date ?? .distantPast
            return lastSession1 > lastSession2
        }
        .prefix(10))
    }
    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: screenWidth * 0.05) {
                ForEach(sortedBooks) { book in
                    BookCard(book: book, onDelete: {
                        book.cleanupStoredImage()
                        modelContext.delete(book)
                    }, currentGroup: nil)
                }
            }
            .padding(.horizontal, screenWidth * 0.05)
        }
        .frame(height: screenHeight * 0.25)
        .padding(.bottom, screenHeight * 0.1)
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Book.self, ReadingGoal.self, ReadingSession.self, configurations: config)
        
        // Add sample data
        let context = container.mainContext
        
        // Create a sample book
        let book = Book(
            title: "The Great Gatsby", 
            author: "F. Scott Fitzgerald",
            totalPages: 180,
            externalReference: ["openLibraryKey": "OL26874A"]
        )
        context.insert(book)
        
        // Create a sample reading goal
        let goal = ReadingGoal(
            type: .books,
            target: 12,
            period: .yearly
        )
        context.insert(goal)
        
        // Create a sample reading session
        let session = ReadingSession(
            id: UUID(),
            book: book,
            startPage: 1,
            endPage: 20,
            duration: 1800,
            date: Date()
        )
        context.insert(session)
        
        return HomeView()
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview")
    }
}
