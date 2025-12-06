import SwiftUI

// Enum to track which map is selected
enum MapType: String, Hashable {
    case original = "original"
    case mountain = "mountain"
    case sea = "sea"
    case hotdogLand = "hotdogLand"
}

struct MapSelectionView: View {
    @State private var selectedMap: MapType = .original
    @Binding var navigationPath: NavigationPath

    var body: some View {
        ZStack {
            // Background
            Image("background")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Spacer() // Push title down
                
                // Title
                Text("Select Map")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                
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
                    
                    // Sea Map Card
                    MapCard(
                        mapType: .sea, 
                        isSelected: selectedMap == .sea,
                        onTap: { selectedMap = .sea }
                    )
                    
                    // Hotdog Land Map Card
                    MapCard(
                        mapType: .hotdogLand, 
                        isSelected: selectedMap == .hotdogLand,
                        onTap: { selectedMap = .hotdogLand }
                    )
                }
                .padding(.horizontal)
                
                // Play Button
                Button(action: {
                    // Define the popToRoot action
                    let popToRootAction = {
                        navigationPath = NavigationPath() // Clear the path to pop to root
                    }
                    // Push GameView onto the path with the selected map and the pop action
                    navigationPath.append(GameViewData(mapType: selectedMap, popToRoot: popToRootAction))
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
                .padding(.bottom, 30)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(false)
        .safeAreaInset(edge: .top) { Color.clear.frame(height: 1) }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 40) }
        .navigationDestination(for: GameViewData.self) { gameData in
            GameView(mapType: gameData.mapType, popToRoot: gameData.popToRoot)
        }
    }
}

// Struct to hold data for GameView navigation
struct GameViewData: Hashable {
    let mapType: MapType
    let popToRoot: () -> Void

    // Implement Hashable
    static func == (lhs: GameViewData, rhs: GameViewData) -> Bool {
        lhs.mapType == rhs.mapType // Equality based on mapType for simplicity in navigation
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(mapType)
    }
}

// Card view for map selection
struct MapCard: View {
    let mapType: MapType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        let imageName: String
        let title: String
        
        switch mapType {
        case .original:
            imageName = "background"
            title = "Original"
        case .mountain:
            imageName = "background_mount"
            title = "Mountain"
        case .sea:
            imageName = "sea_background"
            title = "Sea"
        case .hotdogLand:
            imageName = "hotdog_background"
            title = "Hotdog Land"
        }
        
        return VStack {
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
        // Need to provide a dummy binding for the preview
        StatefulPreviewWrapper(NavigationPath()) { path in
            MapSelectionView(navigationPath: path)
        }
    }
}

// Helper for previewing views with @State bindings
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    var body: some View {
        content($value)
    }

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: value)
        self.content = content
    }
} 