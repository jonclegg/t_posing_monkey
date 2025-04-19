import SwiftUI
import AVFoundation

// High score structure
struct HighScore: Identifiable, Codable, Comparable {
    var id = UUID()
    var initials: String
    var score: Int
    var date: Date
    
    static func < (lhs: HighScore, rhs: HighScore) -> Bool {
        return lhs.score > rhs.score // Sort in descending order
    }
}

struct GameView: View {
    // Presentation mode for dismissing the view
    // @Environment(\.presentationMode) var presentationMode

    // Map type
    let mapType: MapType
    
    // Closure to pop back to the root view
    let popToRoot: () -> Void
    
    // Game state
    @State private var playerPosition = CGPoint(x: UIScreen.main.bounds.width * 0.75, y: UIScreen.main.bounds.height * 0.5)
    @State private var monkeyPosition = CGPoint(x: UIScreen.main.bounds.width * 0.25, y: UIScreen.main.bounds.height * 0.5)
    @State private var score = 0
    @State private var isGameOver = false
    @State private var timer: Timer? = nil
    @State private var gameStartTime = Date()
    
    // Larry state
    @State private var isLarryVisible = false
    @State private var isMonkeyFrozen = false
    @State private var larryPosition = CGPoint(x: 0, y: 0)
    @State private var larryTimer: Timer? = nil
    @State private var isLarryMoving = false
    @State private var larryTargetPosition = CGPoint(x: 0, y: 0)
    @State private var larryMovementTimer: Timer? = nil
    
    // High score state
    @State private var highScores: [HighScore] = []
    @State private var showingInitialsInput = false
    @State private var playerInitials = ""
    @State private var isHighScore = false
    
    // Constants
    private let playerSize: CGFloat = 90
    private let monkeySize: CGFloat = 90
    private let monkeySpeed: CGFloat = 2.0
    private let larrySize: CGFloat = 120  // Increased Larry's size for better visibility
    private let larryAppearInterval: TimeInterval = 10.0
    private let larryFreezeTime: TimeInterval = 3.0
    private let maxHighScores = 10
    
    // Computed properties for player and monkey size based on map type
    private var actualPlayerSize: CGFloat {
        switch mapType {
        case .mountain:
            return playerSize * 2  // Double size for mountain map
        default:
            return playerSize
        }
    }
    
    private var actualMonkeySize: CGFloat {
        switch mapType {
        case .mountain:
            return monkeySize * 2  // Double size for mountain map
        default:
            return monkeySize
        }
    }
    
    // Computed properties for image names based on map type
    private var backgroundImage: String {
        switch mapType {
        case .original:
            return "background"
        case .mountain:
            return "background_mount"
        case .sea:
            return "sea_background"
        }
    }
    
    private var playerImage: String {
        switch mapType {
        case .original:
            return "player"
        case .mountain:
            return "player_mount"
        case .sea:
            return "sea_player"
        }
    }
    
    private var monkeyImage: String {
        switch mapType {
        case .original:
            return "monkey"
        case .mountain:
            return "monkey_mount"
        case .sea:
            return "sea_monkey"
        }
    }
    
    private var larryImage: String {
        switch mapType {
        case .original:
            return "larry"
        case .mountain:
            return "larry_mount"
        case .sea:
            // Reuse mountain larry for now, or create sea_larry if available
            return "larry_mount"
        }
    }
    
    // Initialize with map type and popToRoot closure
    init(mapType: MapType, popToRoot: @escaping () -> Void) {
        self.mapType = mapType
        self.popToRoot = popToRoot
    }
    
    var body: some View {
        ZStack {
            // Background
            Image(backgroundImage)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            if isGameOver {
                if showingInitialsInput {
                    // Initials input screen
                    VStack(spacing: 20) {
                        HStack {
                            Spacer()
                            Button(action: {
                                // Close dialog without saving
                                showingInitialsInput = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 22))
                            }
                            .padding(.trailing, 10)
                        }
                        
                        Text("NEW HIGH SCORE!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                            .shadow(color: .black, radius: 2, x: 0, y: 0)
                        
                        Text("Score: \(score)")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2, x: 0, y: 0)
                        
                        Text("Enter your initials:")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2, x: 0, y: 0)
                        
                        TextField("AAA", text: $playerInitials)
                            .frame(width: 100)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 30, weight: .bold))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: playerInitials) { newValue in
                                // Limit to 3 characters, all uppercase
                                if newValue.count > 3 {
                                    playerInitials = String(newValue.prefix(3))
                                }
                                playerInitials = playerInitials.uppercased()
                            }
                            .padding()
                        
                        Button("Submit") {
                            submitHighScore()
                        }
                        .disabled(playerInitials.isEmpty)
                        .padding()
                        .background(playerInitials.isEmpty ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                } else {
                    // Show the full-screen High Score Board
                    HighScoreBoardView(
                        highScores: highScores,
                        currentScore: score,
                        dismissAction: {
                            // presentationMode.wrappedValue.dismiss() // OLD
                            popToRoot() // NEW: Call the popToRoot closure
                        },
                        backgroundImage: "scoreboard_background" // Use the scoreboard background
                    )
                }
            } else {
                // Game elements
                // Player
                Image(playerImage)
                    .resizable()
                    .frame(width: actualPlayerSize, height: actualPlayerSize)
                    .position(playerPosition)
                
                // Monkey
                Image(monkeyImage)
                    .resizable()
                    .frame(width: actualMonkeySize, height: actualMonkeySize)
                    .position(monkeyPosition)
                    .colorMultiply(isMonkeyFrozen ? .blue : .white) // Turn monkey blue when frozen
                
                // Game title
                // Title removed as per requirement
                
                // Larry (appears periodically)
                if isLarryVisible {
                    Image(larryImage)
                        .resizable()
                        .frame(width: larrySize, height: larrySize)
                        .position(larryPosition)
                        .overlay(
                            Text("LARRY")
                                .foregroundColor(.red)
                                .font(.headline)
                        )
                    
                    // Debug info
                    Text("Larry is here!")
                        .foregroundColor(.green)
                        .background(Color.black)
                        .padding()
                        .position(x: UIScreen.main.bounds.width * 0.5, y: 50)
                }
                
                // Score display
                Text("Score: \(score)")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2, x: 0, y: 0)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 50)
                    .padding(.trailing, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isGameOver {
                        playerPosition = value.location
                    }
                }
        )
        .onAppear {
            loadHighScores()
            startGame()
        }
        .onDisappear {
            timer?.invalidate()
            larryTimer?.invalidate()
            larryMovementTimer?.invalidate()
        }
    }
    
    // Start the game
    private func startGame() {
        resetGame()
        
        // Create a timer to update monkey position and check collisions
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            updateMonkeyPosition()
            checkCollision()
            updateScore()
        }
        
        // Schedule Larry to appear
        scheduleLarryAppearance()
    }
    
    // Reset the game state
    private func resetGame() {
        playerPosition = CGPoint(x: UIScreen.main.bounds.width * 0.75, y: UIScreen.main.bounds.height * 0.5)
        monkeyPosition = CGPoint(x: UIScreen.main.bounds.width * 0.25, y: UIScreen.main.bounds.height * 0.5)
        score = 0
        isGameOver = false
        isLarryVisible = false
        isMonkeyFrozen = false
        isLarryMoving = false
        isHighScore = false
        showingInitialsInput = false
        playerInitials = ""
        gameStartTime = Date()
        timer?.invalidate()
        timer = nil
        larryTimer?.invalidate()
        larryTimer = nil
        larryMovementTimer?.invalidate()
        larryMovementTimer = nil
    }
    
    // Schedule Larry to appear
    private func scheduleLarryAppearance() {
        print("Scheduling Larry to appear every 10 seconds")
        
        // Schedule regular appearances every 10 seconds
        larryTimer = Timer.scheduledTimer(withTimeInterval: larryAppearInterval, repeats: true) { _ in
            print("Larry timer fired!")
            self.showLarry()
        }
    }
    
    // Show Larry and freeze the monkey
    private func showLarry() {
        print("Larry should appear now!")
        
        // Set Larry's initial position at the edge of the screen
        larryPosition = CGPoint(
            x: UIScreen.main.bounds.width * 0.5, 
            y: UIScreen.main.bounds.height * 0.25
        )
        
        // Set target position to be at the monkey
        larryTargetPosition = monkeyPosition
        
        // Make Larry visible and start moving
        isLarryVisible = true
        isLarryMoving = true
        
        // Create a timer to move Larry toward the monkey
        larryMovementTimer?.invalidate()
        larryMovementTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            moveLarryToMonkey()
        }
    }
    
    // Move Larry toward the monkey
    private func moveLarryToMonkey() {
        // Calculate direction vector from Larry to monkey
        let dx = monkeyPosition.x - larryPosition.x
        let dy = monkeyPosition.y - larryPosition.y
        
        // Calculate distance
        let distance = sqrt(dx * dx + dy * dy)
        
        if distance < 10 { // Larry has reached the monkey
            // Stop movement timer
            larryMovementTimer?.invalidate()
            larryMovementTimer = nil
            isLarryMoving = false
            
            // Freeze the monkey
            isMonkeyFrozen = true
            
            // Schedule Larry to disappear after freeze time
            DispatchQueue.main.asyncAfter(deadline: .now() + larryFreezeTime) {
                isLarryVisible = false
                isMonkeyFrozen = false
            }
        } else {
            // Normalize the direction vector
            let normalizedDx = dx / distance
            let normalizedDy = dy / distance
            
            // Move Larry toward the monkey
            let larrySpeed: CGFloat = 5.0
            larryPosition.x += normalizedDx * larrySpeed
            larryPosition.y += normalizedDy * larrySpeed
        }
    }
    
    // Update the monkey position to follow the player
    private func updateMonkeyPosition() {
        // Only update if the monkey is not frozen
        if !isMonkeyFrozen {
            // Calculate direction vector from monkey to player
            let dx = playerPosition.x - monkeyPosition.x
            let dy = playerPosition.y - monkeyPosition.y
            
            // Normalize the direction vector
            let length = sqrt(dx * dx + dy * dy)
            if length > 0 {
                let normalizedDx = dx / length
                let normalizedDy = dy / length
                
                // Move monkey in the direction of the player
                monkeyPosition.x += normalizedDx * monkeySpeed
                monkeyPosition.y += normalizedDy * monkeySpeed
            }
        }
    }
    
    // Check for collision between player and monkey
    private func checkCollision() {
        // Only check for collisions if the monkey is not frozen
        if !isMonkeyFrozen {
            let distance = sqrt(
                pow(playerPosition.x - monkeyPosition.x, 2) +
                pow(playerPosition.y - monkeyPosition.y, 2)
            )
            
            // If the distance is less than the sum of their radii, they're colliding
            // Using 0.7 as a multiplier for better collision feel
            let collisionThreshold = (actualPlayerSize + actualMonkeySize) / 2 * 0.7
            if distance < collisionThreshold {
                gameOver()
            }
        }
    }
    
    // Update the score based on time survived
    private func updateScore() {
        if !isGameOver {
            // Calculate how many seconds have passed since game start
            let secondsElapsed = Int(Date().timeIntervalSince(gameStartTime))
            score = secondsElapsed * 100
        }
    }
    
    // Handle game over
    private func gameOver() {
        isGameOver = true
        timer?.invalidate()
        timer = nil
        larryTimer?.invalidate()
        larryTimer = nil
        larryMovementTimer?.invalidate()
        larryMovementTimer = nil
        
        // Check if the score is a high score
        checkForHighScore()
    }
    
    // Load high scores from UserDefaults
    private func loadHighScores() {
        if let data = UserDefaults.standard.data(forKey: "highScores") {
            if let decoded = try? JSONDecoder().decode([HighScore].self, from: data) {
                highScores = decoded.sorted()
            }
        }
    }
    
    // Save high scores to UserDefaults
    private func saveHighScores() {
        if let encoded = try? JSONEncoder().encode(highScores) {
            UserDefaults.standard.set(encoded, forKey: "highScores")
        }
    }
    
    // Check if the current score is a high score
    private func checkForHighScore() {
        // If we have fewer than maxHighScores, it's automatically a high score
        if highScores.count < maxHighScores {
            isHighScore = true
            showingInitialsInput = true
            return
        }
        
        // Otherwise, check if it's higher than the lowest high score
        if let lowestHighScore = highScores.sorted().last {
            if score > lowestHighScore.score {
                isHighScore = true
                showingInitialsInput = true
                return
            }
        }
        
        // Not a high score
        isHighScore = false
    }
    
    // Submit the high score with player initials
    private func submitHighScore() {
        // Create a new high score
        let newHighScore = HighScore(initials: playerInitials.isEmpty ? "AAA" : playerInitials, score: score, date: Date())
        
        // Add it to the list
        highScores.append(newHighScore)
        
        // Sort and trim the list
        highScores.sort()
        if highScores.count > maxHighScores {
            highScores = Array(highScores.prefix(maxHighScores))
        }
        
        // Save to UserDefaults
        saveHighScores()
        
        // Close the initials input
        showingInitialsInput = false
    }
}

// Preview
struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a dummy closure for the preview
        GameView(mapType: .original, popToRoot: { print("Preview: Pop to root called") })
    }
} 