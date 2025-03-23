//
//  MorseElement.swift
//  MorseCode
//
//  Created by Joseph Brinker on 3/22/25.
//

import SwiftUI
import AVFoundation

// Define the elements of Morse code
enum MorseElement: Equatable {
    case dot
    case dash
    case elementGap
    case letterGap
    case wordGap
    
    var duration: Double {
        switch self {
        case .dot: return 0.2
        case .dash: return 0.6
        case .elementGap: return 0.2
        case .letterGap: return 0.6
        case .wordGap: return 1.4
        }
    }
    
    var isLight: Bool {
        switch self {
        case .dot, .dash: return true
        default: return false
        }
    }
    
    var soundFileName: String? {
        switch self {
        case .dot: return "dot"
        case .dash: return "dash"
        default: return nil
        }
    }
}

class AudioPlayer {
    private var audioPlayer: AVAudioPlayer?
    
    func playSound(named fileName: String) {
        guard let soundURL = Bundle.main.url(forResource: fileName, withExtension: "wav") else {
            print("Sound file not found: \(fileName)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
    
    func stopSound() {
        audioPlayer?.stop()
    }
}

class MorseCodeEncoder: ObservableObject {
    // Published properties to be observed by views
    @Published var isFlashing: Bool = false
    @Published var flashColor: Color = .black
    @Published var isPlaying: Bool = false
    
    // Private properties
    private var morseSequence: [MorseElement] = []
    private var currentElementIndex: Int = 0
    private var timer: Timer?
    private let audioPlayer = AudioPlayer()
    
    // Start flashing the Morse code
    func startFlashing(for morseCode: String) {
        if morseCode.isEmpty { return }
        
        morseSequence = parseMorseString(morseCode)
        if morseSequence.isEmpty { return }
        
        isFlashing = true
        currentElementIndex = 0
        
        // Play the first element immediately
        playCurrentElement()
        
        // Schedule timer for the next element
        scheduleNextElement()
    }
    
    // Parse Morse code string to sequence of elements
    private func parseMorseString(_ morseString: String) -> [MorseElement] {
        var sequence: [MorseElement] = []
        let components = morseString.components(separatedBy: " ")
        
        for (index, component) in components.enumerated() {
            if component == "/" {
                sequence.append(.wordGap)
                continue
            }
            
            for (charIndex, char) in component.enumerated() {
                if char == "." {
                    sequence.append(.dot)
                } else if char == "-" {
                    sequence.append(.dash)
                }
                
                // Add element gap if not the last character in component
                if charIndex < component.count - 1 {
                    sequence.append(.elementGap)
                }
            }
            
            // Add letter gap if not the last component
            if index < components.count - 1 && components[index + 1] != "/" {
                sequence.append(.letterGap)
            }
        }
        
        return sequence
    }
    
    // Play the current Morse element
    private func playCurrentElement() {
        guard currentElementIndex < morseSequence.count else {
            stopFlashing()
            return
        }
        
        let element = morseSequence[currentElementIndex]
        
        if element.isLight {
            // Turn on the flashlight
            toggleFlash(on: true)
            
            // Play sound for the element
            if let soundFileName = element.soundFileName {
                audioPlayer.playSound(named: soundFileName)
            }
        } else {
            // Turn off the flashlight for gaps
            toggleFlash(on: false)
        }
    }
    
    // Schedule the next element
    private func scheduleNextElement() {
        guard currentElementIndex < morseSequence.count else {
            stopFlashing()
            return
        }
        
        let element = morseSequence[currentElementIndex]
        
        timer = Timer.scheduledTimer(withTimeInterval: element.duration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            self.currentElementIndex += 1
            
            if self.currentElementIndex < self.morseSequence.count {
                self.playCurrentElement()
                self.scheduleNextElement()
            } else {
                // Reset after completing the sequence
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.stopFlashing()
                }
            }
        }
    }
    
    // Stop flashing and reset
    func stopFlashing() {
        timer?.invalidate()
        timer = nil
        isFlashing = false
        toggleFlash(on: false)
        audioPlayer.stopSound()
        currentElementIndex = 0
    }
    
    // Toggle the device flashlight
    private func toggleFlash(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        if device.hasTorch && device.isTorchAvailable {
            do {
                try device.lockForConfiguration()
                if on == true {
                    try device.setTorchModeOn(level: 1.0)
                } else {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used: \(error.localizedDescription)")
            }
        }
    }
}
