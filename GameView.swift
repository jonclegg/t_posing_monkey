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

// Schedule Larry to appear
private func scheduleLarryAppearance() {
    print("Scheduling Larry to appear in 5 seconds")
    
    // Make Larry appear once after 5 seconds
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
        print("Time to show Larry!")
        self.showLarry()
    }
    
    // Then schedule regular appearances
    larryTimer = Timer.scheduledTimer(withTimeInterval: larryAppearInterval, repeats: true) { _ in
        print("Larry timer fired!")
        self.showLarry()
    }
}

// Constants
private let playerSize: CGFloat = 90
private let monkeySize: CGFloat = 90
private let monkeySpeed: CGFloat = 2.0
private let larrySize: CGFloat = 120  // Increased Larry's size
private let larryAppearInterval: TimeInterval = 10.0
private let larryFreezeTime: TimeInterval = 3.0

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