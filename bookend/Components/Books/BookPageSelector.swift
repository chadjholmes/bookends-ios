import SwiftUI

struct BookPageSelector: View {
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    @State private var showingCurrentPagePicker = false

    var body: some View {
        VStack {
            // Current Page Display with Slider
            HStack {
                Button(action: {
                    showingCurrentPagePicker.toggle()
                    if showingCurrentPagePicker {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }) {
                    Text("Current Page: \(currentPage) of \(totalPages)")
                        .font(.headline)
                        .foregroundColor(Color("Accent1")) // Change text color to indicate it's tappable
                }
                .buttonStyle(PlainButtonStyle()) // Remove default button styling
                Spacer()
            }
            .padding(.bottom, 8)
            .background(Color(.systemGray6)) // Background for the button
            .cornerRadius(8) // Rounded corners for the button background

            // Slider for Page Selection
            if totalPages > 0 {
                Slider(value: Binding(
                    get: { Double(currentPage) },
                    set: { newValue in
                        currentPage = Int(newValue)
                    }
                ), in: 0...Double(totalPages), step: 1)
                .accentColor(Color("Accent1"))
            } else {
                VStack {
                    Text("😢 We couldn't find total pages for this title 😢") // Note about page counts
                        .font(.headline)
                        .foregroundColor(.gray) // Change text color to indicate no pages
                        .padding(.top, 4)
                    Text("you can still adjust the total below to match your copy!")
                        .font(.subheadline)
                        .foregroundColor(.gray) // Change text color to indicate no pages
                }
                .padding(.top, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }

            // Inline TextField for Current Page Input
            if showingCurrentPagePicker {
                HStack {
                    TextField("Enter Page", value: $currentPage, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .frame(width: 80)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical, 8)
                        .onChange(of: currentPage) { newValue in
                            if newValue > totalPages {
                                currentPage = totalPages
                            }
                        }
                        .toolbar {
                            ToolbarItem(placement: .keyboard) {
                                HStack {
                                    Spacer()
                                    Button("Done") {
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        showingCurrentPagePicker = false
                                    }
                                }
                            }
                        }

                    Text("of \(totalPages)")
                        .padding(.leading, 4)
                }
                .padding(.top, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding() // Add padding around the VStack
        .background(Color(.systemGray6)) // Background for the entire selector
        .cornerRadius(8) // Rounded corners for the entire selector
        .onTapGesture {
            // Dismiss the keyboard and close the TextField if tapped outside
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            showingCurrentPagePicker = false
        }
    }
}
