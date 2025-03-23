import AVFoundation
import UIKit
import Combine

class MorseCodeDetector: NSObject, ObservableObject {
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let processingQueue = DispatchQueue(label: "processingQueue")
    
    // Morse code detection state
    @Published var detectedBrightness: Double = 0
    @Published var morseSignals: [String] = []
    @Published var currentMorseSignal: String = ""
    @Published var decodedMessage: String = ""
    
    // Timing variables
    private var lastBrightnessChangeTime: Date?
    private var isCurrentlyBright = false
    private var currentSignalDuration: TimeInterval = 0
    private var symbolBuffer: String = ""
    private var letterBuffer: String = ""
    
    // Time constants for signal detection
    private let dotThreshold: Double = MorseCode.dotDuration * 1.5
    private let dashThreshold: Double = MorseCode.dashDuration * 0.8
    private let letterSpaceThreshold: Double = MorseCode.letterSpaceDuration * 0.8
    private let wordSpaceThreshold: Double = MorseCode.wordSpaceDuration * 0.8
    
    override init() {
        super.init()
        setupCaptureSession()
    }
    
    func startCapturing() {
        sessionQueue.async {
            self.captureSession?.startRunning()
        }
    }
    
    func stopCapturing() {
        sessionQueue.async {
            self.captureSession?.stopRunning()
        }
    }
    
    private func setupCaptureSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .medium
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        self.captureSession = session
        self.videoOutput = videoOutput
    }
    
    private func calculateBrightness(from sampleBuffer: CMSampleBuffer) -> Double {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return 0 }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let extent = ciImage.extent
        let centerPoint = CGPoint(x: extent.width / 2, y: extent.height / 2)
        
        // Sample a small region around the center point
        let context = CIContext(options: nil)
        let sampleRect = CGRect(x: centerPoint.x - 20, y: centerPoint.y - 20, width: 40, height: 40)
        guard let outputImage = context.createCGImage(ciImage, from: sampleRect) else { return 0 }
        
        // Get the average brightness of the sampled region
        let dataProvider = outputImage.dataProvider
        guard let data = dataProvider?.data else { return 0 }
        let buffer = CFDataGetBytePtr(data)
        
        var totalBrightness: Double = 0
        let bytesPerPixel = 4
        let bytesPerRow = outputImage.bytesPerRow
        let width = sampleRect.width
        let height = sampleRect.height
        
        for y in 0..<Int(height) {
            for x in 0..<Int(width) {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let r = Double(buffer?[offset] ?? 0)
                let g = Double(buffer?[offset + 1] ?? 0)
                let b = Double(buffer?[offset + 2] ?? 0)
                
                // Simple RGB average for brightness
                totalBrightness += (r + g + b) / (3.0 * 255.0)
            }
        }
        
        return totalBrightness / (Double(width * height))
    }
    
    private func processBrightnessChange(newBrightValue: Bool, timestamp: Date) {
        // First brightness change
        guard let lastChangeTime = lastBrightnessChangeTime else {
            lastBrightnessChangeTime = timestamp
            isCurrentlyBright = newBrightValue
            return
        }
        
        // Calculate duration since last change
        let duration = timestamp.timeIntervalSince(lastChangeTime)
        
        // Process the signal based on previous state
        if isCurrentlyBright {
            // Previously bright (light was ON)
            if duration < dotThreshold {
                symbolBuffer += "."
            } else {
                symbolBuffer += "-"
            }
        } else {
            // Previously dark (light was OFF)
            // Check if this was a pause between letters or words
            if duration > wordSpaceThreshold {
                // Word space
                processLetter()
                letterBuffer += " / "
            } else if duration > letterSpaceThreshold {
                // Letter space
                processLetter()
            }
        }
        
        // Update state
        lastBrightnessChangeTime = timestamp
        isCurrentlyBright = newBrightValue
    }
    
    private func processLetter() {
        if !symbolBuffer.isEmpty {
            letterBuffer += symbolBuffer + " "
            symbolBuffer = ""
        }
        
        // If we have a full letter or word, update the UI
        DispatchQueue.main.async {
            self.currentMorseSignal = self.letterBuffer
            if !self.letterBuffer.isEmpty {
                self.decodedMessage = MorseCode.morseToText(self.letterBuffer)
            }
        }
    }
    
    // Reset detection state
    func resetDetection() {
        lastBrightnessChangeTime = nil
        isCurrentlyBright = false
        symbolBuffer = ""
        letterBuffer = ""
        
        DispatchQueue.main.async {
            self.currentMorseSignal = ""
            self.decodedMessage = ""
            self.morseSignals = []
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension MorseCodeDetector: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let brightness = calculateBrightness(from: sampleBuffer)
        let timestamp = Date()
        
        // Update UI with current brightness level
        DispatchQueue.main.async {
            self.detectedBrightness = brightness
        }
        
        // Detect light changes
        let isBright = brightness > MorseCode.brightnessThreshold
        
        if isBright != isCurrentlyBright {
            processBrightnessChange(newBrightValue: isBright, timestamp: timestamp)
        } else if !symbolBuffer.isEmpty && !isCurrentlyBright {
            // Check for timeout while collecting a letter
            let timeSinceLastChange = timestamp.timeIntervalSince(lastBrightnessChangeTime ?? timestamp)
            if timeSinceLastChange > letterSpaceThreshold {
                processLetter()
                lastBrightnessChangeTime = timestamp
            }
        }
    }
}
