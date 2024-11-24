import SwiftUI
import SwiftData

struct ReadingSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let book: Book
    @Binding var currentPage: Int
    
    @State private var startPage: Int
    @State private var endPage: Int // Change to Int for Picker selection
    @State private var duration: Int // Duration in seconds
    @State private var date = Date()
    
    // New state variables for duration input as Strings
    @State private var inputHours: String = "0"
    @State private var inputMinutes: String = "0"
    @State private var inputSeconds: String = "0"

    @State private var showingStartPicker = false
    @State private var showingEndPicker = false
    
    var onSessionAdded: ((ReadingSession) -> Void)?
    var existingSession: ReadingSession? // New optional property for existing session
    
    // Updated initializer to accept an optional ReadingSession
    init(book: Book, currentPage: Binding<Int>, duration: Int? = nil, startPage: Int? = nil, endPage: Int? = nil, date: Date? = nil, onSessionAdded: ((ReadingSession) -> Void)? = nil, existingSession: ReadingSession? = nil) {
        self.book = book
        _currentPage = currentPage
        self.onSessionAdded = onSessionAdded
        
        // Initialize state variables based on existing session or defaults
        if let session = existingSession {
            self._startPage = State(initialValue: session.startPage)
            self._endPage = State(initialValue: session.endPage)
            self._duration = State(initialValue: session.duration)
            self._date = State(initialValue: session.date)
            // Initialize input fields based on existing session duration
            let totalDuration = session.duration
            self._inputHours = State(initialValue: "\(totalDuration / 3600)")
            self._inputMinutes = State(initialValue: "\((totalDuration % 3600) / 60)")
            self._inputSeconds = State(initialValue: "\(totalDuration % 60)")
            self.existingSession = existingSession
        } else {
            self._startPage = State(initialValue: startPage ?? currentPage.wrappedValue)
            self._endPage = State(initialValue: endPage ?? currentPage.wrappedValue)
            let totalDuration = duration ?? 30 // Default to 30 seconds if no duration is provided
            self._duration = State(initialValue: totalDuration)
            self._inputHours = State(initialValue: "\(totalDuration / 3600)")
            self._inputMinutes = State(initialValue: "\((totalDuration % 3600) / 60)")
            self._inputSeconds = State(initialValue: "\(totalDuration % 60)")
            self._date = State(initialValue: date ?? Date())
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                DatePicker("Date", selection: $date, displayedComponents: [.date])
                // HStack for Start Page and End Page Picker
                HStack() {
                    HStack() {
                        Text("Start Page:")
                        TextField("Page", text: Binding(
                            get: { String(startPage) },
                            set: { newValue in
                                if let page = Int(newValue), page >= 0 {
                                    startPage = page
                                }
                            }
                        ))
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                        .padding(6)
                        .background(Color(UIColor.systemGray6)) // Light grey that adapts to dark/light mode
                        .cornerRadius(8)
                        .toolbar {
                            ToolbarItem(placement: .keyboard) {
                                HStack {
                                    Spacer()
                                    Button("Done") {
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    }
                                }
                            }
                        }
                    }
                    Spacer()
                    HStack() {
                        Text("End Page:")
                        TextField("Page", text: Binding(
                            get: { String(endPage) },
                            set: { newValue in
                                if let page = Int(newValue), page >= startPage, page <= book.totalPages {
                                    endPage = page
                                }
                            }
                        ))
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                        .padding(6)
                        .background(Color(UIColor.systemGray6)) // Light grey that adapts to dark/light mode
                        .cornerRadius(8)
                        .toolbar {
                            ToolbarItem(placement: .keyboard) {
                                HStack {
                                    Spacer()
                                    Button("Done") {
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    }
                                }
                            }
                        }
                    }
                }

                // Duration Input Section using MultiPicker
                VStack(spacing: 20) {
                    Text("Duration")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center) // Center the Duration text

                    MultiPicker(data: [
                        ("Hours", Array(0...23).map { "\($0)" }), // Hours from 0 to 23
                        ("Minutes", Array(0...59).map { "\($0)" }), // Minutes from 0 to 59
                        ("Seconds", Array(0...59).map { "\($0)" }) // Seconds from 0 to 59
                    ], selection: Binding(
                        get: {
                            [inputHours, inputMinutes, inputSeconds]
                        },
                        set: { newValue in
                            inputHours = newValue[0]
                            inputMinutes = newValue[1]
                            inputSeconds = newValue[2]
                        }
                    ))
                    .frame(height: 200) // Set fixed height
                    .frame(maxWidth: .infinity, alignment: .center) // Center horizontally
                }
                .frame(maxWidth: .infinity) // Make the VStack take full width
                .padding(.top, UIScreen.main.bounds.height * 0.075)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .navigationTitle("New Reading Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveSession()
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 40)
    }
    
    private func saveSession() {
        // Convert input fields to integers
        let hours = Int(inputHours) ?? 0
        let minutes = Int(inputMinutes) ?? 0
        let seconds = Int(inputSeconds) ?? 0

        // Calculate total duration in seconds
        let totalDurationFromInput = (hours * 3600) + (minutes * 60) + seconds
        let finalDuration = totalDurationFromInput > 0 ? totalDurationFromInput : duration
        
        if let existingSession = existingSession {
            print("Updating existing session")
            // Update existing session
            existingSession.startPage = startPage
            existingSession.endPage = endPage
            existingSession.duration = finalDuration
            existingSession.date = date
        } else {
            print("Creating new session")
            // Create new session
            let session = ReadingSession(
                book: book,
                startPage: startPage,
                endPage: endPage,
                duration: finalDuration,
                date: date
            )
            modelContext.insert(session)
        }
        
        // Update both the book and the binding
        if endPage > book.currentPage {
            book.currentPage = endPage
            currentPage = endPage
        }
        
        do {
            try modelContext.save()
            print("Reading session saved successfully")
            dismiss()
        } catch {
            print("Failed to save reading session: \(error.localizedDescription)")
        }
    }
}

// Preview
struct ReadingSessionView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock Book instance for preview
        let mockBook = Book(
            title: "Sample Book",
            author: "Author Name",
            totalPages: 100,
            currentPage: 1,
            externalReference: [:]
        )
        
        ReadingSessionView(book: mockBook, currentPage: .constant(1), duration: 120) // Example with 120 seconds
            .previewLayout(.sizeThatFits) // Adjust the preview layout
            .padding() // Add padding for better visibility
    }
} 
