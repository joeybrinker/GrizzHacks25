import SwiftUI

struct ContentView: View {
    @State private var showEncodeView = false
    @State private var showDecodeView = false
    @State private var showTwoWayView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Title
                    Text("Morse Code Helper")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 50)
                    
                    // Encode Button
                    NavigationLink(destination: EncodeView(), isActive: $showEncodeView) {
                        EmptyView()
                    }
                    
                    Button(action: {
                        showEncodeView = true
                    }) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .font(.title2)
                            Text("Encode")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .frame(width: 250, height: 60)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                    
                    // Decode Button
                    NavigationLink(destination: DecodeView(), isActive: $showDecodeView) {
                        EmptyView()
                    }
                    
                    Button(action: {
                        showDecodeView = true
                    }) {
                        HStack {
                            Image(systemName: "lock.open.fill")
                                .font(.title2)
                            Text("Decode")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .frame(width: 250, height: 60)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                    
                    //Two way communication system
                    // Decode Button
                    NavigationLink(destination: TwoWayView(), isActive: $showTwoWayView) {
                        EmptyView()
                    }
                    
                    Button(action: {
                        showTwoWayView = true
                    }) {
                        HStack {
                            Image(systemName: "message.fill")
                                .font(.title2)
                            Text("Two Way Chat")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .frame(width: 250, height: 60)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                    
                    
                }
                
            }
            .navigationBarHidden(true)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
