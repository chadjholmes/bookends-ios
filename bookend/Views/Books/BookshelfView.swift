import SwiftUI
import SwiftData

struct BookshelfView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.title) private var books: [Book]
    @Query(sort: \BookGroup.name) private var groups: [BookGroup]
    @Query(sort: \BookGroupRelationship.dateAdded) private var relationships: [BookGroupRelationship]
    @State private var showingAddBook = false
    @State private var showingAddGroup = false
    @State private var selectedGroupId: UUID?
    @State private var bookForGroupSelection: Book?
    @State private var bookForEditing: Book?
    
    private var selectedGroup: BookGroup? {
        guard let groupId = selectedGroupId else { return nil }
        return groups.first { $0.id == groupId }
    }
    
    var filteredBooks: [Book] {
        if let groupId = selectedGroupId {
            guard groups.contains(where: { $0.id == groupId }) else {
                DispatchQueue.main.async {
                    selectedGroupId = nil
                }
                return books
            }
            return relationships
                .filter { $0.group.id == groupId }
                .map { $0.book }
        }
        return books
    }
    
    private func cleanupOrphanedData() {
        // Clean up relationships with invalid books or groups
        for relationship in relationships {
            if !books.contains(where: { $0.id == relationship.book.id }) ||
               !groups.contains(where: { $0.id == relationship.group.id }) {
                modelContext.delete(relationship)
            }
        }
        
        // Clean up any invalid group references
        if let currentGroupId = selectedGroupId,
           !groups.contains(where: { $0.id == currentGroupId }) {
            selectedGroupId = nil
        }
        
        // Save changes
        try? modelContext.save()
    }
    
    // Add this temporary function
    private func nukeGroupData() {
        // Delete all relationships first
        relationships.forEach { relationship in
            modelContext.delete(relationship)
        }
        
        // Delete all groups
        groups.forEach { group in
            modelContext.delete(group)
        }
        
        // Save changes
        try? modelContext.save()
        
        // Reset selected group
        selectedGroupId = nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    // Groups horizontal scroll
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            Button {
                                selectedGroupId = nil
                            } label: {
                                Text("All Books")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedGroupId == nil ? .purple : .gray.opacity(0.2))
                                    .foregroundColor(selectedGroupId == nil ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            ForEach(groups) { group in
                                Button {
                                    selectedGroupId = group.id
                                } label: {
                                    Text(group.name)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedGroupId == group.id ? .purple : .gray.opacity(0.2))
                                        .foregroundColor(selectedGroupId == group.id ? .white : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .contextMenu {
                                    Button("Edit Group") {
                                        // TODO: Show edit group sheet
                                    }
                                    Button("Delete Group", role: .destructive) {
                                        if selectedGroupId == group.id {
                                            selectedGroupId = nil
                                        }
                                        
                                        // First, delete all relationships for this group
                                        let relationshipsToDelete = relationships.filter { $0.group.id == group.id }
                                        relationshipsToDelete.forEach { modelContext.delete($0) }
                                        
                                        // Then delete the group
                                        modelContext.delete(group)
                                        
                                        // Save changes
                                        try? modelContext.save()
                                        
                                        // Run cleanup
                                        cleanupOrphanedData()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Books grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        ForEach(filteredBooks) { book in
                            BookCard(book: book, onDelete: {
                                if let currentGroup = selectedGroup {
                                    if let relationshipToDelete = relationships.first(where: { 
                                        $0.book.id == book.id && $0.group.id == currentGroup.id 
                                    }) {
                                        modelContext.delete(relationshipToDelete)
                                    }
                                } else {
                                    relationships.filter { $0.book.id == book.id }.forEach { relationship in
                                        modelContext.delete(relationship)
                                    }
                                    book.cleanupStoredImage()
                                    modelContext.delete(book)
                                }
                            }, currentGroup: selectedGroup)
                        }
                    }
                    .padding()
                }
                .navigationTitle("") // Hide the default navigation title
                .toolbar(.hidden, for: .navigationBar)
                .safeAreaInset(edge: .top) {
                    HStack {
                        Text("Bookshelf")
                            .font(.largeTitle)
                            .bold()
                        Spacer()
                        HStack(spacing: 32) {
                            Button {
                                showingAddGroup = true
                            } label: {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 24))
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(.purple)
                            }
                            Button {
                                showingAddBook = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 24))
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding(.leading)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground).opacity(0.9)) // Background color for the header
                    .shadow(radius: 2) // Optional shadow for depth
                }
                .sheet(isPresented: $showingAddBook) {
                    BookAddView()
                }
                .sheet(isPresented: $showingAddGroup) {
                    BookGroupAddView()
                }
                .sheet(item: $bookForGroupSelection) { book in
                    BookGroupSelectionView(book: book)
                }
                .sheet(item: $bookForEditing) { book in
                    BookEditView(book: book) { savedBook, success in
                        if success {
                            // Handle saving the book in BookshelfView
                            do {
                                modelContext.insert(savedBook) // Insert the book into the context
                                try modelContext.save() // Save the context
                                print("Successfully saved book: \(savedBook.title)")
                                bookForEditing = nil
                            } catch {
                                print("Failed to save book: \(error.localizedDescription)")
                            }
                        } else {
                            // Handle the case where a duplicate was found
                            print("Duplicate book found, not saving.")
                        }
                    }
                }
            }
            .onAppear {
                print("Books in context:")
                for book in books {
                    print("Book: \(book.title ?? "Unknown Title")")
                }
                cleanupOrphanedData()
            }
        }
    }
    
    private func showGroupSelection(for book: Book) {
        bookForGroupSelection = book
    }
}

// New view for adding groups
struct BookGroupAddView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var groupDescription = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Group Name", text: $name)
                TextField("Description (optional)", text: $groupDescription)
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let group = BookGroup(name: name, groupDescription: groupDescription)
                        modelContext.insert(group)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        BookshelfView()
    }
    .modelContainer(for: [
        Book.self,
        ReadingGoal.self,
        ReadingSession.self,
        BookGroup.self,
        BookGroupRelationship.self
    ], inMemory: true)
    .onAppear {
        Task { @MainActor in
            await createPreviewData()
        }
    }
}

@MainActor
private func createPreviewData() async {
    guard let container = try? ModelContainer(
        for: Book.self,
        ReadingGoal.self,
        ReadingSession.self,
        BookGroup.self,
        BookGroupRelationship.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return }
    
    let context = container.mainContext
    
    // Sample groups
    let currentlyReading = BookGroup(name: "Currently Reading", groupDescription: "Books I'm actively reading")
    let favorites = BookGroup(name: "Favorites", groupDescription: "My all-time favorites")
    let sciFi = BookGroup(name: "Science Fiction", groupDescription: "Sci-fi collection")
    let toRead = BookGroup(name: "Want to Read", groupDescription: "Reading wishlist")
    
    [currentlyReading, favorites, sciFi, toRead].forEach { context.insert($0) }
    
    // Sample books
    let books: [Book] = [
        Book(
            title: "Project Hail Mary",
            author: "Andy Weir",
            genre: "Science Fiction",
            notes: "Currently reading",
            totalPages: 496,
            isbn: "978-0593135204",
            publisher: "Ballantine Books",
            publishYear: 2021,
            currentPage: 200,
            externalReference: ["openLibraryKey": "OL28096123M"]
        ),
        // ... other books ...
    ]
    
    books.forEach { book in
        context.insert(book)
        
        if book.currentPage > 0 {
            let session = ReadingSession(
                book: book,
                startPage: 1,
                endPage: book.currentPage,
                duration: Int.random(in: 600...3600),
                date: Date().addingTimeInterval(-Double.random(in: 0...86400))
            )
            context.insert(session)
        }
        
        // Add relationships
        if book.currentPage > 0 && book.currentPage < book.totalPages {
            context.insert(BookGroupRelationship(book: book, group: currentlyReading))
        }
        if book.title == "Dune" {
            context.insert(BookGroupRelationship(book: book, group: favorites))
        }
        if book.genre == "Science Fiction" {
            context.insert(BookGroupRelationship(book: book, group: sciFi))
        }
        if book.currentPage == 0 {
            context.insert(BookGroupRelationship(book: book, group: toRead))
        }
    }
} 