//
//  MorseCode.swift
//  MorseCode
//
//  Created by Solomiya Pylypiv on 3/23/25.
//

import Foundation
import AVFoundation

struct MorseCode {
    // Morse code dictionary for encoding
    static let alphabetToMorse: [Character: String] = [
        "A": ".-", "B": "-...", "C": "-.-.", "D": "-..", "E": ".",
        "F": "..-.", "G": "--.", "H": "....", "I": "..", "J": ".---",
        "K": "-.-", "L": ".-..", "M": "--", "N": "-.", "O": "---",
        "P": ".--.", "Q": "--.-", "R": ".-.", "S": "...", "T": "-",
        "U": "..-", "V": "...-", "W": ".--", "X": "-..-", "Y": "-.--",
        "Z": "--..", "1": ".----", "2": "..---", "3": "...--", "4": "....-",
        "5": ".....", "6": "-....", "7": "--...", "8": "---..", "9": "----.",
        "0": "-----", " ": "/", ".": ".-.-.-", ",": "--..--", "?": "..--.."
    ]
    
    // Morse code dictionary for decoding
    static let morseToAlphabet: [String: Character] = {
        var result: [String: Character] = [:]
        for (key, value) in alphabetToMorse {
            result[value] = key
        }
        return result
    }()
    
    // Timing constants (in seconds)
    static let dotDuration: Double = 0.2
    static let dashDuration: Double = 0.6 // 3x dot duration
    static let symbolSpaceDuration: Double = 0.2 // same as dot duration
    static let letterSpaceDuration: Double = 0.6 // 3x dot duration
    static let wordSpaceDuration: Double = 1.4 // 7x dot duration
    
    // Threshold for light detection
    static let brightnessThreshold: Double = 0.5
    
    // Convert text to morse code
    static func textToMorse(_ text: String) -> String {
        let uppercaseText = text.uppercased()
        var morseCode = ""
        
        for character in uppercaseText {
            if let morse = alphabetToMorse[character] {
                morseCode += morse + " "
            }
        }
        
        return morseCode.trimmingCharacters(in: .whitespaces)
    }
    
    // Convert morse code to text
    static func morseToText(_ morse: String) -> String {
        // Preprocess morse code string to handle special characters
        var processedMorse = morse
            .replacingOccurrences(of: "…", with: "...")
            .replacingOccurrences(of: "—", with: "--")
            .replacingOccurrences(of: "–", with: "----")
        
        let morseWords = processedMorse.components(separatedBy: " / ")
        var result = ""
        
        for morseWord in morseWords {
            let morseLetters = morseWord.components(separatedBy: " ")
            for morseLetter in morseLetters {
                if !morseLetter.isEmpty, let character = morseToAlphabet[morseLetter] {
                    result.append(character)
                }
            }
            result.append(" ")
        }
        
        return result.trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Morse Audio Player
class MorseAudioPlayer {
    private var audioPlayer: AVAudioPlayer?
    private let dotSound: URL?
    private let dashSound: URL?
    
    init() {
        // Initialize sound file URLs
        dotSound = Bundle.main.url(forResource: "dot", withExtension: "wav")
        dashSound = Bundle.main.url(forResource: "dash", withExtension: "wav")
    }
    
    func playDot() {
        playSound(url: dotSound)
    }
    
    func playDash() {
        playSound(url: dashSound)
    }
    
    func stopSound() {
        audioPlayer?.stop()
    }
    
    private func playSound(url: URL?) {
        guard let soundURL = url else {
            print("Sound file not found")
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
}
