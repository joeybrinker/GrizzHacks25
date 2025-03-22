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
}

class MorseCodeEncoder: ObservableObject {
    // Published properties to be observed by views
    @Published var isFlashing: Bool = false
    @Published var flashColor: Color = .black
    
    // Private properties
    private var morseSequence: [MorseElement] = []
    private var currentElementIndex: Int = 0
    private var timer: Timer?
    
    // Morse code dictionary
    let morseCodeDict: [Character: String] = [
        "a": ".-", "b": "-...", "c": "-.-.", "d": "-..", "e": ".", "f": "..-.", "g": "--.",
        "h": "....", "i": "..", "j": ".---", "k": "-.-", "l": ".-..", "m": "--", "n": "-.",
        "o": "---", "p": ".--.", "q": "--.-", "r": ".-.", "s": "...", "t": "-", "u": "..-",
        "v": "...-", "w": ".--", "x": "-..-", "y": "-.--", "z": "--..",
        "1": ".----", "2": "..---", "3": "...--", "4": "....-", "5": ".....",
        "6": "-....", "7": "--...", "8": "---..", "9": "----.", "0": "-----",
        " ": "/", ".": ".-.-.-", ",": "--..--", "?": "..--..", "'": ".----.",
        "!": "-.-.--", "/": "-..-.", "(": "-.--.", ")": "-.--.-", "&": ".-...",
        ":": "---...", ";": "-.-.-.", "=": "-...-", "+": ".-.-.", "-": "-....-",
        "_": "..--.-", "\"": ".-..-.", "$": "...-..-", "@": ".--.-."
    ]
    
    // Convert text to Morse code string
    func textToMorse(_ text: String) -> String {
        let lowercasedText = text.lowercased()
        var morseString = ""
        
        for char in lowercasedText {
            if let morseChar = morseCodeDict[char] {
                morseString += morseChar + " "
            }
        }
        
        return morseString
    }
    
    // Convert text to sequence of Morse elements
    func textToMorseSequence(_ text: String) -> [MorseElement] {
        let lowercasedText = text.lowercased()
        var sequence: [MorseElement] = []
        
        for (index, char) in lowercasedText.enumerated() {
            if let morseChar = morseCodeDict[char] {
                for (charIndex, element) in morseChar.enumerated() {
                    // Add dot or dash
                    if element == "." {
                        sequence.append(.dot)
                    } else if element == "-" {
                        sequence.append(.dash)
                    } else if element == "/" {
                        // Word gap (space)
                        sequence.append(.wordGap)
                        continue
                    }
                    
                    // Add element gap if not the last element in the character
                    if charIndex < morseChar.count - 1 {
                        sequence.append(.elementGap)
                    }
                }
                
                // Add letter gap if not the last character
                if index < lowercasedText.count - 1 && lowercasedText[lowercasedText.index(after: lowercasedText.index(lowercasedText.startIndex, offsetBy: index))] != " " {
                    sequence.append(.letterGap)
                }
                
                // Add word gap if the character is a space
                if char == " " {
                    sequence.append(.wordGap)
                }
            }
        }
        
        return sequence
    }
    
    // Start flashing the Morse code
    func startFlashing(for text: String) {
        if text.isEmpty { return }
        
        morseSequence = textToMorseSequence(text)
        if morseSequence.isEmpty { return }
        
        isFlashing = true
        currentElementIndex = 0
        
        // Play the first element immediately
        playCurrentElement()
        
        // Schedule timer for the next element
        scheduleNextElement()
    }
    
    // Play the current Morse element
    private func playCurrentElement() {
        guard currentElementIndex < morseSequence.count else {
            stopFlashing()
            return
        }
        
        let element = morseSequence[currentElementIndex]
        
        if element.isLight {
            // Turn on the light
            flashColor = .white
            toggleFlash(on: true)
            
            
            // Optional: Also play a sound
            AudioServicesPlaySystemSound(1057) // iOS system sound
        } else {
            // Turn off the light for gaps
            flashColor = .black
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
        flashColor = .black
        currentElementIndex = 0
        
    }
    func toggleFlash(on: Bool) {
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
                print("Torch could not be used now!")
            }
        }
        
        
    }
}
