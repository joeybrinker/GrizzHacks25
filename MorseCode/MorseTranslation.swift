//
//  MorseTranslation.swift
//  MorseCode
//
//  Created by Joseph Brinker on 3/22/25.
//

import Foundation

let morseCodeDictionary: [Character: String] = [
    // Letters
    "A": ".-",
    "B": "-...",
    "C": "-.-.",
    "D": "-..",
    "E": ".",
    "F": "..-.",
    "G": "--.",
    "H": "....",
    "I": "..",
    "J": ".---",
    "K": "-.-",
    "L": ".-..",
    "M": "--",
    "N": "-.",
    "O": "---",
    "P": ".--.",
    "Q": "--.-",
    "R": ".-.",
    "S": "...",
    "T": "-",
    "U": "..-",
    "V": "...-",
    "W": ".--",
    "X": "-..-",
    "Y": "-.--",
    "Z": "--..",
    
    // Numbers
    "0": "-----",
    "1": ".----",
    "2": "..---",
    "3": "...--",
    "4": "....-",
    "5": ".....",
    "6": "-....",
    "7": "--...",
    "8": "---..",
    "9": "----."
    ]

// Create the reverse dictionary for more efficient lookups
let codeToMorseDict: [String: Character] = {
    var result: [String: Character] = [:]
    for (char, morse) in morseCodeDictionary {
        result[morse] = char
    }
    return result
}()

func translateCode(morseCode: String) -> String {
    // Replace ellipsis with three dots
    var processedMorseCode = morseCode.replacingOccurrences(of: "…", with: "...")
    
    // Handle en dash DO NOT TOUCH THE HYPHEN IN of: THIS HYPHEN IS FOR A COMBINATION OF 2
    processedMorseCode = processedMorseCode.replacingOccurrences(of: "—", with: "--")
    
    // Handle em dash DO NOT TOUCH THE HYPHEN IN of: THIS HYPHEN IS FOR A COMBINATION OF 4
    processedMorseCode = processedMorseCode.replacingOccurrences(of: "–", with: "----")
    
    
    // Split the input by spaces
    let morseCharacters = processedMorseCode.split(separator: " ")
    var translatedText = ""
    
    for morseCharacter in morseCharacters {
        if morseCharacter == "/" {
            translatedText.append(" ")
        } else if let character = codeToMorseDict[String(morseCharacter)] {
            translatedText.append(character)
        }
    }
    
    return translatedText
}

func translateText(text: String) -> String {
    var translatedMorse: [String] = []

    for letter in text.uppercased() {
        if letter == " " {
            translatedMorse.append("/")
        }
        for (character, code) in morseCodeDictionary{
            if character == letter {
                translatedMorse.append(code)
            }
        }
    }
    
    return translatedMorse.joined(separator: " ")
}
