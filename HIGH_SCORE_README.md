# Global High Score System

This game now features a global high score system powered by AWS infrastructure!

## Features

- Real-time global leaderboard
- Seamless score submission
- Persistent high scores across devices
- Sorted leaderboard by score

## Technical Infrastructure

The global high score system is powered by:

1. **AWS DynamoDB**: NoSQL database storing all player scores
2. **AWS Lambda Functions**: 
   - `GetHighScoresFunction`: Retrieves top scores
   - `SaveHighScoreFunction`: Saves new scores
3. **API Gateway**: Exposes RESTful endpoints

## Implementation

The game integration is done through:

- `GlobalHighScoreManager.swift`: Communicates with the AWS API
- `GameView.swift`: Updated to submit and display global scores
- `HighScoreBoardView.swift`: Displays the leaderboard

## How It Works

1. When the game ends, the score is compared against global high scores
2. If it qualifies, the player can enter their initials (3 characters)
3. The score is submitted to the global leaderboard
4. The high score screen shows all top scores from players around the world

## Future Improvements

- Add player countries
- Time-based leaderboards (daily, weekly, all-time)
- Achievements system
- Social sharing of high scores 