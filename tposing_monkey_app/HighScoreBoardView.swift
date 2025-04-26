import SwiftUI

struct HighScoreBoardView: View {
    let highScores: [HighScore]
    let currentScore: Int
    let dismissAction: () -> Void
    let backgroundImage: String // Pass the background image name
    var title: String = "High Scores" // Customizable title, defaults to "High Scores"

    var body: some View {
        // Use a VStack as the main container to handle the background
        VStack(spacing: 20) {
            // Top section with title and score
            VStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.yellow)
                    .shadow(color: .black, radius: 2, x: 0, y: 0)
                
                Text("Your Score: \(currentScore)")
                    .font(.title)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2, x: 0, y: 0)
            }
            .padding(.top, 40) // Keep some padding at the top

            // Main content area with two columns
            HStack(alignment: .top, spacing: 20) {
                // --- Left Column: Leaderboard ---
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Rank")
                            .font(.headline)
                            .foregroundColor(.white)
                            .underline()
                            .frame(width: 50, alignment: .leading) // Adjusted width
                        
                        Text("Initials")
                            .font(.headline)
                            .foregroundColor(.white)
                            .underline()
                            .frame(minWidth: 80, alignment: .leading) // Adjusted width
                        
                        Spacer()
                        
                        Text("Score")
                            .font(.headline)
                            .foregroundColor(.white)
                            .underline()
                            .frame(width: 80, alignment: .trailing) // Adjusted width
                    }
                    .padding(.horizontal, 15) // Adjusted padding
                    .padding(.bottom, 10)
                    
                    Divider()
                        .background(Color.white.opacity(0.7))
                        .padding(.horizontal, 15) // Adjusted padding
                    
                    // Scrollable scores list
                    ScrollView {
                        VStack(spacing: 12) { // Adjusted spacing
                            // Ensure we show top 10 or fewer if not enough scores
                            let displayedScores = highScores.prefix(10)
                            
                            if displayedScores.isEmpty {
                                Text("No scores yet! Be the first!")
                                    .foregroundColor(.white)
                                    .padding(.top, 30)
                            } else {
                                ForEach(displayedScores.indices, id: \.self) { index in
                                    let scoreData = displayedScores[index]
                                    HStack {
                                        Text("\(index + 1).")
                                            .font(.title3)
                                            .foregroundColor(.white)
                                            .frame(width: 50, alignment: .leading) // Matched header width
                                        
                                        Text(scoreData.initials)
                                            .font(.title3)
                                            .foregroundColor(.yellow)
                                            .frame(minWidth: 80, alignment: .leading) // Matched header width
                                        
                                        Spacer()
                                        
                                        Text("\(scoreData.score)")
                                            .font(.title3)
                                            .foregroundColor(.white)
                                            .frame(width: 80, alignment: .trailing) // Matched header width
                                    }
                                    .padding(.horizontal, 15) // Adjusted padding
                                }
                            }
                        }
                        .padding(.top, 10) // Add padding above the list
                    }
                    // Give the ScrollView a flexible height but constrain if needed
                    .frame(maxHeight: .infinity)

                }
                .padding(.vertical) // Add vertical padding to the leaderboard container
                .background(Color.black.opacity(0.4)) // Slightly increased opacity
                .cornerRadius(10)
                .frame(maxWidth: .infinity) // Allow leaderboard to take available width

                // --- Right Column: Controls ---
                VStack {
                    Button {
                        dismissAction()
                    } label: {
                        Label("Close", systemImage: "xmark.circle.fill")
                            .font(.title2)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .shadow(radius: 5)

                    }
                    .padding(.top, 20) // Add padding above the button

                    Spacer() // Push button towards the top
                }
                .frame(width: 150) // Give the right column a fixed width

            }
            .padding(.horizontal) // Add horizontal padding to the HStack

            Spacer() // Pushes content towards the top
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure VStack fills the screen
        .background(
            Image(backgroundImage)
                .resizable()
                .scaledToFill()
                .overlay(Color.black.opacity(0.6)) // Adjusted overlay opacity
                .edgesIgnoringSafeArea(.all)
        )
    }
}

// Preview requires some sample data
struct HighScoreBoardView_Previews: PreviewProvider {
    static let sampleScores = [
        HighScore(initials: "JON", score: 15000, date: Date()),
        HighScore(initials: "XYZ", score: 12500, date: Date()),
        HighScore(initials: "ABC", score: 11000, date: Date()),
        HighScore(initials: "DEF", score: 9800, date: Date()),
        HighScore(initials: "GHI", score: 7500, date: Date()),
        HighScore(initials: "JKL", score: 6000, date: Date()),
        HighScore(initials: "MNO", score: 5100, date: Date()),
        HighScore(initials: "PQR", score: 4200, date: Date()),
        HighScore(initials: "STU", score: 3000, date: Date()),
        HighScore(initials: "VWX", score: 1500, date: Date()),
    ]

    static var previews: some View {
        HighScoreBoardView(
            highScores: sampleScores,
            currentScore: 10500,
            dismissAction: { print("Dismiss Tapped") },
            backgroundImage: "scoreboard_background",
            title: "Global High Scores"
        )
    }
} 