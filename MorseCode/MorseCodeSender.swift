import AVFoundation
import Foundation

class MorseCodeSender: ObservableObject {
    private var morseSequence: [MorseSignal] = []
    private var isTransmitting = false
    private let torchQueue = DispatchQueue(label: "torchQueue")
    
    enum MorseSignal {
        case dot
        case dash
        case symbolSpace
        case letterSpace
        case wordSpace
    }
    
    @Published var transmissionProgress: Double = 0
    @Published var isAvailable: Bool = false
    
    init() {
        checkTorchAvailability()
    }
    
    private func checkTorchAvailability() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else {
            isAvailable = false
            return
        }
        isAvailable = true
    }
    
    func sendMessage(_ message: String) {
        guard isAvailable, !isTransmitting else { return }
        
        // Convert message to morse code
        let morseCode = MorseCode.textToMorse(message)
        
        // Convert morse code to signal sequence
        convertToSignalSequence(morseCode)
        
        // Start transmission
        isTransmitting = true
        transmissionProgress = 0
        
        // Execute the sequence
        executeSignalSequence()
    }
    
    func stopTransmission() {
        isTransmitting = false
        morseSequence = []
        transmissionProgress = 0
        torchQueue.async {
            self.setTorchMode(on: false)
        }
    }
    
    private func convertToSignalSequence(_ morseCode: String) {
        morseSequence = []
        
        var index = 0
        let components = morseCode.components(separatedBy: " ")
        
        for component in components {
            if component.isEmpty {
                continue
            } else if component == "/" {
                morseSequence.append(.wordSpace)
            } else {
                // Add each symbol in the morse code letter
                for symbol in component {
                    if symbol == "." {
                        morseSequence.append(.dot)
                    } else if symbol == "-" {
                        morseSequence.append(.dash)
                    }
                    
                    // Add symbol space if not the last symbol in the letter
                    if component.index(after: component.firstIndex(of: symbol)!) != component.endIndex {
                        morseSequence.append(.symbolSpace)
                    }
                }
                
                // Add letter space if not the last component
                if index < components.count - 1 {
                    morseSequence.append(.letterSpace)
                }
            }
            
            index += 1
        }
    }
    
    private func executeSignalSequence() {
        guard isTransmitting else { return }
        
        torchQueue.async {
            var index = 0
            let totalSignals = self.morseSequence.count
            
            for signal in self.morseSequence {
                // Check if transmission was cancelled
                guard self.isTransmitting else { return }
                
                self.executeSignal(signal)
                
                // Update progress
                index += 1
                DispatchQueue.main.async {
                    self.transmissionProgress = Double(index) / Double(totalSignals)
                }
            }
            
            // Completed transmission
            DispatchQueue.main.async {
                self.isTransmitting = false
                self.transmissionProgress = 1.0
            }
        }
    }
    
    private func executeSignal(_ signal: MorseSignal) {
        switch signal {
        case .dot:
            setTorchMode(on: true)
            Thread.sleep(forTimeInterval: MorseCode.dotDuration)
            setTorchMode(on: false)
            
        case .dash:
            setTorchMode(on: true)
            Thread.sleep(forTimeInterval: MorseCode.dashDuration)
            setTorchMode(on: false)
            
        case .symbolSpace:
            Thread.sleep(forTimeInterval: MorseCode.symbolSpaceDuration)
            
        case .letterSpace:
            Thread.sleep(forTimeInterval: MorseCode.letterSpaceDuration)
            
        case .wordSpace:
            Thread.sleep(forTimeInterval: MorseCode.wordSpaceDuration)
        }
    }
    
    private func setTorchMode(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            
            if on {
                try device.setTorchModeOn(level: 1.0)
            } else {
                device.torchMode = .off
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error setting torch mode: \(error.localizedDescription)")
        }
    }
}
//
//  MorseCodeSender.swift
//  MorseCode
//
//  Created by Solomiya Pylypiv on 3/23/25.
//

