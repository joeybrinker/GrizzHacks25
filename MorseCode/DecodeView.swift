import SwiftUI

struct DecodeView: View {
    @State private var inputText = ""
    @State private var outputText = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Decode Message")
                .font(.largeTitle)
                .padding(.top)
            
            TextEditor(text: $inputText)
                .frame(height: 150)
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
            
            Button("Decode") {
                // Simple decoding (replace with actual algorithm)
                outputText = decodeMessage(inputText)
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Text("Result:")
                .font(.headline)
                .padding(.top)
            
            Text(outputText)
                .padding()
                .frame(minHeight: 100)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Decode")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Simple decoding function (replace with your algorithm)
    func decodeMessage(_ message: String) -> String {
        return message.map { String(UnicodeScalar(UInt32($0.asciiValue ?? 0) - 1)!) }.joined()
    }
}

