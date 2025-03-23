//
//  MorseCodeView.swift
//  MorseCode
//
//  Created by Solomiya Pylypiv on 3/23/25.
//

import SwiftUI
import AVFoundation

struct MorseCodeView: View {
    @StateObject private var detector = MorseCodeDetector()
    @StateObject private var sender = MorseCodeSender()
    
    @State private var messageToSend: String = ""
    @State private var isCameraActive: Bool = false
    @State private var showCameraPreview: Bool = true
    @State private var showMorseCode: Bool = false
    
    // Camera preview
    private let previewViewSize: CGFloat = 150
    
    var body: some View {
        NavigationView {
            VStack {
                // Camera and detection section
                VStack {
                    Text("Morse Code Two-Way Communication")
                        .font(.headline)
                        .padding()
                    
                    if showCameraPreview {
                        CameraPreviewView()
                            .frame(width: UIScreen.main.bounds.width - 40, height: 200)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    }
                    
                    // Brightness indicator
                    VStack(alignment: .leading) {
                        Text("Detected Light Level: \(Int(detector.detectedBrightness * 100))%")
                            .font(.caption)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .frame(width: geometry.size.width, height: 20)
                                    .opacity(0.3)
                                    .foregroundColor(.gray)
                                
                                Rectangle()
                                    .frame(width: min(CGFloat(detector.detectedBrightness) * geometry.size.width, geometry.size.width), height: 20)
                                    .foregroundColor(detector.detectedBrightness > MorseCode.brightnessThreshold ? .green : .blue)
                            }
                            .cornerRadius(5)
                        }
                        .frame(height: 20)
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal)
                    
                    Divider().padding(.vertical, 8)
                    
                    // Decoded message section
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Decoded Message:")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                detector.resetDetection()
                            }) {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        
                        if showMorseCode {
                            Text(detector.currentMorseSignal)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(2)
                                .padding(.top, 2)
                        }
                        
                        Text(detector.decodedMessage.isEmpty ? "No message detected yet" : detector.decodedMessage)
                            .font(.body)
                            .padding(.vertical, 8)
                            .frame(minHeight: 60, alignment: .topLeading)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
                
                Divider()
                
                // Message sending section
                VStack {
                    HStack {
                        Text("Send Message:")
                            .font(.headline)
                        
                        Spacer()
                        
                        // Toggle camera preview
                        Button(action: {
                            showCameraPreview.toggle()
                        }) {
                            Image(systemName: showCameraPreview ? "eye.slash" : "eye")
                        }
                        
                        // Toggle morse code display
                        Button(action: {
                            showMorseCode.toggle()
                        }) {
                            Image(systemName: "textformat.alt")
                        }
                    }
                    .padding(.horizontal)
                    
                    TextField("Type message to send", text: $messageToSend)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    
                    if sender.isAvailable {
                        VStack {
                            // Morse code preview for the message to send
                            if !messageToSend.isEmpty && showMorseCode {
                                Text("Morse: \(MorseCode.textToMorse(messageToSend))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                                    .padding(.horizontal)
                            }
                            
                            // Send button and progress
                            HStack {
                                Button(action: {
                                    sender.sendMessage(messageToSend)
                                }) {
                                    Text("Send with Flash")
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                .disabled(messageToSend.isEmpty || sender.transmissionProgress > 0 && sender.transmissionProgress < 1)
                                
                                if sender.transmissionProgress > 0 && sender.transmissionProgress < 1 {
                                    Spacer()
                                    
                                    Button(action: {
                                        sender.stopTransmission()
                                    }) {
                                        Text("Cancel")
                                            .foregroundColor(.red)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Progress bar for sending
                            if sender.transmissionProgress > 0 {
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .frame(width: geometry.size.width, height: 8)
                                            .opacity(0.3)
                                            .foregroundColor(.gray)
                                        
                                        Rectangle()
                                            .frame(width: min(CGFloat(sender.transmissionProgress) * geometry.size.width, geometry.size.width), height: 8)
                                            .foregroundColor(.blue)
                                    }
                                    .cornerRadius(4)
                                }
                                .frame(height: 8)
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                            }
                        }
                    } else {
                        Text("Flashlight not available on this device")
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                
                Spacer()
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                toggleCamera()
            }) {
                Image(systemName: isCameraActive ? "stop.circle" : "play.circle")
                    .imageScale(.large)
            })
            .onAppear {
                startCamera()
            }
            .onDisappear {
                stopCamera()
            }
        }
    }
    
    private func startCamera() {
        detector.startCapturing()
        isCameraActive = true
    }
    
    private func stopCamera() {
        detector.stopCapturing()
        isCameraActive = false
    }
    
    private func toggleCamera() {
        if isCameraActive {
            stopCamera()
        } else {
            startCamera()
        }
    }
}

// Camera Preview View using UIViewRepresentable
struct CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        view.backgroundColor = .black
        
        // Add camera preview layer if needed
        // This is a placeholder - in a full implementation,
        // you would add the actual AVCaptureVideoPreviewLayer here
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview if needed
    }
}

struct MorseCodeView_Previews: PreviewProvider {
    static var previews: some View {
        MorseCodeView()
    }
}
