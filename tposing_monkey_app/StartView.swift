import SwiftUI
import AVFoundation

struct StartView: View {
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    Image("background")
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                    
                    // Title at the top
                    VStack {
                        Text("T Posing Monkey")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2, x: 1, y: 1)
                            .padding(.top, 25)
                            .padding(.horizontal, 10)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        Spacer()
                    }
                    
                    // Monkey image
                    VStack {
                        Image("monkey")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                        Spacer().frame(height: geometry.size.height * 0.5)
                    }
                    
                    // Start Game Button - positioned lower
                    VStack {
                        Button(action: {
                            navigationPath.append(MapType.original)
                        }) {
                            Text("Start Game")
                                .font(.headline)
                                .padding()
                                .frame(minWidth: 200)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
                        }
                    }
                }
            }
            .navigationDestination(for: MapType.self) { _ in
                MapSelectionView(navigationPath: $navigationPath)
            }
        }
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
    }
} 