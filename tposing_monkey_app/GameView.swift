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
    @State private var isSubmitting = false
    @State private var submissionError: String? = nil
    
    // Constants
    private let playerSize: CGFloat = 90
    private let monkeySize: CGFloat = 90
    private let monkeySpeed: CGFloat = 2.0
    private let larrySize: CGFloat = 120  // Increased Larry's size for better visibility
    private let larryAppearInterval: TimeInterval = 10.0
    private let larryFreezeTime: TimeInterval = 3.0
    private let maxHighScores = 10
    
    // Global high score manager
    private let globalHighScoreManager = GlobalHighScoreManager()
    
    // Computed properties for player and monkey size based on map type
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
    
    // Computed properties for image names based on map type
    private var backgroundImage: String {
        switch mapType {
        case .original:
            return "background"
        case .mountain:
            return "background_mount"
        case .sea:
            return "sea_background"
        case .hotdogLand:
            return "hotdog_background"
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
        case .hotdogLand:
            return "hotdog_player"
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
        case .hotdogLand:
            return "hotdog_monkey"
        }
    }
    
    private var larryImage: String {
        switch mapType {
        case .original:
            return "larry"
        case .mountain:
            return "larry_mount"
        case .sea:
            return "larry_mount"
        case .hotdogLand:
            return "hotdog_larry"
        }
    }
    
    private var larryName: String {
        switch mapType {
        case .hotdogLand:
            return "MARCUS"
        case .original, .mountain, .sea:
            return "LARRY"
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
                        
                        // Show submission error if there is one
                        if let error = submissionError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.bottom, 5)
                        }
                        
                        Button(isSubmitting ? "Submitting..." : "Submit") {
                            submitHighScore()
                        }
                        .disabled(playerInitials.isEmpty || isSubmitting)
                        .padding()
                        .background(playerInitials.isEmpty || isSubmitting ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                } else {
                    // Show the full-screen High Score Board (global only)
                    HighScoreBoardView(
                        highScores: highScores,
                        currentScore: score,
                        dismissAction: {
                            popToRoot()
                        },
                        backgroundImage: "scoreboard_background",
                        title: "Global High Scores" // Specify it's global high scores
                    )
                }
            } else {
                // Game elements
                // Player
                Image(playerImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: actualPlayerSize)
                    .position(playerPosition)
                
                // Monkey
                Image(monkeyImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: actualMonkeySize)
                    .position(monkeyPosition)
                    .colorMultiply(isMonkeyFrozen ? .blue : .white)
                
                // Larry (appears periodically)
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
                    
                    // Debug info
                    Text("\(larryName) is here!")
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
    
    // Load high scores from global database
    private func loadHighScores() {
        globalHighScoreManager.getGlobalHighScores(limit: maxHighScores) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let scores):
                    highScores = scores.sorted()
                case .failure(let error):
                    print("Failed to load global high scores: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Check if the current score is a high score
    private func checkForHighScore() {
        // If we don't have high scores yet, fetch them
        if highScores.isEmpty {
            globalHighScoreManager.getGlobalHighScores(limit: maxHighScores) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let scores):
                        highScores = scores.sorted()
                        checkIfScoreQualifies(scores: scores)
                    case .failure:
                        // On error, assume it's a high score
                        isHighScore = true
                        showingInitialsInput = true
                    }
                }
            }
        } else {
            // Check against already loaded scores
            checkIfScoreQualifies(scores: highScores)
        }
    }
    
    // Helper to check if score qualifies for high score
    private func checkIfScoreQualifies(scores: [HighScore]) {
        if scores.count < maxHighScores {
            isHighScore = true
            showingInitialsInput = true
        } else if let lowestScore = scores.last, score > lowestScore.score {
            isHighScore = true
            showingInitialsInput = true
        } else {
            isHighScore = false
        }
    }
    
    // Submit the high score with player initials
    private func submitHighScore() {
        isSubmitting = true
        submissionError = nil
        
        // Submit to global high scores
        globalHighScoreManager.submitGlobalScore(playerName: playerInitials.isEmpty ? "AAA" : playerInitials, score: score) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success(_):
                    // Successfully submitted
                    // Refresh global high scores
                    loadHighScores()
                    showingInitialsInput = false
                case .failure(let error):
                    // Show error but still close the dialog
                    submissionError = "Failed to submit global score: \(error.localizedDescription)"
                    print("Failed to submit global high score: \(error.localizedDescription)")
                    
                    // Give user a moment to see the error, then close
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showingInitialsInput = false
                    }
                }
            }
        }
    }
}

// Preview
struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a dummy closure for the preview
        GameView(mapType: .original, popToRoot: { print("Preview: Pop to root called") })
    }
} 