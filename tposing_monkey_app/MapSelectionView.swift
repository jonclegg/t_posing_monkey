import SwiftUI

// Enum to track which map is selected
enum MapType: String, Hashable {
    case original = "original"
    case mountain = "mountain"
    case sea = "sea"
    case hotdogLand = "hotdogLand"
}

// Enum for unlockable pets
enum PetType: String, Hashable, CaseIterable {
    case none = "none"
    case ellie = "ellie"
    case loaf = "loaf"
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .ellie: return "Ellie"
        case .loaf: return "Loaf"
        }
    }
    
    var imageName: String? {
        switch self {
        case .none: return nil
        case .ellie: return "ellie"
        case .loaf: return "loaf"
        }
    }
}

struct MapSelectionView: View {
    @State private var selectedMap: MapType = .original
    @State private var selectedPet: PetType = .none
    @State private var showCodeInput = false
    @State private var codeInput = ""
    @State private var codeError = ""
    @State private var starScale: CGFloat = 1.0
    @Binding var navigationPath: NavigationPath
    
    @State private var showMultiplayerModal = false
    @State private var multiplayerMode: MultiplayerMode = .none
    @State private var roomCode = ""
    @State private var joinRoomCode = ""
    @State private var multiplayerError = ""
    @State private var isWaitingForPlayer = false
    @State private var isJoining = false
    @State private var playerId = ""
    @State private var pollingTimer: Timer? = nil
    
    enum MultiplayerMode {
        case none
        case creating
        case joining
        case waiting
    }
    
    private var unlockedPets: [PetType] {
        var pets: [PetType] = [.none]
        if UserDefaults.standard.bool(forKey: "pet_ellie_unlocked") {
            pets.append(.ellie)
        }
        if UserDefaults.standard.bool(forKey: "pet_loaf_unlocked") {
            pets.append(.loaf)
        }
        return pets
    }

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
                
                // Pet selection (only show if any pets are unlocked)
                if unlockedPets.count > 1 {
                    VStack(spacing: 10) {
                        Text("Select Pet")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 1, x: 0, y: 0)
                        
                        HStack(spacing: 15) {
                            ForEach(unlockedPets, id: \.self) { pet in
                                PetCard(
                                    petType: pet,
                                    isSelected: selectedPet == pet,
                                    onTap: { selectedPet = pet }
                                )
                            }
                        }
                    }
                    .padding(.top, 10)
                }
                
                HStack(spacing: 20) {
                    Button(action: {
                        let popToRootAction = {
                            navigationPath = NavigationPath()
                        }
                        navigationPath.append(GameViewData(mapType: selectedMap, petType: selectedPet, popToRoot: popToRootAction))
                    }) {
                        Text("Play Solo")
                            .font(.headline)
                            .padding()
                            .frame(minWidth: 140)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
                    }
                    
                    Button(action: {
                        showMultiplayerModal = true
                        multiplayerMode = .none
                        multiplayerError = ""
                        roomCode = ""
                        joinRoomCode = ""
                    }) {
                        Text("Multiplayer")
                            .font(.headline)
                            .padding()
                            .frame(minWidth: 140)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.bottom, 30)
                
                Spacer()
            }
            
            // Hidden star button in bottom-right corner
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showCodeInput = true
                        codeInput = ""
                        codeError = ""
                    }) {
                        Text("⭐")
                            .font(.system(size: 28))
                            .shadow(color: .black, radius: 0, x: 1, y: 1)
                            .shadow(color: .black, radius: 0, x: -1, y: -1)
                            .shadow(color: .black, radius: 0, x: 1, y: -1)
                            .shadow(color: .black, radius: 0, x: -1, y: 1)
                            .opacity(0.5)
                            .scaleEffect(starScale)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 60)
                }
            }
            .onAppear {
                withAnimation(
                    Animation
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                ) {
                    starScale = 1.4
                }
            }
            
            // Code input overlay
            if showCodeInput {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showCodeInput = false
                    }
                
                VStack(spacing: 20) {
                    Text("Enter Secret Code")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("Code", text: $codeInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 200)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                    
                    if !codeError.isEmpty {
                        Text(codeError)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    HStack(spacing: 20) {
                        Button("Cancel") {
                            showCodeInput = false
                        }
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        Button("Submit") {
                            checkCode()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(30)
                .frame(maxWidth: 320)
                .background(Color.black.opacity(0.8))
                .cornerRadius(15)
            }
            
            // Multiplayer modal
            if showMultiplayerModal {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        if multiplayerMode == .none {
                            showMultiplayerModal = false
                        }
                    }
                
                multiplayerModalContent
            }
        }
        .onDisappear {
            pollingTimer?.invalidate()
            pollingTimer = nil
        }
        .navigationBarBackButtonHidden(false)
        .safeAreaInset(edge: .top) { Color.clear.frame(height: 1) }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 40) }
        .navigationDestination(for: GameViewData.self) { gameData in
            GameView(mapType: gameData.mapType, petType: gameData.petType, popToRoot: gameData.popToRoot)
        }
        .navigationDestination(for: MultiplayerGameViewData.self) { gameData in
            MultiplayerGameView(
                mapType: gameData.mapType,
                petType: gameData.petType,
                roomCode: gameData.roomCode,
                playerId: gameData.playerId,
                isHost: gameData.isHost,
                popToRoot: gameData.popToRoot
            )
        }
    }
    
    @ViewBuilder
    private var multiplayerModalContent: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Multiplayer")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                if multiplayerMode == .none {
                    Button(action: { showMultiplayerModal = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }
                }
            }
            
            if !multiplayerError.isEmpty {
                Text(multiplayerError)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            switch multiplayerMode {
            case .none:
                Button(action: { createRoom() }) {
                    Text("Create Room")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: { multiplayerMode = .joining }) {
                    Text("Join Room")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
            case .creating:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                Text("Creating room...")
                    .foregroundColor(.white)
                
            case .waiting:
                Text("Room Code:")
                    .foregroundColor(.gray)
                
                Text(roomCode)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.yellow)
                
                Text("Share this code with your friend!")
                    .foregroundColor(.white)
                    .font(.subheadline)
                
                Text("Waiting for player to join...")
                    .foregroundColor(.gray)
                    .font(.caption)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Button(action: { cancelRoom() }) {
                    Text("Cancel")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
            case .joining:
                Text("Enter Room Code:")
                    .foregroundColor(.white)
                
                TextField("ABCD", text: $joinRoomCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 150)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .onChange(of: joinRoomCode) { newValue in
                        if newValue.count > 4 {
                            joinRoomCode = String(newValue.prefix(4))
                        }
                        joinRoomCode = joinRoomCode.uppercased()
                    }
                
                HStack(spacing: 20) {
                    Button(action: { multiplayerMode = .none }) {
                        Text("Back")
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: { joinRoom() }) {
                        if isJoining {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding()
                        } else {
                            Text("Join")
                                .padding()
                        }
                    }
                    .background(joinRoomCode.count == 4 ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(joinRoomCode.count != 4 || isJoining)
                }
            }
        }
        .padding(30)
        .frame(maxWidth: 320)
        .background(Color.black.opacity(0.9))
        .cornerRadius(20)
    }

    private func createRoom() {
        multiplayerMode = .creating
        multiplayerError = ""
        
        MultiplayerManager.shared.createRoom(playerName: "P1", mapType: selectedMap.rawValue) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    roomCode = response.roomCode
                    playerId = response.playerId
                    multiplayerMode = .waiting
                    startPollingForPlayer()
                case .failure(let error):
                    multiplayerError = error.localizedDescription
                    multiplayerMode = .none
                }
            }
        }
    }

    private func startPollingForPlayer() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            MultiplayerManager.shared.getRoomState(roomCode: roomCode) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let state):
                        if state.player2 != nil {
                            pollingTimer?.invalidate()
                            pollingTimer = nil
                            startMultiplayerGame(isHost: true)
                        }
                    case .failure:
                        break
                    }
                }
            }
        }
    }

    private func joinRoom() {
        isJoining = true
        multiplayerError = ""
        
        MultiplayerManager.shared.joinRoom(roomCode: joinRoomCode, playerName: "P2") { result in
            DispatchQueue.main.async {
                isJoining = false
                switch result {
                case .success(let response):
                    roomCode = response.roomCode
                    playerId = response.playerId
                    if let mapTypeStr = response.mapType, let mapType = MapType(rawValue: mapTypeStr) {
                        selectedMap = mapType
                    }
                    startMultiplayerGame(isHost: false)
                case .failure(let error):
                    multiplayerError = error.localizedDescription
                }
            }
        }
    }

    private func cancelRoom() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        MultiplayerManager.shared.deleteRoom(roomCode: roomCode) { _ in }
        multiplayerMode = .none
        roomCode = ""
    }

    private func startMultiplayerGame(isHost: Bool) {
        showMultiplayerModal = false
        let popToRootAction = {
            navigationPath = NavigationPath()
        }
        navigationPath.append(MultiplayerGameViewData(
            mapType: selectedMap,
            petType: selectedPet,
            roomCode: roomCode,
            playerId: playerId,
            isHost: isHost,
            popToRoot: popToRootAction
        ))
    }

    private func checkCode() {
        let code = codeInput.uppercased()
        
        if code == "HAVANESE121" {
            UserDefaults.standard.set(true, forKey: "pet_ellie_unlocked")
            selectedPet = .ellie
            showCodeInput = false
            codeError = ""
            return
        }
        
        if code == "KITTY89" {
            UserDefaults.standard.set(true, forKey: "pet_loaf_unlocked")
            selectedPet = .loaf
            showCodeInput = false
            codeError = ""
            return
        }
        
        codeError = "Invalid code"
    }
}

// Pet card for pet selection
struct PetCard: View {
    let petType: PetType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack {
            if let imageName = petType.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            } else {
                Image(systemName: "xmark.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
            }
            
            Text(petType.displayName)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.blue.opacity(0.6) : Color.gray.opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
        .onTapGesture {
            onTap()
        }
    }
}

struct GameViewData: Hashable {
    let mapType: MapType
    let petType: PetType
    let popToRoot: () -> Void

    static func == (lhs: GameViewData, rhs: GameViewData) -> Bool {
        lhs.mapType == rhs.mapType && lhs.petType == rhs.petType
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(mapType)
        hasher.combine(petType)
    }
}



struct MultiplayerGameViewData: Hashable {
    let mapType: MapType
    let petType: PetType
    let roomCode: String
    let playerId: String
    let isHost: Bool
    let popToRoot: () -> Void

    static func == (lhs: MultiplayerGameViewData, rhs: MultiplayerGameViewData) -> Bool {
        lhs.roomCode == rhs.roomCode && lhs.playerId == rhs.playerId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(roomCode)
        hasher.combine(playerId)
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
        StatefulPreviewWrapper(NavigationPath()) { path in
            MapSelectionView(navigationPath: path)
        }
    }
}

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
