import SwiftUI
import SwiftData

struct BookListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [Book]
    @Query private var goals: [ReadingGoal]
    @Query private var sessions: [ReadingSession]
    @State private var showingAddBook = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    // Add GoalRings at the top
                    GoalRings(goals: goals, sessions: sessions)
                        .padding(.top, 40)
                        .frame(height: 400)
                    
                    Spacer() // This pushes the carousel down
                    
                    if books.isEmpty {
                        Text("No books added yet.")
                            .foregroundColor(.gray)
                            .padding(.bottom, 80) // Space for the add button
                    } else {
                        // Horizontal book carousel
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 20) {
                                ForEach(books) { book in
                                    NavigationLink(destination: BookView(book: book, currentPage: book.currentPage)) {
                                        BookCover(book: book)
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            book.cleanupStoredImage()
                                            modelContext.delete(book)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .overlay(
                                HStack {
                                    Spacer()
                                    LinearGradient(
                                        gradient: Gradient(colors: [.clear, Color(.systemBackground).opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(width: 40)
                                },
                                alignment: .trailing
                            )
                        }
                        .frame(height: 200)
                        .padding(.bottom, 80) // Space for the add button
                    }
                }
                
                // Add button
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
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("📚 Bookends")
            .sheet(isPresented: $showingAddBook) {
                BookAddView()
            }
        }
    }
}

struct BookCover: View {
    let book: Book
    
    var progressPercentage: CGFloat {
        guard book.totalPages > 0 else { return 0 }
        return CGFloat(book.currentPage) / CGFloat(book.totalPages)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            if let image = try? book.loadCoverImage() {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 150)
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .overlay(
                        Circle()
                            .trim(from: 0, to: progressPercentage)
                            .stroke(Color.white, lineWidth: 3)
                            .rotationEffect(.degrees(-90))
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.8))
                                    .frame(width: 34, height: 34)
                            )
                            .padding(8),
                        alignment: .bottomTrailing
                    )
            } else {
                Image(systemName: "book.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 150)
                    .foregroundColor(.gray)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Text(book.title)
                .font(.caption)
                .lineLimit(1)
                .frame(width: 100)
            
            Text(book.author)
                .font(.caption2)
                .foregroundColor(.gray)
                .lineLimit(1)
                .frame(width: 100)
        }
    }
}

struct GoalRings: View {
    let goals: [ReadingGoal]
    let sessions: [ReadingSession]
    
    // Computed properties to find goals by period
    private var dailyGoal: ReadingGoal? {
        goals.first { $0.period == .daily && $0.isActive }
    }
    
    private var monthlyGoal: ReadingGoal? {
        goals.first { $0.period == .monthly && $0.isActive }
    }
    
    private var yearlyGoal: ReadingGoal? {
        goals.first { $0.period == .yearly && $0.isActive }
    }
    
    // Calculate progress for each ring
    private func progress(for goal: ReadingGoal?) -> Double {
        guard let goal = goal else { return 0.0 }
        return min(1.0, goal.calculateProgress(from: sessions))
    }
    
    var body: some View {
        ZStack {
            // Daily Goal (Outer Ring)
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                .frame(width: 280, height: 280)
            Circle()
                .trim(from: 0, to: progress(for: dailyGoal))
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(-90))
            
            // Monthly Goal (Middle Ring)
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                .frame(width: 220, height: 220)
            Circle()
                .trim(from: 0, to: progress(for: monthlyGoal))
                .stroke(Color.green, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-90))
            
            // Yearly Goal (Inner Ring)
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                .frame(width: 160, height: 160)
            Circle()
                .trim(from: 0, to: progress(for: yearlyGoal))
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
            
            // Color key centered inside rings
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text("Daily")
                        .font(.caption2)
                }
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Monthly")
                        .font(.caption2)
                }
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    Text("Yearly")
                        .font(.caption2)
                }
            }
            .padding(8)
            .background(Color(UIColor.systemBackground).opacity(0.8))
            .cornerRadius(8)
        }
        .padding(.top, -30)
        .animation(.easeInOut, value: goals)
    }
}
