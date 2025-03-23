//
//  TabView.swift
//  MorseCode
//
//  Created by Joseph Brinker on 3/23/25.
//

import SwiftUI

struct MorseView: View {
    
    @State private var selectedTabIndex = 0
    
    var body: some View {
        TabView(selection: $selectedTabIndex) {
            ContentView()
                .tabItem {
                    Label("Find Courses", systemImage: "map")
                }
                .tag(0)
        }
    }
}

#Preview {
    MorseView()
}
