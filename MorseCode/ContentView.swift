//
//  ContentView.swift
//  MorseCode
//
//  Created by Joseph Brinker on 3/22/25.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var isEncodingMode: Bool = false
    @StateObject private var morseEncoder = MorseCodeEncoder()
    
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
                            .onChange(of: inputText) { newText in
                                if isEncodingMode {
                                    outputText = translateText(text: inputText)
                                } else {
                                    outputText = translateCode(morseCode: inputText)
                                }
                            }
                            .disabled(morseEncoder.isFlashing)
                        
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
                    // Flash button
                    Button(action: {
                        if morseEncoder.isFlashing {
                            morseEncoder.stopFlashing()
                        } else {
                            morseEncoder.startFlashing(for: outputText)
                        }
                    }) {
                        Text(morseEncoder.isFlashing ? "Stop Flashing" : "Flash Morse Code")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(morseEncoder.isFlashing ? Color.red : Color.black)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .disabled(!isEncodingMode)
                    
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
