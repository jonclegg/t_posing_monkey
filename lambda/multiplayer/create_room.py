import json
import os
import random
import string
import time
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])


###############################################################################


def generate_room_code():
    return ''.join(random.choices(string.ascii_uppercase, k=4))


###############################################################################


def handler(event, context):
    body = json.loads(event.get('body', '{}'))
    player_name = body.get('playerName', 'P1')
    map_type = body.get('mapType', 'original')
    
    room_code = generate_room_code()
    current_time = int(time.time())
    expires_at = current_time + 3600  # 1 hour TTL
    
    room = {
        'roomCode': room_code,
        'mapType': map_type,
        'hostPlayerId': 'player1',
        'monkeyPlayerId': None,
        'player1': {
            'name': player_name,
            'x': 0,
            'y': 0,
            'connected': True
        },
        'player2': None,
        'monkey': {'x': 0, 'y': 0},
        'larry': {'visible': False, 'x': 0, 'y': 0, 'frozen': False},
        'gameState': 'waiting',
        'score': 0,
        'createdAt': current_time,
        'expiresAt': expires_at
    }
    
    table.put_item(Item=room)
    
    return build_response(201, {'roomCode': room_code, 'playerId': 'player1'})


###############################################################################


def build_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body)
    }

