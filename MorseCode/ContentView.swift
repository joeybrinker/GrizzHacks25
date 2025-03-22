//
//  ContentView.swift
//  MorseCode
//
//  Created by Joseph Brinker on 3/22/25.
//

import SwiftUI

struct ContentView: View {
    
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var isEncodingMode: Bool = false
    
//    var body: some View {
//        VStack {
//            
//            Picker("Mode", selection: $mode) {
//                Text("Text").tag(true)
//                Text("Morse").tag(false)
//            }
//            
//            
//            TextField("Enter Morse Code", text: $input)
//            
//            Text("Translated Morse: \(translateCode(morseCode: input))")
//            
//            
//            Text(translateCode(morseCode: ".... . .-.. .-.. --- / .-- --- .-. .-.. -.."))
//            Text(translateText(text: "Hello World"))
//        }
//        .padding()
//    }
    var body: some View {
            NavigationView {
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
                    }
                    
                    // Convert button
                    Button(action: {
                        if isEncodingMode {
                            outputText = translateText(text: inputText)
                        } else {
                            outputText = translateCode(morseCode: inputText)
                        }
                        // Dismiss keyboard
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }) {
                        Text("Convert")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    
                    // Output field
                    VStack(alignment: .leading) {
                        Text(isEncodingMode ? "Morse Code:" : "Decoded Text:")
                            .font(.headline)
                            .padding(.leading)
                        
                        TextEditor(text: $outputText)
                            .frame(height: 100)
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                            .padding(.horizontal)
                            .disabled(true)
                    }
                    
                    // Copy button
                    Button(action: {
                        UIPasteboard.general.string = outputText
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
                    
                    // Clear button
                    Button(action: {
                        inputText = ""
                        outputText = ""
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
                    
                    Spacer()
                }
                .navigationTitle("Morse Code Translator")
                .padding(.top)
            }
        }
}

#Preview {
    ContentView()
}
