import SwiftUI
import AVFoundation

struct EncodeView: View {
    @StateObject private var morseEncoder = MorseCodeService()
    @State private var inputText: String = ""
    
    var body: some View {
        ZStack {
            // Background color that changes based on flashing state
            morseEncoder.flashColor
                .edgesIgnoringSafeArea(.all)
                .animation(.easeInOut(duration: 0.1), value: morseEncoder.flashColor)
            
            VStack(spacing: 20) {
                Text("Morse Code Flasher")
                    .font(.largeTitle)
                    .foregroundColor(morseEncoder.flashColor == .black ? .white : .black)
                    .padding()
                
                TextField("Enter text to encode", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .foregroundColor(.black)
                    .disabled(morseEncoder.isFlashing)
                
                Button(action: {
                    if morseEncoder.isFlashing {
                        morseEncoder.stopFlashing()
                    } else {
                        morseEncoder.startFlashing(for: inputText)
                    }
                }) {
                    Text(morseEncoder.isFlashing ? "Stop" : "Start Flashing")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(morseEncoder.isFlashing ? Color.red : Color.blue)
                        .cornerRadius(10)
                }
                
                if !morseEncoder.isFlashing {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Morse Code Translation:")
                            .font(.headline)
                            .foregroundColor(morseEncoder.flashColor == .black ? .white : .black)
                        
                        Text(morseEncoder.textToMorse(inputText))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(morseEncoder.flashColor == .black ? .white : .black)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(5)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Encode")
        .navigationBarTitleDisplayMode(.inline)
    }
}
