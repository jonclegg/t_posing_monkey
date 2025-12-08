import json
import os
import random
import boto3
import decimal

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])


###############################################################################


class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, decimal.Decimal):
            if o % 1 > 0:
                return float(o)
            return int(o)
        return super(DecimalEncoder, self).default(o)


###############################################################################


def handler(event, context):
    room_code = event['pathParameters']['code']
    body = json.loads(event.get('body', '{}'))
    
    player_id = body.get('playerId')
    action = body.get('action')
    
    if action == 'join':
        return handle_join(room_code, body)
    
    if action == 'start':
        return handle_start(room_code)
    
    if action == 'restart':
        return handle_restart(room_code)
    
    return handle_update(room_code, body, player_id)


###############################################################################


def handle_join(room_code, body):
    player_name = body.get('playerName', 'P2')
    
    response = table.get_item(Key={'roomCode': room_code})
    room = response.get('Item')
    
    if not room:
        return build_response(404, {'error': 'Room not found'})
    
    if room.get('player2') is not None:
        return build_response(400, {'error': 'Room is full'})
    
    table.update_item(
        Key={'roomCode': room_code},
        UpdateExpression='SET player2 = :p2',
        ExpressionAttributeValues={
            ':p2': {
                'name': player_name,
                'x': 0,
                'y': 0,
                'connected': True
            }
        }
    )
    
    return build_response(200, {'roomCode': room_code, 'playerId': 'player2', 'mapType': room.get('mapType', 'original')})


###############################################################################


def handle_start(room_code):
    monkey_player_id = random.choice(['player1', 'player2'])
    
    table.update_item(
        Key={'roomCode': room_code},
        UpdateExpression='SET gameState = :gs, monkeyPlayerId = :mp',
        ExpressionAttributeValues={
            ':gs': 'playing',
            ':mp': monkey_player_id
        }
    )
    
    return build_response(200, {'status': 'started', 'monkeyPlayerId': monkey_player_id})


###############################################################################


def handle_restart(room_code):
    monkey_player_id = random.choice(['player1', 'player2'])
    
    table.update_item(
        Key={'roomCode': room_code},
        UpdateExpression='SET gameState = :gs, score = :score, monkey = :monkey, larry = :larry, monkeyPlayerId = :mp',
        ExpressionAttributeValues={
            ':gs': 'playing',
            ':score': 0,
            ':monkey': {'x': decimal.Decimal('200'), 'y': decimal.Decimal('400')},
            ':larry': {'visible': False, 'x': decimal.Decimal('0'), 'y': decimal.Decimal('0'), 'frozen': False},
            ':mp': monkey_player_id
        }
    )
    
    return build_response(200, {'status': 'restarted', 'monkeyPlayerId': monkey_player_id})


###############################################################################


def handle_update(room_code, body, player_id):
    response = table.get_item(Key={'roomCode': room_code})
    room = response.get('Item')
    
    if not room:
        return build_response(404, {'error': 'Room not found'})
    
    monkey_player_id = room.get('monkeyPlayerId')
    is_host = player_id == 'player1'
    is_monkey_player = player_id == monkey_player_id
    
    update_expr_parts = []
    expr_values = {}
    
    if 'myPosition' in body:
        if player_id == 'player1':
            update_expr_parts.append('player1.x = :p1x')
            update_expr_parts.append('player1.y = :p1y')
            expr_values[':p1x'] = decimal.Decimal(str(body['myPosition']['x']))
            expr_values[':p1y'] = decimal.Decimal(str(body['myPosition']['y']))
        elif player_id == 'player2':
            update_expr_parts.append('player2.x = :p2x')
            update_expr_parts.append('player2.y = :p2y')
            expr_values[':p2x'] = decimal.Decimal(str(body['myPosition']['x']))
            expr_values[':p2y'] = decimal.Decimal(str(body['myPosition']['y']))
    
    if 'monkey' in body and is_monkey_player:
        update_expr_parts.append('monkey = :monkey')
        expr_values[':monkey'] = {
            'x': decimal.Decimal(str(body['monkey']['x'])),
            'y': decimal.Decimal(str(body['monkey']['y']))
        }
    
    if is_host:
        if 'larry' in body:
            update_expr_parts.append('larry = :larry')
            expr_values[':larry'] = {
                'visible': body['larry']['visible'],
                'x': decimal.Decimal(str(body['larry']['x'])),
                'y': decimal.Decimal(str(body['larry']['y'])),
                'frozen': body['larry']['frozen']
            }
        
        if 'score' in body:
            update_expr_parts.append('score = :score')
            expr_values[':score'] = body['score']
        
        if 'gameState' in body:
            update_expr_parts.append('gameState = :gs')
            expr_values[':gs'] = body['gameState']
    
    if not update_expr_parts:
        return build_response(400, {'error': 'No updates provided'})
    
    update_expr = 'SET ' + ', '.join(update_expr_parts)
    
    table.update_item(
        Key={'roomCode': room_code},
        UpdateExpression=update_expr,
        ExpressionAttributeValues=expr_values
    )
    
    response = table.get_item(Key={'roomCode': room_code})
    room = response.get('Item')
    
    return build_response(200, room)


###############################################################################


def build_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body, cls=DecimalEncoder)
    }

