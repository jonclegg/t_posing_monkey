import SwiftUI
import AVFoundation

struct GameView: View {
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
    
    // Constants
    private let playerSize: CGFloat = 90
    private let monkeySize: CGFloat = 90
    private let monkeySpeed: CGFloat = 2.0
    private let larrySize: CGFloat = 120  // Increased Larry's size for better visibility
    private let larryAppearInterval: TimeInterval = 10.0
    private let larryFreezeTime: TimeInterval = 3.0
    
    var body: some View {
        ZStack {
            // Background
            Image("background")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            if isGameOver {
                // Game Over screen
                VStack {
                    Text("Game Over!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .shadow(color: .black, radius: 2, x: 0, y: 0)
                        .padding()
                    
                    Text("Score: \(score)")
                        .font(.title)
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2, x: 0, y: 0)
                        .padding()
                    
                    Button("Play Again") {
                        resetGame()
                        startGame()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
                }
            } else {
                // Game elements
                // Player
                Image("player")
                    .resizable()
                    .frame(width: playerSize, height: playerSize)
                    .position(playerPosition)
                
                // Monkey
                Image("monkey")
                    .resizable()
                    .frame(width: monkeySize, height: monkeySize)
                    .position(monkeyPosition)
                    .colorMultiply(isMonkeyFrozen ? .blue : .white) // Turn monkey blue when frozen
                
                // Game title
                // Title removed as per requirement
                
                // Larry (appears periodically)
                if isLarryVisible {
                    Image("larry")
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
            if distance < (playerSize + monkeySize) / 2 * 0.7 {  // Using 0.7 as a multiplier for better collision feel
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
    }
}

// Preview
struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
} 