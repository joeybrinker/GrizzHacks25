import SwiftUI
import AVFoundation

struct ContentView: View {
  
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var isEncodingMode: Bool = true
    @StateObject private var morseEncoder = MorseCodeEncoder()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Mode selector
                    Picker("Mode", selection: $isEncodingMode) {
                        Text("Text to Morse").tag(true)
                        Text("Morse to Text").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: isEncodingMode) { _ in
                        // Clear input and output when switching modes
                        inputText = ""
                        outputText = ""
                    }
                    
                    // Input field
                    VStack(alignment: .leading) {
                        Text(isEncodingMode ? "Enter Text:" : "Enter Morse Code:")
                            .font(.headline)
                            .padding(.leading)
                        
                        TextEditor(text: $inputText)
                            .frame(height: 100)
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                            .padding(.horizontal)
                            .focused($isInputFocused)
                            .onChange(of: inputText) { newText in
                                if isEncodingMode {
                                    outputText = translateText(text: inputText)
                                } else {
                                    outputText = translateCode(morseCode: inputText)
                                }
                            }
                            .disabled(morseEncoder.isFlashing)
                            .background(Color(UIColor.systemBackground))
                    }
                    
                    // Output field
                    VStack(alignment: .leading) {
                        Text(isEncodingMode ? "Morse Code:" : "Decoded Text:")
                            .font(.headline)
                            .padding(.leading)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: .constant(outputText))
                                .frame(height: 100)
                                .padding(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                                .padding(.horizontal)
                                .disabled(true)
                                .background(Color(UIColor.systemBackground))
                            
                            if outputText.isEmpty {
                                Text("Output will appear here")
                                    .foregroundColor(Color.gray.opacity(0.5))
                                    .padding()
                                    .padding(.top, 4)
                                    .padding(.leading, 8)
                            }
                        }
                    }
                    
                    // Flash button
                    Button(action: {
                        if morseEncoder.isFlashing {
                            morseEncoder.stopFlashing()
                        } else {
                            morseEncoder.startFlashing(for: outputText)
                        }
                    }) {
                        HStack {
                            Image(systemName: morseEncoder.isFlashing ? "stop.fill" : "bolt.fill")
                            Text(morseEncoder.isFlashing ? "Stop Flashing" : "Flash Morse Code")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(morseEncoder.isFlashing ? Color.red : Color.black)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .disabled(!isEncodingMode || outputText.isEmpty)
                    .opacity(!isEncodingMode || outputText.isEmpty ? 0.6 : 1.0)
                    
                    // Copy button
                    Button(action: {
                        UIPasteboard.general.string = outputText
                        // Show feedback for copying
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }) {
                        Label("Copy Result", systemImage: "doc.on.doc")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .disabled(outputText.isEmpty)
                    .opacity(outputText.isEmpty ? 0.6 : 1.0)
                    
                    // Clear button
                    Button(action: {
                        inputText = ""
                        outputText = ""
                        if morseEncoder.isFlashing {
                            morseEncoder.stopFlashing()
                        }
                    }) {
                        Label("Clear", systemImage: "trash")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .disabled(inputText.isEmpty && outputText.isEmpty && !morseEncoder.isFlashing)
                    .opacity(inputText.isEmpty && outputText.isEmpty && !morseEncoder.isFlashing ? 0.6 : 1.0)
                    
                    Spacer().frame(height: 20)
                }
                .padding(.top, 10)
                .navigationTitle("Morse Code Translator")
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isInputFocused = false
                        }
                    }
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
    
    // Function to hide keyboard
    private func hideKeyboard() {
        isInputFocused = false
    }
}

// Extension to hide keyboard
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
