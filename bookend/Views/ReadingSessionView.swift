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
    
    // Updated initializer to accept an optional duration
    init(book: Book, currentPage: Binding<Int>, duration: Int? = nil, onSessionAdded: ((ReadingSession) -> Void)? = nil) {
        self.book = book
        _currentPage = currentPage
        _startPage = State(initialValue: currentPage.wrappedValue)
        self.onSessionAdded = onSessionAdded
        
        // Initialize duration and input components
        let totalDuration = duration ?? 30 // Default to 30 seconds if no duration is provided
        self._duration = State(initialValue: totalDuration)
        
        // Calculate hours, minutes, and seconds from total duration
        self._inputHours = State(initialValue: "\(totalDuration / 3600)")
        self._inputMinutes = State(initialValue: "\((totalDuration % 3600) / 60)")
        self._inputSeconds = State(initialValue: "\(totalDuration % 60)")
        
        // Initialize endPage to startPage
        self._endPage = State(initialValue: currentPage.wrappedValue)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                DatePicker("Date", selection: $date, displayedComponents: [.date])
                // HStack for Start Page and End Page Picker
                HStack() {
                    Text("Start Page: \(startPage)")
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

        // Use the calculated total duration or the default duration
        let finalDuration = totalDurationFromInput > 0 ? totalDurationFromInput : duration

        let session = ReadingSession(
            book: book,
            startPage: startPage,
            endPage: endPage, // Use the selected endPage
            duration: finalDuration, // Use the final duration
            date: date
        )
        
        modelContext.insert(session)
        
        // Update both the book and the binding
        book.currentPage = endPage
        currentPage = endPage
        
        do {
            try modelContext.save()
            print("Reading session saved successfully: \(session)") // Log success
            onSessionAdded?(session) // Call the closure to notify about the new session
            dismiss()
        } catch {
            print("Failed to save reading session: \(error.localizedDescription)") // Log error
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
