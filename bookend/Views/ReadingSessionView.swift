import SwiftUI
import SwiftData

struct ReadingSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let book: Book
    @Binding var currentPage: Int
    
    @State private var startPage: Int
    @State private var endPage: Int
    @State private var duration: Int = 30
    @State private var date = Date()
    
    @State private var showingStartPicker = false
    @State private var showingEndPicker = false
    @State private var showingDurationPicker = false
    
    init(book: Book, currentPage: Binding<Int>) {
        self.book = book
        _currentPage = currentPage
        _startPage = State(initialValue: currentPage.wrappedValue)
        _endPage = State(initialValue: currentPage.wrappedValue)
    }
    
    var body: some View {
        Form {
            Section("Reading Progress") {
                Button {
                    showingStartPicker = true
                } label: {
                    HStack {
                        Text("Start Page")
                        Spacer()
                        Text("\(startPage)")
                            .foregroundColor(.gray)
                    }
                }
                
                Button {
                    showingEndPicker = true
                } label: {
                    HStack {
                        Text("End Page")
                        Spacer()
                        Text("\(endPage)")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Section("Session Details") {
                DatePicker("Date", selection: $date, displayedComponents: [.date])
                
                Button {
                    showingDurationPicker = true
                } label: {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text("\(duration) min")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle("New Reading Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveSession()
                }
            }
        }
        .sheet(isPresented: $showingStartPicker) {
            NavigationView {
                Picker("Start Page", selection: $startPage) {
                    ForEach(0...book.totalPages, id: \.self) { page in
                        Text("\(page)").tag(page)
                    }
                }
                .pickerStyle(.wheel)
                .navigationTitle("Select Start Page")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showingStartPicker = false
                        }
                    }
                }
            }
            .presentationDetents([.height(250)])
        }
        .sheet(isPresented: $showingEndPicker) {
            NavigationView {
                Picker("End Page", selection: $endPage) {
                    ForEach(startPage...book.totalPages, id: \.self) { page in
                        Text("\(page)").tag(page)
                    }
                }
                .pickerStyle(.wheel)
                .navigationTitle("Select End Page")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showingEndPicker = false
                        }
                    }
                }
            }
            .presentationDetents([.height(250)])
        }
        .sheet(isPresented: $showingDurationPicker) {
            NavigationView {
                Picker("Duration", selection: $duration) {
                    ForEach(5...240, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                .pickerStyle(.wheel)
                .navigationTitle("Select Duration")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showingDurationPicker = false
                        }
                    }
                }
            }
            .presentationDetents([.height(250)])
        }
    }
    
    private func saveSession() {
        let session = ReadingSession(
            book: book,
            startPage: startPage,
            endPage: endPage,
            duration: duration,
            date: date
        )
        
        modelContext.insert(session)
        
        // Update both the book and the binding
        book.currentPage = endPage
        currentPage = endPage
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save reading session: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Book.self, configurations: config)
    
    let book = Book(
        title: "Sample Book",
        author: "John Doe",
        genre: "",
        notes: "",
        totalPages: 300,
        isbn: nil,
        publisher: nil,
        publishYear: nil,
        externalReference: [:]
    )
    
    NavigationView {
        ReadingSessionView(book: book, currentPage: .constant(50))
    }
    .modelContainer(container)
} 