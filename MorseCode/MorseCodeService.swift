import Foundation
import AVFoundation
import SwiftUI

class MorseCodeService: ObservableObject {
    static let shared = MorseCodeService()
    
    // Published properties for UI updates
    @Published var isFlashing = false
    @Published var flashColor: Color = .white
    
    private var flashWorkItem: DispatchWorkItem?
    
     let morseDict: [Character: String] = [
        "a": ".-", "b": "-...", "c": "-.-.", "d": "-..", "e": ".", "f": "..-.",
        "g": "--.", "h": "....", "i": "..", "j": ".---", "k": "-.-", "l": ".-..",
        "m": "--", "n": "-.", "o": "---", "p": ".--.", "q": "--.-", "r": ".-.",
        "s": "...", "t": "-", "u": "..-", "v": "...-", "w": ".--", "x": "-..-",
        "y": "-.--", "z": "--..", "1": ".----", "2": "..---", "3": "...--",
        "4": "....-", "5": ".....", "6": "-....", "7": "--...", "8": "---..",
        "9": "----.", "0": "-----", " ": "/"
    ]
    
    let inverseMorseDict: [String: Character] = [
        ".-": "a", "-...": "b", "-.-.": "c", "-..": "d", ".": "e", "..-.": "f",
        "--.": "g", "....": "h", "..": "i", ".---": "j", "-.-": "k", ".-..": "l",
        "--": "m", "-.": "n", "---": "o", ".--.": "p", "--.-": "q", ".-.": "r",
        "...": "s", "-": "t", "..-": "u", "...-": "v", ".--": "w", "-..-": "x",
        "-.--": "y", "--..": "z", ".----": "1", "..---": "2", "...--": "3",
        "....-": "4", ".....": "5", "-....": "6", "--...": "7", "---..": "8",
        "----.": "9", "-----": "0", "/": " "
    ]
    
    // Constants for timing
    let dotDuration: TimeInterval = 0.2
    let dashDuration: TimeInterval = 0.6
    let symbolSpaceDuration: TimeInterval = 0.2
    let letterSpaceDuration: TimeInterval = 0.6
    let wordSpaceDuration: TimeInterval = 1.4
    
    // Convert text to Morse code
    func textToMorse(_ text: String) -> String {
        return text.lowercased().map { char in
            morseDict[char] ?? ""
        }.joined(separator: " ")
    }
    
    // Convert Morse code to text
    func morseToText(_ morse: String) -> String {
        let words = morse.components(separatedBy: " / ")
        let textWords = words.map { word -> String in
            let letters = word.components(separatedBy: " ")
            let textLetters = letters.map { inverseMorseDict[$0] ?? Character("?") }
            return String(textLetters)
        }
        return textWords.joined(separator: " ")
    }
    
    // Start flashing for the input text
    func startFlashing(for text: String) {
        stopFlashing() // Stop any existing flashing
        
        isFlashing = true
        let morseString = textToMorse(text)
        
        // Check if we should use device torch or screen flashing
        let hasTorch = AVCaptureDevice.default(for: .video)?.hasTorch ?? false
        print("Device has torch capability: \(hasTorch)")
        
        if hasTorch {
            print("Using device torch for Morse code transmission")
            transmitMorseCode(morseString) { [weak self] in
                DispatchQueue.main.async {
                    print("Torch transmission completed")
                    self?.isFlashing = false
                }
            }
        } else {
            print("No torch available, using screen flashing instead")
            flashWithScreen(morseString)
        }
    }
    
    // Stop flashing
    func stopFlashing() {
        isFlashing = false
        flashColor = .white
        
        // Cancel any pending flash operations
        flashWorkItem?.cancel()
        flashWorkItem = nil
        
        // Turn off the torch if it's on
        let device = AVCaptureDevice.default(for: .video)
        if let device = device, device.hasTorch && device.torchMode == .on {
            try? device.lockForConfiguration()
            device.torchMode = .off
            device.unlockForConfiguration()
        }
    }
    
    // Flash the screen based on Morse code
    private func flashWithScreen(_ morseString: String) {
        var totalDelay: TimeInterval = 0
        
        for (index, char) in morseString.enumerated() {
            switch char {
            case ".":
                let onItem = DispatchWorkItem { [weak self] in
                    self?.flashColor = .black
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay, execute: onItem)
                totalDelay += dotDuration
                
                let offItem = DispatchWorkItem { [weak self] in
                    self?.flashColor = .white
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay, execute: offItem)
                totalDelay += symbolSpaceDuration
                
            case "-":
                let onItem = DispatchWorkItem { [weak self] in
                    self?.flashColor = .black
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay, execute: onItem)
                totalDelay += dashDuration
                
                let offItem = DispatchWorkItem { [weak self] in
                    self?.flashColor = .white
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay, execute: offItem)
                totalDelay += symbolSpaceDuration
                
            case " ":
                // Space between letters (already have symbol space)
                totalDelay += letterSpaceDuration - symbolSpaceDuration
                
            case "/":
                // Space between words (already have symbol space)
                totalDelay += wordSpaceDuration - symbolSpaceDuration
                
            default:
                break
            }
            
            // If it's the last character, mark completion after appropriate delay
            if index == morseString.count - 1 {
                let completionItem = DispatchWorkItem { [weak self] in
                    self?.isFlashing = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay, execute: completionItem)
                flashWorkItem = completionItem
            }
        }
    }
    
    // Flash device torch based on Morse code
    func transmitMorseCode(_ morseString: String, completion: @escaping () -> Void) {
        let device = AVCaptureDevice.default(for: .video)
        
        guard let device = device, device.hasTorch else {
            print("Torch not available for transmission")
            completion()
            return
        }
        
        print("Starting torch-based Morse transmission for: \(morseString)")
        
        do {
            try device.lockForConfiguration()
            print("Successfully locked device for torch configuration")
            
            var totalDelay: TimeInterval = 0
            
            for (index, char) in morseString.enumerated() {
                switch char {
                case ".":
                    DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                        print("Turning torch ON for dot")
                        try? device.lockForConfiguration()
                        device.torchMode = .on
                        device.unlockForConfiguration()
                    }
                    totalDelay += dotDuration
                    DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                        print("Turning torch OFF after dot")
                        try? device.lockForConfiguration()
                        device.torchMode = .off
                        device.unlockForConfiguration()
                    }
                    totalDelay += symbolSpaceDuration
                    
                case "-":
                    DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                        print("Turning torch ON for dash")
                        try? device.lockForConfiguration()
                        device.torchMode = .on
                        device.unlockForConfiguration()
                    }
                    totalDelay += dashDuration
                    DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                        print("Turning torch OFF after dash")
                        try? device.lockForConfiguration()
                        device.torchMode = .off
                        device.unlockForConfiguration()
                    }
                    totalDelay += symbolSpaceDuration
                    
                case " ":
                    // Space between letters (already have symbol space)
                    totalDelay += letterSpaceDuration - symbolSpaceDuration
                    
                case "/":
                    // Space between words (already have symbol space)
                    totalDelay += wordSpaceDuration - symbolSpaceDuration
                    
                default:
                    break
                }
                
                // If it's the last character, call completion after appropriate delay
                if index == morseString.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                        completion()
                    }
                }
            }
            
            device.unlockForConfiguration()
            
        } catch {
            device.unlockForConfiguration()
            completion()
        }
    }
}
