//
//  ContentView.swift
//  MorseCode
//
//  Created by Joseph Brinker on 3/22/25.
//

import SwiftUI

struct ContentView: View {
    
    @State private var input: String = ""
    
    var body: some View {
        VStack {
            TextField("Enter Morse Code", text: $input)
            
            Text("Translated Morse: \(translateText(text: input))")
            
            
//            Text(translateCode(morseCode: ".... . .-.. .-.. --- / .-- --- .-. .-.. -.."))
//            Text(translateText(text: "Hello World"))
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
