import SwiftUI
import SwiftData

struct BookGroupSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allGroups: [BookGroup]
    @Query private var relationships: [BookGroupRelationship]
    
    let book: Book
    
    @State private var showingAddGroup = false
    
    private var bookRelationships: [BookGroupRelationship] {
        relationships.filter { relationship in
            relationship.book == book
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(allGroups) { group in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(group.name)
                                .font(.headline)
                            if let description = group.groupDescription {
                                Text(description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if bookRelationships.contains(where: { $0.group.id == group.id }) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.purple)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleGroup(group)
                    }
                }
            }
            .navigationTitle("Edit Groups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddGroup = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGroup) {
                BookGroupAddView()
            }
        }
    }
    
    private func toggleGroup(_ group: BookGroup) {
        if let existingRelationship = bookRelationships.first(where: { $0.group.id == group.id }) {
            // Remove from group
            modelContext.delete(existingRelationship)
        } else {
            // Add to group
            let relationship = BookGroupRelationship(book: book, group: group)
            modelContext.insert(relationship)
        }
    }
} 