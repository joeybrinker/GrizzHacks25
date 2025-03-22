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

func translateCode(morseCode: String) -> String {
    var translatedText: [Character] = []
    
    for morseCharacter in morseCode.split(separator: " ") {
        if morseCharacter == "/" {
            translatedText.append(" ")
        }
        for (character, code) in morseCodeDictionary {
            if code == String(morseCharacter) {
                translatedText.append(character)
            }
        }
    }
    
    return String(translatedText)
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
