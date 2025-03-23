import Foundation
import AVFoundation
import UIKit
import Combine

class FlashDetectionService: NSObject, ObservableObject {
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let morseService = MorseCodeService.shared
    
    @Published var isRunning = false
    @Published var detectedBrightness: CGFloat = 0
    @Published var detectedMorseSignal = ""
    @Published var receivedMessage = ""
    
    var onMessageReceived: ((String) -> Void)?
    
    private var brightnessSamples: [CGFloat] = []
    private var lastSignalTime: Date?
    private var currentMorseCharacter = ""
    private var currentWord = ""
    
    private let brightnessThreshold: CGFloat = 0.7
    private let brightnessCheckInterval: TimeInterval = 0.05
    private let characterEndInterval: TimeInterval = 1.0
    private let wordEndInterval: TimeInterval = 2.0
    
    private var timer: Timer?
    
    override init() {
        super.init()
        setupCaptureSession()
    }
    
    func start() {
        guard let captureSession = captureSession, !captureSession.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
            DispatchQueue.main.async {
                self?.isRunning = true
                self?.startBrightnessTimer()
            }
        }
    }
    
    func stop() {
        guard let captureSession = captureSession, captureSession.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
            DispatchQueue.main.async {
                self?.isRunning = false
                self?.timer?.invalidate()
                self?.timer = nil
            }
        }
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .medium
        
        guard let captureSession = captureSession,
              let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        if let videoOutput = videoOutput, captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
    }
    
    private func startBrightnessTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: brightnessCheckInterval, repeats: true) { [weak self] _ in
            self?.processBrightnessSamples()
        }
    }
    
    private func processBrightnessSamples() {
        guard !brightnessSamples.isEmpty else { return }
        
        // Average brightness from samples
        let averageBrightness = brightnessSamples.reduce(0, +) / CGFloat(brightnessSamples.count)
        brightnessSamples.removeAll()
        detectedBrightness = averageBrightness
        
        // Detect signal (dot or dash)
        let now = Date()
        let isSignalOn = averageBrightness > brightnessThreshold
        
        if isSignalOn {
            if lastSignalTime == nil {
                lastSignalTime = now
            } else {
                let duration = now.timeIntervalSince(lastSignalTime!)
                if duration > morseService.dashDuration / 2 {
                    // Dash
                    if !currentMorseCharacter.hasSuffix("-") {
                        currentMorseCharacter += "-"
                    }
                } else {
                    // Dot
                    if !currentMorseCharacter.hasSuffix(".") {
                        currentMorseCharacter += "."
                    }
                }
            }
        } else {
            // Signal off
            if let lastTime = lastSignalTime {
                let offDuration = now.timeIntervalSince(lastTime)
                
                if offDuration > morseService.wordSpaceDuration {
                    // End of word
                    if !currentMorseCharacter.isEmpty {
                        if let character = morseService.inverseMorseDict[currentMorseCharacter] {
                            currentWord += String(character)
                        }
                        currentMorseCharacter = ""
                    }
                    
                    if !currentWord.isEmpty {
                        let message = currentWord
                        receivedMessage = message
                        onMessageReceived?(message)
                        currentWord = ""
                    }
                } else if offDuration > morseService.letterSpaceDuration {
                    // End of character
                    if !currentMorseCharacter.isEmpty {
                        if let character = morseService.inverseMorseDict[currentMorseCharacter] {
                            currentWord += String(character)
                        }
                        currentMorseCharacter = ""
                    }
                }
            }
            lastSignalTime = nil
        }
        
        detectedMorseSignal = currentMorseCharacter
    }
}

extension FlashDetectionService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let cameraImage = CIImage(cvPixelBuffer: pixelBuffer)
        let brightness = calculateBrightness(from: cameraImage)
        
        DispatchQueue.main.async { [weak self] in
            self?.brightnessSamples.append(brightness)
        }
    }
    
    private func calculateBrightness(from image: CIImage) -> CGFloat {
        let extent = image.extent
        let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
        let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: image, kCIInputExtentKey: inputExtent])!
        let outputImage = filter.outputImage!
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        // Calculate brightness: (0.299*R + 0.587*G + 0.114*B)
        let brightness = (0.299 * CGFloat(bitmap[0]) + 0.587 * CGFloat(bitmap[1]) + 0.114 * CGFloat(bitmap[2])) / 255.0
        return brightness
    }
}
