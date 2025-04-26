import json
import os
import uuid
import boto3
from datetime import datetime

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def handler(event, context):
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        
        # Extract score data
        player_name = body.get('playerName')
        score = body.get('score')
        
        # Validate input
        if not player_name or not isinstance(score, (int, float)):
            return build_response(400, {'error': 'Invalid input. Required fields: playerName (string), score (number)'})
        
        # Generate unique ID
        score_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat()
        
        # Save to DynamoDB
        item = {
            'id': score_id,
            'playerName': player_name,
            'score': score,
            'timestamp': timestamp
        }
        
        table.put_item(Item=item)
        
        return build_response(201, {'message': 'Score saved successfully', 'scoreId': score_id})
    except Exception as e:
        return build_response(500, {'error': str(e)})

def build_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body)
    } 