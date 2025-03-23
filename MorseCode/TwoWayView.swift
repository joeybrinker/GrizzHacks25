import SwiftUI
import AVFoundation

struct TwoWayView: View {
    @State private var inputMessage = ""
    @State private var messages: [(text: String, isSent: Bool)] = []
    @State private var isTransmitting = false
    @StateObject private var flashDetectionService = FlashDetectionService()
    
    // Camera preview
    @State private var previewLayer: AVCaptureVideoPreviewLayer?
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(0..<messages.count, id: \.self) { index in
                                MessageBubble(message: messages[index].text,
                                            isSent: messages[index].isSent)
                                .id(index)
                            }
                        }
                        .padding()
                        .rotationEffect(.degrees(180))
                    }
                    .rotationEffect(.degrees(180))
                    .onChange(of: messages.count) { _ in
                        if !messages.isEmpty {
                            proxy.scrollTo(messages.count - 1, anchor: .bottom)
                        }
                    }
                }
                
                // Camera preview area when listening
                if flashDetectionService.isRunning {
                    ZStack {
                        CameraPreviewView(previewLayer: $previewLayer)
                            .frame(height: 120)
                            .cornerRadius(10)
                        
                        VStack {
                            Text("Detecting flashes...")
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(4)
                            
                            Text("Signal: \(flashDetectionService.detectedMorseSignal)")
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Input area
                HStack {
                    TextField("Type a message", text: $inputMessage)
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .disabled(isTransmitting)
                    
                    Button(action: {
                        if !inputMessage.isEmpty {
                            sendMessage()
                        }
                    }) {
                        Image(systemName: isTransmitting ? "hourglass" : "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundColor(isTransmitting ? .gray : .blue)
                    }
                    .disabled(inputMessage.isEmpty || isTransmitting)
                    
                    Button(action: {
                        toggleCameraListening()
                    }) {
                        Image(systemName: flashDetectionService.isRunning ? "camera.fill" : "camera")
                            .font(.title)
                            .foregroundColor(flashDetectionService.isRunning ? .green : .gray)
                    }
                }
                .padding()
            }
            .navigationTitle("Two-Way Communication")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                setupFlashDetection()
                requestCameraPermission()
            }
            .onDisappear {
                flashDetectionService.stop()
            }
        }
    }
    
    private func setupFlashDetection() {
        flashDetectionService.onMessageReceived = { message in
            DispatchQueue.main.async {
                self.messages.append((message, false))
            }
        }
    }
    
    private func toggleCameraListening() {
        if flashDetectionService.isRunning {
            flashDetectionService.stop()
        } else {
            requestCameraPermission()
        }
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.setupCameraPreview()
                    self.flashDetectionService.start()
                }
            }
        }
    }
    
    private func setupCameraPreview() {
        guard previewLayer == nil else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let captureSession = AVCaptureSession()
            captureSession.sessionPreset = .medium
            
            guard let camera = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                return
            }
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            captureSession.startRunning()
            
            DispatchQueue.main.async {
                let layer = AVCaptureVideoPreviewLayer(session: captureSession)
                layer.videoGravity = .resizeAspectFill
                self.previewLayer = layer
            }
        }
    }
    
    private func sendMessage() {
        let messageText = inputMessage
        messages.append((messageText, true))
        
        isTransmitting = true
        let morseText = MorseCodeService.shared.textToMorse(messageText)
        
        // Display sending status
        inputMessage = ""
        
        // Transmit the message
        MorseCodeService.shared.transmitMorseCode(morseText) {
            DispatchQueue.main.async {
                self.isTransmitting = false
            }
        }
    }
}

// Camera preview view
struct CameraPreviewView: UIViewRepresentable {
    @Binding var previewLayer: AVCaptureVideoPreviewLayer?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = previewLayer {
            layer.frame = uiView.bounds
            
            // Only add the layer if it's not already added
            if layer.superlayer == nil {
                uiView.layer.addSublayer(layer)
            }
        }
    }
}

// Message bubble component for the chat interface
struct MessageBubble: View {
    let message: String
    let isSent: Bool
    
    var body: some View {
        HStack {
            if isSent {
                Spacer()
            }
            
            Text(message)
                .padding(10)
                .background(isSent ? Color.blue : Color(UIColor.secondarySystemBackground))
                .foregroundColor(isSent ? .white : .primary)
                .cornerRadius(10)
            
            if !isSent {
                Spacer()
            }
        }
    }
}

struct TwoWayView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TwoWayView()
        }
    }
}
