import SwiftUI

// Enum to track which map is selected
enum MapType: String {
    case original = "original"
    case mountain = "mountain"
}

struct MapSelectionView: View {
    @State private var navigateToGame = false
    @State private var selectedMap: MapType = .original
    
    var body: some View {
        ZStack {
            // Background
            Image("background")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Title
                Text("Select Map")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                    .padding(.top, 50)
                
                // Map selection cards
                HStack(spacing: 20) {
                    // Original Map Card
                    MapCard(
                        mapType: .original, 
                        isSelected: selectedMap == .original,
                        onTap: { selectedMap = .original }
                    )
                    
                    // Mountain Map Card
                    MapCard(
                        mapType: .mountain, 
                        isSelected: selectedMap == .mountain,
                        onTap: { selectedMap = .mountain }
                    )
                }
                .padding(.horizontal)
                
                // Play Button
                NavigationLink(destination: GameView(mapType: selectedMap), isActive: $navigateToGame) {
                    Button(action: {
                        navigateToGame = true
                    }) {
                        Text("Play")
                            .font(.headline)
                            .padding()
                            .frame(minWidth: 200)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.top, 30)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(false)
    }
}

// Card view for map selection
struct MapCard: View {
    let mapType: MapType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        let imageName = mapType == .original ? "background" : "background_mount"
        let title = mapType == .original ? "Original" : "Mountain"
        
        VStack {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 150, height: 150)
                .clipped()
                .cornerRadius(10)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1, x: 0, y: 0)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(isSelected ? Color.blue.opacity(0.6) : Color.gray.opacity(0.4))
                .shadow(color: isSelected ? .blue : .black.opacity(0.3), radius: isSelected ? 6 : 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
        .onTapGesture {
            onTap()
        }
    }
}

struct MapSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        MapSelectionView()
    }
} 