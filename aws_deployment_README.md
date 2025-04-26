# High Score System AWS Deployment

This project sets up a global high score system for your game using AWS DynamoDB and Lambda functions.

## Prerequisites

1. AWS Account
2. AWS CLI installed and configured
3. Python 3.9+
4. Node.js 14+
5. AWS CDK installed (`npm install -g aws-cdk`)

## Installation

1. Install dependencies:

```bash
# Install CDK dependencies
pip install -r requirements.txt
```

2. Bootstrap CDK (if you haven't already):

```bash
cdk bootstrap
```

3. Deploy the stack:

```bash
cdk deploy
```

4. After deployment, the API URL will be outputted to the console. Use this URL to connect your game to the high score system.

## Infrastructure Components

- **DynamoDB Table**: Stores high scores
- **Lambda Functions**: 
  - `GetHighScoresFunction`: Retrieves high scores
  - `SaveHighScoreFunction`: Saves new high scores
- **API Gateway**: Exposes REST endpoints to interact with the high score system

## API Endpoints

- **GET /scores**: Get the top high scores
  - Query parameters:
    - `limit`: Maximum number of scores to return (default: 10)
  
- **POST /scores**: Submit a new high score
  - Request body (JSON):
    ```json
    {
      "playerName": "Player1",
      "score": 1000
    }
    ```

## Integration with Your Game

Use the API endpoints to submit new high scores and retrieve the leaderboard. 