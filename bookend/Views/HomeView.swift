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
            ZStack {
                ScrollView {
                    VStack(spacing: 35) {
                        // Header with more bottom padding
                        Text("Bookends📚")
                            .font(.largeTitle)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 60)
                            .padding(.bottom, 80)
                        
                        // Goals section in its own container
                        VStack(spacing: 0) {
                            GoalRings(goals: goals, sessions: sessions)
                                .frame(height: 250)
                        }
                        .padding(.horizontal)
                        
                        // Books section
                        GeometryReader { geometry in
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Jump back in...")
                                    .bold()
                                    .padding(.horizontal)
                                    .font(.subheadline)
                                
                                if books.isEmpty {
                                    EmptyBooksList(showingAddBook: $showingAddBook)
                                } else {
                                    BookCarousel(books: books, modelContext: modelContext)
                                }
                            }
                            .frame(width: geometry.size.width, 
                                   height: geometry.size.height, 
                                   alignment: .bottom)
                        }
                        .frame(height: UIScreen.main.bounds.height * 0.4)
                    }
                }
                .scrollDisabled(true)
            }
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
        VStack {
            Text("No books added yet.")
                .foregroundColor(.gray)
                .padding(.bottom, 20)
            
            Button(action: {
                showingAddBook = true
            }) {
                Text("Add a Book")
                    .font(.headline)
                    .foregroundColor(.purple)
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.bottom, 80)
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
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 20) {
                ForEach(sortedBooks) { book in
                    BookCard(book: book, onDelete: {
                        book.cleanupStoredImage()
                        modelContext.delete(book)
                    }, currentGroup: nil)
                }
            }
            .padding(.horizontal)
            .overlay(
                TrailingGradient(),
                alignment: .trailing
            )
        }
        .frame(height: 200)
        .padding(.bottom, 80)
    }
}

private struct TrailingGradient: View {
    var body: some View {
        HStack {
            Spacer()
            GradientOverlay(
                direction: .trailing,
                color: Color(.systemBackground)
            )
            .frame(width: 40)
        }
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
            duration: 30,
            date: Date()
        )
        context.insert(session)
        
        return HomeView()
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview")
    }
}
