import SwiftUI

struct MultiplayerGameView: View {
    let mapType: MapType
    let petType: PetType
    let roomCode: String
    let playerId: String
    let isHost: Bool
    let popToRoot: () -> Void
    
    @State private var playerPosition = CGPoint(x: UIScreen.main.bounds.width * 0.75, y: UIScreen.main.bounds.height * 0.5)
    @State private var monkeyPosition = CGPoint(x: UIScreen.main.bounds.width * 0.25, y: UIScreen.main.bounds.height * 0.5)
    @State private var petPosition = CGPoint(x: UIScreen.main.bounds.width * 0.75 + 40, y: UIScreen.main.bounds.height * 0.5 + 40)
    @State private var score = 0
    @State private var isGameOver = false
    @State private var gameTimer: Timer? = nil
    @State private var networkTimer: Timer? = nil
    @State private var gameStartTime = Date()
    
    @State private var isLarryVisible = false
    @State private var isMonkeyFrozen = false
    @State private var larryPosition = CGPoint(x: 0, y: 0)
    @State private var larryTimer: Timer? = nil
    @State private var larryMovementTimer: Timer? = nil
    
    @State private var isWaitingToStart = true
    @State private var otherPlayerConnected = false
    @State private var isMonkeyPlayer = false
    
    @State private var targetPlayerPosition = CGPoint(x: UIScreen.main.bounds.width * 0.75, y: UIScreen.main.bounds.height * 0.5)
    @State private var targetMonkeyPosition = CGPoint(x: UIScreen.main.bounds.width * 0.25, y: UIScreen.main.bounds.height * 0.5)
    
    private let larryAppearInterval: TimeInterval = 10.0
    private let larryFreezeTime: TimeInterval = 3.0
    private let petFollowSpeed: CGFloat = 0.08
    private let networkUpdateInterval: TimeInterval = 0.05
    private let remotePlayerLerpSpeed: CGFloat = 0.25

    private var screenWidth: CGFloat { UIScreen.main.bounds.width }
    private var screenHeight: CGFloat { UIScreen.main.bounds.height }

    private func normalizePosition(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: point.x / screenWidth, y: point.y / screenHeight)
    }

    private func denormalizePosition(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: point.x * screenWidth, y: point.y * screenHeight)
    }

    private var screenScale: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let referenceWidth: CGFloat = 1024
        let referenceHeight: CGFloat = 768
        let widthScale = screenWidth / referenceWidth
        let heightScale = screenHeight / referenceHeight
        return min(widthScale, heightScale)
    }

    private var playerSize: CGFloat { 90 * screenScale }
    private var monkeySize: CGFloat { 90 * screenScale }
    private var larrySize: CGFloat { 120 * screenScale }
    private var petSize: CGFloat { 40 * screenScale }

    private var actualPlayerSize: CGFloat {
        switch mapType {
        case .mountain:
            return playerSize * 2
        case .original, .sea, .hotdogLand:
            return playerSize
        }
    }

    private var actualMonkeySize: CGFloat {
        switch mapType {
        case .mountain:
            return monkeySize * 2
        case .original, .sea, .hotdogLand:
            return monkeySize
        }
    }

    private var backgroundImage: String {
        switch mapType {
        case .original: return "background"
        case .mountain: return "background_mount"
        case .sea: return "sea_background"
        case .hotdogLand: return "hotdog_background"
        }
    }

    private var playerImage: String {
        switch mapType {
        case .original: return "player"
        case .mountain: return "player_mount"
        case .sea: return "sea_player"
        case .hotdogLand: return "hotdog_player"
        }
    }

    private var monkeyImage: String {
        switch mapType {
        case .original: return "monkey"
        case .mountain: return "monkey_mount"
        case .sea: return "sea_monkey"
        case .hotdogLand: return "hotdog_monkey"
        }
    }

    private var larryImage: String {
        switch mapType {
        case .original: return "larry"
        case .mountain, .sea: return "larry_mount"
        case .hotdogLand: return "hotdog_larry"
        }
    }

    private var larryName: String {
        switch mapType {
        case .hotdogLand: return "MARCUS"
        case .original, .mountain, .sea: return "LARRY"
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                Image(backgroundImage)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            
                if isWaitingToStart {
                    waitingOverlay
                } else if isGameOver {
                    gameOverOverlay
                } else {
                    gameContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isGameOver && !isWaitingToStart {
                            if isMonkeyPlayer {
                                if !isMonkeyFrozen {
                                    monkeyPosition = value.location
                                }
                            } else {
                                playerPosition = value.location
                            }
                        }
                    }
            )
        }
        .onAppear {
            startPollingForGameStart()
        }
        .onDisappear {
            cleanupTimers()
        }
    }

    @ViewBuilder
    private var waitingOverlay: some View {
        VStack(spacing: 20) {
            Text("Room: \(roomCode)")
                .font(.title)
                .foregroundColor(.white)
            
            if isHost {
                if otherPlayerConnected {
                    Text("Player 2 joined!")
                        .foregroundColor(.green)
                    
                    Button("Start Game") {
                        MultiplayerManager.shared.startGame(roomCode: roomCode) { result in
                            DispatchQueue.main.async {
                                if case .success(let response) = result {
                                    isMonkeyPlayer = response.monkeyPlayerId == playerId
                                }
                                isWaitingToStart = false
                                startGame()
                            }
                        }
                    }
                    .font(.headline)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                } else {
                    Text("Waiting for player 2...")
                        .foregroundColor(.gray)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            } else {
                Text("Waiting for host to start...")
                    .foregroundColor(.gray)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
            
            Button("Cancel") {
                MultiplayerManager.shared.deleteRoom(roomCode: roomCode) { _ in }
                popToRoot()
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 24)
        .frame(maxWidth: 320)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var gameOverOverlay: some View {
        VStack(spacing: 20) {
            Text("GAME OVER")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            Text("Score: \(score)")
                .font(.title)
                .foregroundColor(.white)
            
            if isHost {
                Button("Play Again") {
                    restartGame()
                }
                .font(.headline)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                Text("Waiting for host...")
                    .foregroundColor(.gray)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
            
            Button("Back to Menu") {
                MultiplayerManager.shared.deleteRoom(roomCode: roomCode) { _ in }
                popToRoot()
            }
            .font(.headline)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 24)
        .frame(maxWidth: 320)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if !isHost {
                startPollingForRestart()
            }
        }
    }

    @ViewBuilder
    private var gameContent: some View {
        Image(playerImage)
            .resizable()
            .scaledToFit()
            .frame(height: actualPlayerSize)
            .position(playerPosition)
        
        if !isMonkeyPlayer, let petImage = petType.imageName {
            Image(petImage)
                .resizable()
                .scaledToFit()
                .frame(height: petSize)
                .position(petPosition)
        }
        
        Image(monkeyImage)
            .resizable()
            .scaledToFit()
            .frame(height: actualMonkeySize)
            .position(monkeyPosition)
            .colorMultiply(isMonkeyFrozen ? .blue : .white)
        
        if isLarryVisible {
            Image(larryImage)
                .resizable()
                .scaledToFit()
                .frame(height: larrySize)
                .position(larryPosition)
                .overlay(
                    Text(larryName)
                        .foregroundColor(.red)
                        .font(.headline)
                )
        }
        
        VStack {
            HStack {
                Text("Room: \(roomCode)")
                    .font(.caption)
                    .padding(8)
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                
                Text(isMonkeyPlayer ? "You are: MONKEY" : "You are: PLAYER")
                    .font(.caption)
                    .padding(8)
                    .foregroundColor(isMonkeyPlayer ? .orange : .green)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                
                Spacer()
                
                Text("Score: \(score)")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
            }
            .padding(.top, 50)
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }

    private func startPollingForGameStart() {
        networkTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            MultiplayerManager.shared.getRoomState(roomCode: roomCode) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let state):
                        if state.player2 != nil {
                            otherPlayerConnected = true 
                        }
                        if state.gameState == "playing" {
                            networkTimer?.invalidate()
                            isMonkeyPlayer = state.monkeyPlayerId == playerId
                            isWaitingToStart = false
                            startGame()
                        }
                    case .failure:
                        break
                    }
                }
            }
        }
    }

    private func startGame() {
        gameStartTime = Date()
        
        monkeyPosition = CGPoint(x: UIScreen.main.bounds.width * 0.25, y: UIScreen.main.bounds.height * 0.5)
        playerPosition = CGPoint(x: UIScreen.main.bounds.width * 0.75, y: UIScreen.main.bounds.height * 0.5)
        targetMonkeyPosition = monkeyPosition
        targetPlayerPosition = playerPosition
        petPosition = CGPoint(x: UIScreen.main.bounds.width * 0.75 + 40, y: UIScreen.main.bounds.height * 0.5 + 40)
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            if !isMonkeyPlayer {
                updatePetPosition()
            }
            interpolateRemotePositions()
            checkCollision()
            if isHost {
                updateScore()
            }
        }
        
        if isHost {
            scheduleLarryAppearance()
        }
        
        startNetworkSync()
    }

    private func startNetworkSync() {
        networkTimer?.invalidate()
        networkTimer = Timer.scheduledTimer(withTimeInterval: networkUpdateInterval, repeats: true) { _ in
            syncWithServer()
        }
    }

    private func syncWithServer() {
        let myPosition = isMonkeyPlayer ? monkeyPosition : playerPosition
        let normalizedMyPosition = normalizePosition(myPosition)
        let normalizedMonkey: CGPoint? = isMonkeyPlayer ? normalizePosition(monkeyPosition) : nil
        let normalizedLarry = normalizePosition(larryPosition)
        let larryToSend: (visible: Bool, x: Double, y: Double, frozen: Bool)? = isHost ? (visible: isLarryVisible, x: Double(normalizedLarry.x), y: Double(normalizedLarry.y), frozen: isMonkeyFrozen) : nil
        let scoreToSend: Int? = isHost ? score : nil
        let gameStateToSend: String? = isHost ? (isGameOver ? "ended" : "playing") : nil
        
        MultiplayerManager.shared.updateRoomState(
            roomCode: roomCode,
            playerId: playerId,
            myPosition: normalizedMyPosition,
            monkey: normalizedMonkey,
            larry: larryToSend,
            score: scoreToSend,
            gameState: gameStateToSend
        ) { result in
            DispatchQueue.main.async {
                guard case .success(let state) = result else { return }
                
                let otherPlayer = playerId == "player1" ? state.player2 : state.player1
                if let other = otherPlayer, isMonkeyPlayer {
                    let normalizedOther = CGPoint(x: other.x, y: other.y)
                    if normalizedOther.x > 0.01 || normalizedOther.y > 0.01 {
                        targetPlayerPosition = denormalizePosition(normalizedOther)
                    }
                }
                
                if !isMonkeyPlayer, let monkey = state.monkey {
                    let normalizedMonkeyPos = CGPoint(x: monkey.x, y: monkey.y)
                    if normalizedMonkeyPos.x > 0.01 || normalizedMonkeyPos.y > 0.01 {
                        targetMonkeyPosition = denormalizePosition(normalizedMonkeyPos)
                    }
                }
                
                if !isHost {
                    if let larry = state.larry {
                        isLarryVisible = larry.visible
                        let normalizedLarryPos = CGPoint(x: larry.x, y: larry.y)
                        larryPosition = denormalizePosition(normalizedLarryPos)
                        isMonkeyFrozen = larry.frozen
                    }
                    if let gameScore = state.score {
                        score = gameScore
                    }
                    if state.gameState == "ended" {
                        gameOver()
                    }
                }
            }
        }
    }

    private func interpolateRemotePositions() {
        if isMonkeyPlayer {
            playerPosition.x += (targetPlayerPosition.x - playerPosition.x) * remotePlayerLerpSpeed
            playerPosition.y += (targetPlayerPosition.y - playerPosition.y) * remotePlayerLerpSpeed
        } else {
            monkeyPosition.x += (targetMonkeyPosition.x - monkeyPosition.x) * remotePlayerLerpSpeed
            monkeyPosition.y += (targetMonkeyPosition.y - monkeyPosition.y) * remotePlayerLerpSpeed
        }
    }

    private func updatePetPosition() {
        if petType == .none {
            return
        }
        
        let targetX = playerPosition.x + 30
        let targetY = playerPosition.y + 30
        
        petPosition.x += (targetX - petPosition.x) * petFollowSpeed
        petPosition.y += (targetY - petPosition.y) * petFollowSpeed
    }

    private func checkCollision() {
        if isMonkeyFrozen {
            return
        }
        
        let distance = sqrt(
            pow(playerPosition.x - monkeyPosition.x, 2) +
            pow(playerPosition.y - monkeyPosition.y, 2)
        )
        
        let collisionThreshold = (actualPlayerSize + actualMonkeySize) / 2 * 0.7
        
        if distance < collisionThreshold {
            gameOver()
        }
    }

    private func updateScore() {
        if !isGameOver {
            let secondsElapsed = Int(Date().timeIntervalSince(gameStartTime))
            score = secondsElapsed * 100
        }
    }

    private func scheduleLarryAppearance() {
        larryTimer = Timer.scheduledTimer(withTimeInterval: larryAppearInterval, repeats: true) { _ in
            showLarry()
        }
    }

    private func showLarry() {
        larryPosition = CGPoint(
            x: UIScreen.main.bounds.width * 0.5,
            y: UIScreen.main.bounds.height * 0.25
        )
        
        isLarryVisible = true
        
        larryMovementTimer?.invalidate()
        larryMovementTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            moveLarryToMonkey()
        }
    }

    private func moveLarryToMonkey() {
        let dx = monkeyPosition.x - larryPosition.x
        let dy = monkeyPosition.y - larryPosition.y
        let distance = sqrt(dx * dx + dy * dy)
        
        if distance < 10 {
            larryMovementTimer?.invalidate()
            larryMovementTimer = nil
            isMonkeyFrozen = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + larryFreezeTime) {
                isLarryVisible = false
                isMonkeyFrozen = false
            }
        } else {
            let normalizedDx = dx / distance
            let normalizedDy = dy / distance
            let larrySpeed: CGFloat = 5.0
            larryPosition.x += normalizedDx * larrySpeed
            larryPosition.y += normalizedDy * larrySpeed
        }
    }

    private func gameOver() {
        isGameOver = true
        cleanupTimers()
    }

    private func restartGame() {
        MultiplayerManager.shared.restartGame(roomCode: roomCode) { result in
            DispatchQueue.main.async {
                if case .success(let response) = result {
                    isMonkeyPlayer = response.monkeyPlayerId == playerId
                }
                resetGameState()
                startGame()
            }
        }
    }

    private func resetGameState() {
        isGameOver = false
        score = 0
        monkeyPosition = CGPoint(x: UIScreen.main.bounds.width * 0.25, y: UIScreen.main.bounds.height * 0.5)
        playerPosition = CGPoint(x: UIScreen.main.bounds.width * 0.75, y: UIScreen.main.bounds.height * 0.5)
        targetMonkeyPosition = monkeyPosition
        targetPlayerPosition = playerPosition
        petPosition = CGPoint(x: UIScreen.main.bounds.width * 0.75 + 40, y: UIScreen.main.bounds.height * 0.5 + 40)
        isLarryVisible = false
        isMonkeyFrozen = false
        larryPosition = CGPoint(x: 0, y: 0)
    }

    private func startPollingForRestart() {
        networkTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            MultiplayerManager.shared.getRoomState(roomCode: roomCode) { result in
                DispatchQueue.main.async {
                    if case .success(let state) = result, state.gameState == "playing" {
                        networkTimer?.invalidate()
                        isMonkeyPlayer = state.monkeyPlayerId == playerId
                        resetGameState()
                        startGame()
                    }
                }
            }
        }
    }

    private func cleanupTimers() {
        gameTimer?.invalidate()
        gameTimer = nil
        networkTimer?.invalidate()
        networkTimer = nil
        larryTimer?.invalidate()
        larryTimer = nil
        larryMovementTimer?.invalidate()
        larryMovementTimer = nil
    }
}

